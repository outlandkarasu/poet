/**
Type module.
*/
module poet.type;

@safe:

/**
Type interface.
*/
immutable interface IType
{
    /**
    Compare an other type.

    Params:
        other = an other type.
    Returns:
        true if this type equals other.
    */
    bool equals(scope Type other) @nogc nothrow pure scope;
}

/**
Immutable Type.
*/
alias Type = immutable(IType);

