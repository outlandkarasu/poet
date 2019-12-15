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
    ImcompleteDefinitionException,
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
            cast(FunctionType) currentScope.target.result);

        auto newScopeID = ScopeID(lastScopeID_ + 1);
        immutable newScope = new Scope(newScopeID, functionType, variables_);
        immutable index = VariableIndex(0);
        variables_ = list(VariableEntry(newScope, index, functionType.argument));
        lastScopeID_ = newScopeID;
        return Variable(newScopeID, index);
    }

    /**
    Apply function.

    Params:
        f = function variable.
        a = function argument variable.
    Returns:
        function result variable.
    */
    Variable apply(const(Variable) f, const(Variable) a) pure scope
    out (r; getType(r).equals((cast(FunctionType) getType(f)).result))
    {
        immutable functionType = enforce!NotFunctionTypeException(cast(FunctionType) getType(f));
        immutable argumentType = getType(a);
        enforce!UnmatchTypeException(functionType.argument.equals(argumentType));
        return pushVariable(functionType.result);
    }

    /**
    End function definition.

    Params:
        result = result variable.
    Returns:
        defined function type.
    */
    Variable end(const(Variable) result) pure scope
    out (r; getType(r))
    {
        immutable resultType = getType(result);
        immutable targetType = currentScope.target;
        enforce!UnmatchTypeException(resultType.equals(targetType.result));

        immutable before = currentScope.before;
        enforce!FunctionNotStartedException(before);

        variables_ = before;
        return pushVariable(targetType);
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

    @property Scope currentScope() const @nogc nothrow pure scope
    out (r; r !is null)
    {
        return variables_.head.currentScope;
    }

    Variable pushVariable(Type variableType) nothrow pure scope
    out (r; getType(r).equals(variableType))
    {
        immutable index = VariableIndex(variables_.head.index + 1);
        variables_ = variables_.append(VariableEntry(currentScope, index, variableType));
        return Variable(currentScope.id, index);
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

/**
define function.

Params:
    target = target function type.
    def = define delegate.
*/
void define(FunctionType target, scope Variable delegate(scope Definition, const(Variable)) @safe pure def) pure
in (target !is null)
in (def !is null)
{
    scope d = new Definition(target);
    auto result = def(d, Variable(d.variables_.head.currentScope.id, VariableIndex(0)));
    enforce!UnmatchTypeException(d.getType(result).equals(target.result));
    enforce!ImcompleteDefinitionException(d.currentScope.before is null);
}

///
pure unittest
{
    import poet.example : example;
    import poet.fun : funType;

    auto t = example();
    auto u = example();
    auto v = example();
    auto f = funType(funType(t, u), funType(u, v), funType(t, v));

    // (t -> u) -> (u -> v) -> (t -> v)
    define(f, (scope d, a) {
        assert(d.getType(a).equals(funType(t, u)));

        // (u -> v) -> (t -> v)
        auto argumentUtoV = d.begin();
        assert(d.getType(argumentUtoV).equals(funType(u, v)));

        // t -> v
        auto argumentT = d.begin();
        assert(d.getType(argumentT).equals(t));

        auto resultU = d.apply(a, argumentT);
        assert(d.getType(resultU).equals(u));

        auto resultV = d.apply(argumentUtoV, resultU);
        assert(d.getType(resultV).equals(v));

        auto resultTtoV = d.end(resultV);
        assert(d.getType(resultTtoV).equals(funType(t, v)));

        auto resultUtoV_TtoV = d.end(resultTtoV);
        assert(d.getType(resultUtoV_TtoV).equals(funType(funType(u, v), funType(t, v))));

        return resultUtoV_TtoV;
    });
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

