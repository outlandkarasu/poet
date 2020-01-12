/**
Inductive type module.
*/
module poet.inductive.type;

import std.algorithm : equal, map;
import std.range : array;
import std.typecons : Typedef;

import poet.type : IType, Type;

@safe:

/**
Inductive value constructor index.
*/
alias InductiveIndex = Typedef!(size_t, size_t.init, "InductiveIndex");

/**
Inductive constructor.
*/
final immutable class CInductiveConstructor
{
    @property @nogc nothrow pure scope
    {
        Type[] argumentTypes()
        {
            return argumentTypes_;
        }
    }

private:
    Type[] argumentTypes_;

    this(Type[] argumentTypes) @nogc nothrow pure scope
    out (r; r.argumentTypes is argumentTypes)
    {
        this.argumentTypes_ = argumentTypes;
    }
}

alias InductiveConstructor = immutable(CInductiveConstructor);

/**
Inductive type.
*/
final immutable class CInductiveType : IType
{
    /**
    Params:
        constructors = inductive constructors.
    */
    this(scope Type[][] constructors...) nothrow pure scope
    {
        this.constructors_ = constructors
            .map!((c) => c.map!((t) => t.isSelfType ? this : t).array)
            .map!((c) => new InductiveConstructor(c))
            .array;
    }

    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        return this is other;
    }

    @property InductiveConstructor[] constructors() @nogc nothrow pure scope
    {
        return constructors_;
    }

private:
    InductiveConstructor[] constructors_;
}

///
pure unittest
{
    import poet.example : example;

    immutable t = cast(Type) example();
    immutable u = cast(Type) example();
    immutable v = cast(Type) example();
    immutable inductiveType = new InductiveType([], [t], [t, u, v], [SELF_TYPE]);
    assert(inductiveType.constructors.length == 4);
    assert(inductiveType.constructors[0].argumentTypes.length == 0);
    assert(inductiveType.constructors[1].argumentTypes == [t]);
    assert(inductiveType.constructors[2].argumentTypes == [t, u, v]);
    assert(inductiveType.constructors[3].argumentTypes == [cast(Type) inductiveType]);
}

alias InductiveType = immutable(CInductiveType);

/**
Self type indicator.
*/
Type SELF_TYPE = new InductiveSelfType();

/**
Params:
    t = check type.
Returns:
    true if t is self type.
*/
bool isSelfType(scope Type t) @nogc nothrow pure
{
    return SELF_TYPE.equals(t);
}

private:

/**
Inductive self type.
*/
final immutable class CInductiveSelfType : IType
{
    bool equals(scope Type other) @nogc nothrow pure scope
    {
        return this is other;
    }
}

alias InductiveSelfType = immutable(CInductiveSelfType);

