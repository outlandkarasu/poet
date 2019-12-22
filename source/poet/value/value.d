/**
Value module.
*/
module poet.value.value;

import poet.type : Type;

@safe:

/**
Value interface.
*/
immutable interface IValue
{
    /**
    Returns:
        value type.
    */
    @property Type type() @nogc nothrow pure scope
        out (r; r !is null);
}

alias Value = immutable(IValue);

