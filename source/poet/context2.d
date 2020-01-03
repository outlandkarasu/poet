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
}

///
nothrow pure unittest
{
    import poet.example : example;

    immutable t = new RootType();
    immutable u = new RootType();

    assert(t.equals(t));
    assert(!t.equals(u));
}

alias RootType = immutable(CRootType);

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

