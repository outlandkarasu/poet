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
Variable out of scope exception.
*/
class OutOfScopeException : PoetException
{
    ///
    mixin basicExceptionCtors;
}

/**
Variable index not found exception.
*/
class VariableIndexNotFoundException : PoetException
{
    ///
    mixin basicExceptionCtors;
}

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
    */
    void pushScope(SV scopeValue, V value) nothrow pure scope
    {
        auto s = new Scope(ScopeID(lastScopeID_ + 1), scopeValue, variables_);
        variables_ = list(Entry(s, VariableIndex.init, value));
        lastScopeID_ = cast(size_t) s.id;
    }

    /**
    pop current scope.
    */
    void popScope() pure scope
    {
        immutable head = variables_.head;
        enforce!OutOfScopeException(head.currentScope.before !is null);
        variables_ = head.currentScope.before;
    }

    /**
    push new variable.

    Params:
        scopeValue = first scope value.
        value = first variable value.
    */
    void push(V value) nothrow pure scope
    {
        immutable head = variables_.head;
        variables_ = list(Entry(head.currentScope, VariableIndex(head.index + 1), value));
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
    alias Ctx = Context!(string, int);
    auto context = new Ctx("first scope", 123);
    auto v1 = Ctx.Variable(ScopeID(0), VariableIndex(0));
    assert(context.scopeValue == "first scope");
    assert(context.getValue(v1) == 123);

    context.push(223);
    auto v2 = Ctx.Variable(ScopeID(0), VariableIndex(1));
    assert(context.getValue(v2) == 223);

    context.pushScope("second scope", 1234);
    auto v3 = Ctx.Variable(ScopeID(1), VariableIndex(0));
    assert(context.scopeValue == "second scope");
    assert(context.getValue(v3) == 1234);
}

private:

alias ScopeID = Typedef!(size_t, size_t.init, "ScopeID");
alias VariableIndex = Typedef!(size_t, size_t.init, "VariableIndex");

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

