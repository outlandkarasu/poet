/**
Context module.
*/
module poet.context2;

import std.typecons : Typedef;

import poet.type : IType, Type;
import poet.utils : List;
import poet.value : IValue, Value;

@safe:

/**
Value context type.
*/
final class Context
{
private:
    List!ContextEntry values_;
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

alias ScopeID = Typedef!(size_t, size_t.init, "ScopeID");

struct ContextEntry
{
    Scope currentScope;
    Value value;
}

final immutable class CScope
{
    List!ContextEntry before;
    ScopeID scopeID;
}

alias Scope = immutable(CScope);

