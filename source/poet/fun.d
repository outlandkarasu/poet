/**
Function type module.
*/
module poet.fun;

import poet.type : IType, Type;

@safe:

/**
Function type.
*/
final immutable class CFunction : IType
{
    @property @nogc nothrow pure scope
    {
        /**
        Returns:
            argument type.
        */
        Type argument()
        out (r; r !is null)
        {
            return argument_;
        }

        /**
        Returns:
            result type.
        */
        Type result()
        out (r; r !is null)
        {
            return result_;
        }
    }

    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        auto otherFunction = cast(Function) other;
        if (otherFunction)
        {
            return argument_.equals(otherFunction.argument_)
                && result_.equals(otherFunction.result_);
        }

        return false;
    }

private:

    /**
    Default constructor.
    */
    this(Type argument, Type result) @nogc nothrow pure scope
    in (argument !is null)
    in (result !is null)
    {
        this.argument_ = argument;
        this.result_ = result;
    }

    Type argument_;
    Type result_;
}

/**
Create function type.

Params:
    argument = argument type.
    result = result type.
Returns:
    new function type.
*/
Function fun(Type argument, Type result) nothrow pure
{
    return new Function(argument, result);
}

///
nothrow pure unittest
{
    import poet.example : example;

    immutable t = example();
    immutable u = example();
    immutable f = fun(t, u);

    assert(f.argument.equals(t));
    assert(f.result.equals(u));

    assert(f.equals(f));
    assert(f.equals(fun(t, u)));

    assert(!f.equals(null));
    assert(!f.equals(t));
    assert(!f.equals(u));
}

/**
Immutable function.
*/
alias Function = immutable(CFunction);

