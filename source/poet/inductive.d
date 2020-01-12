/**
Inductive type module.
*/
module poet.inductive;

import std.algorithm : equal, map;
import std.exception : enforce;
import std.range : array;
import std.typecons : Typedef;

import poet.exception : UnmatchTypeException;
import poet.type : IType, Type;
import poet.value: IValue, Value;

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
    this(scope Type[][] constructors) nothrow pure scope
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
    immutable inductiveType = new InductiveType([[], [t], [t, u, v], [SELF_TYPE]]);
    assert(inductiveType.constructors.length == 4);
    assert(inductiveType.constructors[0].argumentTypes.length == 0);
    assert(inductiveType.constructors[1].argumentTypes == [t]);
    assert(inductiveType.constructors[2].argumentTypes == [t, u, v]);
    assert(inductiveType.constructors[3].argumentTypes == [cast(Type) inductiveType]);
}

alias InductiveType = immutable(CInductiveType);

/**
Inductive value.
*/
final immutable class CInductiveValue : IValue
{
    @property @nogc nothrow pure scope
    {
        override InductiveType type()
        {
            return type_;
        }

        InductiveIndex index()
        {
            return index_;
        }

        Value[] values()
        {
            return values_;
        }
    }

    /**
    Create inductive value.

    Params:
        type = inductive type.
        index = constructor index.
        values = contained values.
    Returns:
        inductive value.
    Throws: UnmatchTypeException if values unmatch constructor types.
    */
    static InductiveValue create(InductiveType type, InductiveIndex index, Value[] values) pure
    in (index < type.constructors.length)
    out(r; r.type is type)
    out(r; r.index == index)
    out(r; r.values is values)
    {
        auto valueTypes = values.map!((v) => v.type);
        immutable argumentTypes = type.constructors[cast(size_t) index].argumentTypes;
        enforce!UnmatchTypeException(
                valueTypes.equal!((a, b) => a.equals(b))(argumentTypes));
        return new InductiveValue(type, index, values);
    }

private:
    InductiveType type_;
    InductiveIndex index_;
    Value[] values_;

    this(Value[] values) @nogc nothrow pure scope
    {
        this.type_ = null;
        this.index_ = InductiveIndex.init;
        this.values_ = values;
    }

    this(InductiveType type, InductiveIndex index, Value[] values) @nogc nothrow pure scope
    {
        this.type_ = type;
        this.index_ = index;
        this.values_ = values;
    }
}

alias InductiveValue = immutable(CInductiveValue);

///
pure unittest
{
    import std.exception : assertThrown;
    import poet.example : example;

    immutable et = example();
    immutable t = new InductiveType([[et]]);

    immutable etv = et.createValue();
    immutable values = [cast(Value) etv];
    immutable value = InductiveValue.create(t, InductiveIndex(0), values);
    assert(value.type.equals(t));
    assert(value.index == InductiveIndex(0));
    assert(value.values.length == 1);
    assert(value.values[0] is etv);

    // unmatch value type.
    immutable unmatchValues = [cast(Value) example().createValue()];
    assertThrown!UnmatchTypeException(InductiveValue.create(t, InductiveIndex(0), unmatchValues));
}

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

