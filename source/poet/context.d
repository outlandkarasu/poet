/**
Generic context module.
*/
module poet.context;

import std.algorithm : find;
import std.exception : basicExceptionCtors, enforce;
import std.typecons : Rebindable, rebindable, Typedef;

import poet.exception : PoetException;
import poet.list : List, list;

@safe:

/**
Context scope ID.
*/
alias ScopeID = Typedef!(size_t, 0, "ScopeID");

/**
Context variable index.
*/
alias VariableIndex = Typedef!(size_t, 0, "VariableIndex");

/**
Generic context.

Params:
    SV scope value type.
    V = value type.
*/
final class Context(SV, V)
{
    /**
    Variable.
    */
    struct Variable
    {
    private:

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
    constructor.

    Params:
        scopeValue = first scope value.
        value = first variable value.
    */
    this(SV scopeValue, V value) nothrow pure scope
    {
        auto s = new Scope(lastScopeID_, scopeValue, null);
        this.variables_ = list(Entry(s, VariableIndex.init, value));
    }

    /**
    push new scope.

    Params:
        scopeValue = first scope value.
        value = first variable value.
    Returns:
        first variable.
    */
    Variable pushScope(SV scopeValue, V value) nothrow pure scope
    {
        auto sid = ScopeID(lastScopeID_ + 1);
        auto index = VariableIndex.init;
        immutable s = new Scope(sid, scopeValue, variables_);
        variables_ = variables_.append(Entry(s, index, value));
        lastScopeID_ = sid;
        return Variable(sid, index);
    }

    /**
    pop current scope.
    */
    void popScope() pure scope
    out (; variables_ !is null)
    {
        enforce!ScopeNotStartedException(!rootScope);
        variables_ = variables_.head.currentScope.before;
    }

    /**
    push new variable.

    Params:
        scopeValue = first scope value.
        value = first variable value.
    Returns:
        pushed variable.
    */
    Variable push(V value) nothrow pure scope
    {
        immutable head = variables_.head;
        immutable s = head.currentScope;
        immutable index = VariableIndex(head.index + 1);
        variables_ = variables_.append(Entry(s, index, value));
        return Variable(s.id, index);
    }

    /**
    Params:
        v = variable.
    Returns:
        found value.
    Throws:
        OutOfScopeException if v scope is not found.
        VariableIndexNotFoundException if v index is not found.
    */
    ref immutable(V) getValue()(auto scope ref const(Variable) v) const pure return scope
    {
        auto top = getScopeTop(v.scopeID);
        for (auto e = rebindable(top); e; e = e.tail)
        {
            if (e.head.index == v.index)
            {
                return e.head.value;
            }
        }
        throw new VariableIndexNotFoundException("variable not found.");
    }

    /**
    Returns:
        current scope value.
    */
    @property ref immutable(SV) scopeValue() const @nogc nothrow pure return scope
    {
        return variables_.head.currentScope.value;
    }

    /**
    Returns:
        current scope is root.
    */
    @property bool rootScope() const @nogc nothrow pure scope
    {
        return variables_.head.currentScope.before is null;
    }

private:

    alias Scope = immutable(CScope!(SV, V));
    alias Entry = immutable(VariableEntry!(SV, V));

    List!Entry getScopeTop(ScopeID scopeID) const pure return scope
    out (r; r !is null)
    {
        auto found = variables_.range.find!((e) => e.currentScope.id == scopeID);
        enforce!OutOfScopeException(!found.empty);
        return found.list;
    }

    Rebindable!(List!Entry) variables_;
    ScopeID lastScopeID_;
}

///
pure unittest
{
    import std.exception : assertThrown;

    alias Ctx = Context!(string, int);
    auto context = new Ctx("first scope", 123);
    assert(context.scopeValue == "first scope");
    assert(context.rootScope);
    assertThrown!ScopeNotStartedException(context.popScope());

    // get first variable.
    auto v1 = Ctx.Variable.init;
    assert(context.getValue(v1) == 123);
    assert(context.rootScope);

    // push second variable.
    auto v2 = context.push(223);
    assert(v2.scopeID == 0);
    assert(v2.index == 1);
    assert(context.getValue(v2) == 223);
    assert(context.rootScope);

    // push new scope.
    auto v3 = context.pushScope("second scope", 1234);
    assert(v3.scopeID == 1);
    assert(v3.index == 0);
    assert(context.scopeValue == "second scope");
    assert(context.getValue(v3) == 1234);
    assert(!context.rootScope);

    // get pushed variables.
    assert(context.getValue(v1) == 123);
    assert(context.getValue(v2) == 223);

    // pop scope.
    context.popScope();
    assert(context.getValue(v1) == 123);
    assert(context.getValue(v2) == 223);
    assertThrown!OutOfScopeException(context.getValue(v3));
    assert(context.rootScope);

    auto v4 = context.push(333);
    assert(context.getValue(v1) == 123);
    assert(context.getValue(v2) == 223);
    assert(context.getValue(v4) == 333);

    auto v5 = context.pushScope("third scope", 12345);
    assert(context.getValue(v1) == 123);
    assert(context.getValue(v2) == 223);
    assertThrown!OutOfScopeException(context.getValue(v3));
    assert(context.getValue(v4) == 333);
    assert(context.getValue(v5) == 12345);
    assert(context.scopeValue == "third scope");
    assert(!context.rootScope);
}

/**
Context exception.
*/
class ContextException : PoetException
{
    ///
    mixin basicExceptionCtors;
}

/**
Variable out of scope exception.
*/
class OutOfScopeException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

/**
Variable index not found exception.
*/
class VariableIndexNotFoundException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

/**
scope not started exception.
*/
class ScopeNotStartedException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

private:

final immutable class CScope(SV, V)
{
    ScopeID id;
    SV value;
    List!(immutable(VariableEntry!(SV, V))) before;

    this(ScopeID id, SV value, List!(immutable(VariableEntry!(SV, V))) before) @nogc nothrow pure scope
    {
        this.id = id;
        this.value = value;
        this.before = before;
    }
}

struct VariableEntry(SV, V)
{
    immutable(CScope!(SV, V)) currentScope;
    VariableIndex index;
    V value;
}

