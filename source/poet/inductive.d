/**
Inductive type module.
*/
module poet.inductive;

import poet.type : IType, Type;

@safe:

/**
Inductive type.
*/
final immutable class CInductiveType : IType
{
    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        return this is other;
    }
}

alias InductiveType = immutable(CInductiveType);

