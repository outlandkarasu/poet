/**
Function definition module.
*/
module poet.definition.definition;

import std.algorithm : find;
import std.exception : enforce;
import std.typecons : Rebindable, rebindable, Typedef;

import poet.type : Type;
import poet.fun : FunctionType;
import poet.utils : List, list;

import poet.definition.exceptions :
    FunctionNotStartedException,
    NotFunctionTypeException,
    OutOfScopeException,
    UnmatchTypeException,
    VariableIndexNotFoundException;

@safe:

/**
Scope ID type.
*/
alias ScopeID = Typedef!(size_t, size_t.init, "ScopeID");

/**
stack index type.
*/
alias VariableIndex = Typedef!(size_t, size_t.init, "VariableIndex");

/**
Variable.
*/
struct Variable
{
    /**
    Variable scope ID;
    */
    ScopeID scopeID;

    /**
    Variable index.
    */
    VariableIndex index;
}

/**
Function definition.
*/
final class Definition
{
    /**
    Begin function definition.

    Params:
        f = target function variable.
    */
    Variable begin() pure scope
    out (r; getType(r))
    {
        immutable functionType = enforce!NotFunctionTypeException(
                cast(FunctionType) variables_.head.currentScope.target.result);

        auto newScopeID = ScopeID(cast(size_t) lastScopeID_ + 1);
        immutable newScope = new Scope(newScopeID, functionType, variables_);
        immutable index = VariableIndex(0);
        variables_ = list(VariableEntry(newScope, index, functionType.argument));
        lastScopeID_ = newScopeID;
        return Variable(newScopeID, index);
    }

    /**
    End function definition.

    Returns:
        defined function type.
    */
    Variable end(const(Variable) result) pure scope
    out (r; getType(r))
    {
        immutable resultType = getType(result);
        immutable currentScope = variables_.head.currentScope;
        immutable targetType = currentScope.target;
        enforce!UnmatchTypeException(resultType.equals(targetType.result));

        immutable before = currentScope.before;
        enforce!FunctionNotStartedException(before);

        immutable returnTop = before.head;
        immutable returnScope = returnTop.currentScope;
        immutable resultIndex = VariableIndex(returnTop.index + 1);
        immutable resultEntry = VariableEntry(returnScope, resultIndex, targetType);
        variables_ = before.append(resultEntry);

        return Variable(returnScope.id, resultIndex);
    }

private:
    Rebindable!(List!VariableEntry) variables_;
    ScopeID lastScopeID_;

    this(FunctionType target) nothrow pure scope
    in (target !is null)
    out (r; variables_ !is null)
    {
        immutable firstScope = new Scope(lastScopeID_, target, null);
        this.variables_ = list(VariableEntry(firstScope, VariableIndex.init, target.argument));
    }

    Type getType(scope ref const(Variable) v) const pure scope
    out (r; r !is null)
    {
        immutable top = getScopeTop(v.scopeID);
        immutable entry = top.range.find!((e) => e.index == v.index); enforce!VariableIndexNotFoundException(!entry.empty);
        return entry.front.type;
    }

    List!VariableEntry getScopeTop(ScopeID id) const pure scope
    out (r; r !is null)
    {
        for (auto v = rebindable(variables_); v; v = v.head.currentScope.before)
        {
            if (v.head.currentScope.id == id)
            {
                return v;
            }
        }

        throw new OutOfScopeException("scope not found");
    }
}

///
pure unittest
{
    import poet.example : example;
    import poet.fun : funType;

    auto t = example();
    auto u = example();
    auto id = funType(t, t);
    auto f = funType(u, id);

    auto definition = new Definition(f);
    assert(definition.variables_.head.type.equals(u));
    assert(definition.variables_.head.currentScope.target.equals(f));

    auto argumentVariable = definition.begin();
    assert(definition.getType(argumentVariable).equals(t));
    assert(definition.variables_.head.type.equals(t));
    assert(definition.variables_.head.currentScope.target.equals(id));

    auto resultVariable = definition.end(argumentVariable);
    assert(definition.getType(resultVariable).equals(id));
    assert(definition.variables_.head.type.equals(id));
    assert(definition.variables_.head.currentScope.target.equals(f));
}

private:

/**
Definition scope.
*/
final immutable class CScope
{
    /**
    Scope identifier.
    */
    ScopeID id;

    /**
    Definition target.
    */
    FunctionType target;

    /**
    Current scope before position.
    */
    List!VariableEntry before;

    /**
    Returns:
        true if root scope.
    */
    @property bool root() @nogc nothrow pure scope
    {
        return before is null;
    }

    /**
    Constructor.

    Params:
        id = scope identifier.
        target = definition target function.
        before = scope before position. null if root scope.
    */
    this(ScopeID id, FunctionType target, List!VariableEntry before) @nogc nothrow pure scope
    in (target !is null)
    {
        this.id = id;
        this.target = target;
        this.before = before;
    }
}

alias Scope = immutable(CScope);

/**
Current variable entry.
*/
struct VariableEntry
{
    /**
    Current definition scope.
    */
    Scope currentScope;

    /**
    Current variable index.
    */
    VariableIndex index;

    /**
    Variable type.
    */
    Type type;
}

