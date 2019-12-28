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
    Context state save point.
    */
    struct SavePoint
    {
    private:
        List!Entry variables;
        ScopeID lastScopeID;
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
    constructor by save point.

    Params:
        savePoint = save point.
    */
    this()(auto ref const(SavePoint) savePoint) nothrow pure scope
    {
        this.variables_ = savePoint.variables;
        this.lastScopeID_ = savePoint.lastScopeID;
    }

    /**
    push new scope.

    Params:
        sid = new scope ID.
        scopeValue = first scope value.
        value = first variable value.
    Returns:
        first variable.
    */
    Variable pushScope(ScopeID sid, SV scopeValue, V value) nothrow pure scope
    in (lastScopeID_ < sid)
    {
        auto index = VariableIndex.init;
        immutable s = new Scope(sid, scopeValue, variables_);
        variables_ = variables_.append(Entry(s, index, value));
        lastScopeID_ = sid;
        return Variable(sid, index);
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
        return pushScope(ScopeID(lastScopeID_ + 1), scopeValue, value);
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

    /**
    Returns:
        current save point.
    */
    SavePoint save() const @nogc nothrow pure scope
    {
        return SavePoint(variables_, lastScopeID_);
    }

    /**
    Returns:
        current scope ID.
    */
    @property ScopeID scopeID() const @nogc nothrow pure scope
    {
        return variables_.head.currentScope.id;
    }

    /**
    Returns:
        last variable.
    */
    @property Variable lastVariable() const @nogc nothrow pure scope
    {
        immutable head = variables_.head;
        return Variable(head.currentScope.id, head.index);
    }

    /**
    Params:
        dg = foreach delegate.
    Returns:
        loop result.
    */
    int opApply(scope int delegate(ref immutable(V)) nothrow pure @safe dg) nothrow pure scope
    {
        return opApplyReverseImpl(variables_, dg);
    }

private:

    alias Scope = immutable(CScope!(SV, V));
    alias Entry = immutable(VariableEntry!(SV, V));

    int opApplyReverseImpl(scope List!Entry variables, scope int delegate(ref immutable(V)) nothrow pure @safe dg) nothrow pure scope
    {
        if (variables.tail && variables.tail.head.currentScope.id == scopeID)
        {
            auto tailResult = opApplyReverseImpl(variables.tail, dg);
            if (tailResult)
            {
                return tailResult;
            }
        }

        return dg(variables.head.value);
    }

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

///
pure unittest
{
    import std.exception : assertThrown;

    alias Ctx = Context!(string, int);
    auto context = new Ctx("first scope", 123);
    auto v1 = Ctx.Variable.init;
    auto v2 = context.push(456);

    auto saved = context.save();
    auto v3 = context.push(789);

    auto savedContext = new Ctx(saved);
    auto v4 = savedContext.pushScope("second scope", 901);
    assert(savedContext.getValue(v1) == 123);
    assert(savedContext.getValue(v2) == 456);
    assert(savedContext.getValue(v4) == 901);
    assertThrown!VariableIndexNotFoundException(savedContext.getValue(v3));

    auto v5 = context.pushScope(ScopeID(2), "third scope", 321);
    assert(savedContext.getValue(v1) == 123);
    assert(savedContext.getValue(v2) == 456);
    assert(context.getValue(v3) == 789);
    assertThrown!OutOfScopeException(context.getValue(v4));
    assert(context.getValue(v5) == 321);
}

///
pure unittest
{
    alias Ctx = Context!(string, int);
    auto context = new Ctx("first scope", 1);
    context.push(2);
    context.push(3);

    int[] values;
    foreach (v; context)
    {
        values ~= v;
    }

    assert(values[] == [1, 2, 3]);

    context.pushScope("second scope", 100);
    context.push(200);
    context.push(300);

    values = [];
    foreach (v; context)
    {
        values ~= v;
    }

    assert(values[] == [100, 200, 300]);

    context.popScope();
    values = [];
    foreach (v; context)
    {
        values ~= v;
    }

    assert(values[] == [1, 2, 3]);
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

