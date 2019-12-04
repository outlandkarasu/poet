/**
example type module.
*/
module poet.example;

import poet.type : IType, Type;

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

/**
Immutable Example.
*/
alias Example = immutable(CExample);

