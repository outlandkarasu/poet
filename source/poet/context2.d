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
    }

    /**
    Push new scope and value.

    Params:
        newScopeID = new scope ID
        value = pushing value
    Throws: InvalidScopeOrderException if new scope ID less than or equals current scope ID.
    */
    void pushScope(ScopeID newScopeID, Value value) pure scope
    in (value !is null)
    {
        enforce!InvalidScopeOrderException(scopeID < newScopeID);

        immutable newScope = new Scope(newScopeID, values_);
        this.values_ = list(ContextEntry(newScope, VariableIndex.init, value));
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

        c.pushScope(ScopeID(c.scopeID + 1), v);
        assert(c.scopeID == ScopeID(1));
        assert(c.index == VariableIndex.init);
        assert(c.get(Variable(ScopeID(c.scopeID), VariableIndex.init)) is v);
    }

    /**
    Push a value to current scope.

    Params:
        value = pushing value
    */
    void push(Value value) nothrow pure scope
    in (value !is null)
    {
        values_ = values_.append(ContextEntry(currentScope, VariableIndex(index + 1), value));
    }

    ///
    nothrow pure unittest
    {
        import poet.example : example;

        auto c = new Context();

        auto v = example().createValue();
        c.push(v);
        assert(c.scopeID == ScopeID.init);
        assert(c.index == VariableIndex(1));
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

