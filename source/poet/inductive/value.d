/**
Inductive value module.
*/
module poet.inductive.value;

import std.algorithm : equal, map;
import std.exception : enforce;

import poet.exception : UnmatchTypeException;
import poet.inductive.type : InductiveIndex, InductiveType;
import poet.value: IValue, Value;

@safe:

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

