/**
Function value module.
*/
module poet.value.fun_value;

import poet.fun : FunctionType;
import poet.value.value : Value;

@safe:

immutable class CFunction : Value
{
    override @property FunctionType type() @nogc nothrow pure scope
    {
        return type_;
    }

private:

    FunctionType type_;

    this(FunctionType type) @nogc nothrow pure scope
    in (type !is null)
    {
        this.type_ = type;
    }
}

///
nothrow pure unittest
{
    import poet.example : example;
    import poet.fun : funType;

    immutable t = example();
    immutable u = example();
    immutable ftype = funType(t, u);
    immutable f = new Function(ftype);
    assert(f.type is ftype);
}

alias Function = immutable(CFunction);

