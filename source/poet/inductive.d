/**
Inductive type module.
*/
module poet.inductive;

import std.typecons : Typedef;

import poet.type : Type;
import poet.value : Value;

@safe:

alias ConstructorID = Typedef!(size_t, size_t.init, "ConstructorID");

/**
Inductive type.
*/
final immutable class CInductiveType : Type
{
    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        return this is other;
    }

    ///
    nothrow pure unittest
    {
        immutable t = new InductiveType([]);
        immutable u = new InductiveType([]);
        assert(t.equals(t));
        assert(!t.equals(u));
    }

    /**
    Returns:
        Constructor values and functions.
    */
    @property Value[] constructors() @nogc nothrow pure scope
    {
        return [];
    }

private:

    this(Type[][] constructors) nothrow pure scope
    {
    }
}

alias InductiveType = immutable(CInductiveType);

/**
Inductive value.
*/
final immutable class CInductiveValue : Value
{
    @property @nogc nothrow pure scope
    {
        override InductiveType type()
        {
            return type_;
        }

        ConstructorID constructorID()
        {
            return constructorID_;
        }

        Value[] values()
        {
            return values_;
        }
    }

private:

    InductiveType type_;
    ConstructorID constructorID_;
    Value[] values_;

    this(InductiveType type, ConstructorID id, Value[] values) @nogc nothrow pure scope
    in (type !is null)
    {
        this.type_ = type;
        this.constructorID_ = id;
        this.values_ = values;
    }
}

alias InductiveValue = immutable(CInductiveValue);

