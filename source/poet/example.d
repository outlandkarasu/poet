/**
example type module.
*/
module poet.example;

import poet.type : IType, Type;
import poet.value : IValue, Value;

@safe:

/**
Example type.
*/
final immutable class CExample : IType
{
    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        return this is other;
    }

    /**
    create example value.

    Returns:
        example value.
    */
    ExampleValue createValue() nothrow pure scope
    out (r; r !is null)
    out (r; r.type is this)
    {
        return new ExampleValue(this);
    }

private:

    /**
    Default constructor.
    */
    this() @nogc nothrow pure scope
    {
    }
}

/**
Returns:
    new example type.
*/
Example example() nothrow pure
out (r; r !is null)
{
    return new Example();
}

///
pure nothrow unittest
{
    immutable t = example();
    assert(t.equals(t));
    assert(!t.equals(null));

    immutable u = example();
    assert(u.equals(u));
    assert(!t.equals(u));
    assert(!u.equals(t));
}

///
pure nothrow unittest
{
    immutable t = example();
    immutable v1 = t.createValue();
    assert(v1.type is t);

    immutable v2 = t.createValue();
    assert(v2.type is t);
    assert(v1 !is v2);
}

/**
Immutable Example.
*/
alias Example = immutable(CExample);

private:

/**
Example value class.
*/
final immutable class CExampleValue : IValue
{
    @property Example type() @nogc nothrow pure scope
    {
        return type_;
    }

private:

    this(Example e) @nogc nothrow pure scope
    in (e !is null)
    {
        this.type_ = e;
    }

    Example type_;
}

alias ExampleValue = immutable(CExampleValue);

