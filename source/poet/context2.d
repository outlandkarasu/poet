/**
Context module.
*/
module poet.context2;

import std.exception : basicExceptionCtors, enforce;
import std.typecons : Rebindable, rebindable, Typedef;

import poet.exception : PoetException;
import poet.type : IType, Type;
import poet.utils : List, list;
import poet.value : IValue, Value;

@safe:

/**
Context scope ID.
*/
alias ScopeID = Typedef!(size_t, size_t.init, "ScopeID");

/**
Context variable index.
*/
alias VariableIndex = Typedef!(size_t, size_t.init, "VariableIndex");

/**
Context variable.
*/
struct Variable
{
private:
    ScopeID scopeID;
    VariableIndex index;
}

/**
Value context.
*/
final class Context
{
    /**
    construct with root scope.
    */
    this() nothrow pure scope
    {
        immutable rootScope = new Scope(ScopeID.init, null);
        this.values_ = list(ContextEntry(rootScope, VariableIndex.init, RootValue.instance));
    }

    @property const nothrow pure
    {
        VariableIndex index() @nogc scope
        {
            return values_.head.index;
        }

        ///
        unittest
        {
            auto c = new Context();
            assert(c.scopeID == ScopeID.init);
        }

        ScopeID scopeID() @nogc scope
        {
            return currentScope.id;
        }

        ///
        unittest
        {
            auto c = new Context();
            assert(c.index == VariableIndex.init);
        }

        Variable lastVariable() @nogc scope
        {
            return Variable(scopeID, values_.head.index);
        }

        ///
        unittest
        {
            auto c = new Context();
            assert(c.lastVariable == Variable(c.scopeID, VariableIndex.init));
        }
    }

    /**
    Push new scope and value.

    Params:
        newScopeID = new scope ID
        value = pushing value
    Returns:
        pushed value variable.
    Throws: InvalidScopeOrderException if new scope ID less than or equals current scope ID.
    */
    Variable pushScope(ScopeID newScopeID, Value value) pure scope
    in (value !is null)
    {
        enforce!InvalidScopeOrderException(scopeID < newScopeID);

        immutable newScope = new Scope(newScopeID, values_);
        this.values_ = list(ContextEntry(newScope, VariableIndex.init, value));

        return lastVariable;
    }

    ///
    pure unittest
    {
        import std.exception : assertThrown;
        import poet.example : example;

        auto c = new Context();
        auto v = example().createValue();

        // invalid order scope ID.
        assertThrown!InvalidScopeOrderException(c.pushScope(ScopeID(0), v));

        auto vv = c.pushScope(ScopeID(c.scopeID + 1), v);
        assert(c.scopeID == ScopeID(1));
        assert(c.index == VariableIndex.init);
        assert(vv == Variable(ScopeID(1), VariableIndex.init));
        assert(c.get(vv) is v);
    }

    /**
    Pop current scope.

    Throws: InvalidScopeOrderException if new scope ID less than or equals current scope ID.
    */
    void popScope() pure scope
    {
        enforce!CannotPopScopeException(currentScope.before);
        values_ = currentScope.before;
    }

    ///
    pure unittest
    {
        import std.exception : assertThrown;
        import poet.example : example;

        auto c = new Context();
        auto v1 = example().createValue();
        auto vv1 = c.push(v1);

        auto v2 = example().createValue();
        auto vv2 = c.pushScope(ScopeID(c.scopeID + 1), v2);

        assert(c.get(vv1) is v1);
        assert(c.get(vv2) is v2);

        c.popScope();
        assert(c.get(vv1) is v1);
        assert(c.getOrNull(vv2) is null);

        assertThrown!CannotPopScopeException(c.popScope());
    }

    /**
    Push a value to current scope.

    Params:
        value = pushing value
    Returns:
        pushed value variable.
    */
    Variable push(Value value) nothrow pure scope
    in (value !is null)
    {
        values_ = values_.append(ContextEntry(currentScope, VariableIndex(index + 1), value));
        return lastVariable;
    }

    ///
    pure unittest
    {
        import poet.example : example;

        auto c = new Context();

        auto v = example().createValue();
        auto vv = c.push(v);
        assert(c.scopeID == ScopeID.init);
        assert(c.index == VariableIndex(1));
        assert(c.get(vv) is v);
    }

    /**
    Get a value by variable.

    Params:
        v = a value pointed variable.
    Returns:
        pointed value or null.
    */
    Value getOrNull()(auto scope ref const(Variable) v) const @nogc nothrow pure scope
    {
        immutable scopeTop = getScopeTopOrNull(v.scopeID);
        if (scopeTop is null)
        {
            return null;
        }

        for (Rebindable!(List!ContextEntry) e = scopeTop; e; e = e.tail)
        {
            if (e.head.index == v.index)
            {
                return e.head.value;
            }
        }

        return null;
    }

    ///
    nothrow pure unittest
    {
        auto c = new Context();

        // scope not found.
        assert(c.getOrNull(Variable(ScopeID(123), VariableIndex.init)) is null);

        // value not found.
        assert(c.getOrNull(Variable(ScopeID.init, VariableIndex(1))) is null);

        // found root value.
        assert(c.getOrNull(Variable(ScopeID.init, VariableIndex.init)) is RootValue.instance);
    }

    /**
    Get a value or throw exception.

    Params:
        v = value variable.
    Returns:
        a value.
    Throws: VariableNotFoundException if value not found.
    */
    Value get()(auto scope ref const(Variable) v) const pure scope
    out (r; r !is null)
    {
        return enforce!VariableNotFoundException(getOrNull(v));
    }

    ///
    pure unittest
    {
        import std.exception : assertThrown;

        auto c = new Context();

        // scope not found.
        assertThrown!VariableNotFoundException(c.get(Variable(ScopeID(123), VariableIndex.init)));

        // value not found.
        assertThrown!VariableNotFoundException(c.get(Variable(ScopeID.init, VariableIndex(1))));

        // found root value.
        assert(c.get(Variable(ScopeID.init, VariableIndex.init)) is RootValue.instance);
    }

    /**
    foreach implement.

    Params:
        dg = foreach delegate.
    Returns:
        foreach result.
    */
    int opApply(Dg)(scope Dg dg)
    {
        return opApplyImpl(scopeID, values_, dg);
    }

    ///
    pure unittest
    {
        import poet.example : example;


        auto c = new Context();

        immutable v1 = example().createValue();
        immutable v2 = example().createValue();
        immutable v3 = example().createValue();
        c.push(v1);
        c.push(v2);
        c.push(v3);

        Value[] values;
        foreach (Value value; c)
        {
            values ~= value;
        }

        assert(values.length == 3);
        assert(values[0] is v1);
        assert(values[1] is v2);
        assert(values[2] is v3);

        immutable v4 = example().createValue();
        c.pushScope(ScopeID(1), v4);

        values = [];
        foreach (Value value; c)
        {
            values ~= value;
        }

        assert(values.length == 1);
        assert(values[0] is v4);
    }

private:
    Rebindable!(List!ContextEntry) values_;

    @property const @nogc nothrow pure scope
    {
        Scope currentScope()
        out(r; r !is null)
        {
            return values_.head.currentScope;
        }

        List!ContextEntry getScopeTopOrNull(ScopeID id)
        {
            for (Rebindable!(List!ContextEntry) l = values_; l; l = l.head.currentScope.before)
            {
                if (l.head.currentScope.id == id)
                {
                    return l;
                }
            }
            return null;
        }
    }

    int opApplyImpl(Dg)(ScopeID id, scope List!ContextEntry entry, scope Dg dg)
    {
        if (entry.tail && entry.tail.head.currentScope.id == id)
        {
            immutable result = opApplyImpl(id, entry.tail, dg);
            if (result)
            {
                return result;
            }
        }

        if (entry.head.currentScope.id != id || entry.head.value is RootValue.instance)
        {
            return 0;
        }

        return dg(entry.head.value);
    }
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
Context variable not found exception.
*/
class VariableNotFoundException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

/**
Invalid scope order exception.
*/
class InvalidScopeOrderException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

/**
Cannot pop scope exception.
*/
class CannotPopScopeException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

private:

final immutable class CRootType : IType
{
    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        return other is this;
    }

    static @property immutable(CRootType) instance() @nogc nothrow pure
    out (r; r !is null)
    {
        return instance_;
    }

private:
    static immutable(CRootType) instance_ = new immutable RootType();
}

///
nothrow pure unittest
{
    import poet.example : example;

    assert(RootType.instance.equals(RootType.instance));
    assert(!RootType.instance.equals(example()));
}

alias RootType = immutable(CRootType);

final immutable class CRootValue : IValue
{
    override @property Type type() @nogc nothrow pure scope
    {
        return RootType.instance;
    }

    static @property immutable(CRootValue) instance() @nogc nothrow pure
    out (r; r !is null)
    {
        return instance_;
    }

private:
    static immutable(CRootValue) instance_ = new immutable RootValue();
}

///
@nogc nothrow pure unittest
{
    assert(RootValue.instance.type.equals(RootType.instance));
}

alias RootValue = immutable(CRootValue);

struct ContextEntry
{
    Scope currentScope;
    VariableIndex index;
    Value value;
}

final immutable class CScope
{
    this(ScopeID id, List!ContextEntry before) @nogc nothrow pure scope
    {
        this.id = id;
        this.before = before;
    }

    ScopeID id;
    List!ContextEntry before;
}

alias Scope = immutable(CScope);

