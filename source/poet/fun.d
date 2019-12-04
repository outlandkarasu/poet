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
    a = argument type.
    b = argument or result type.
    types = arguments and result.
Returns:
    new function type.
*/
Function fun(Type a, Type b, scope Type[] types ...) nothrow pure
in (a !is null)
in (b !is null)
out (r; r !is null)
{
    immutable r = (types.length == 0) ? b : fun(b, types[0], types[1 .. $]);
    return new Function(a, r);
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

///
nothrow pure unittest
{
    import poet.example : example;

    immutable a = example();
    immutable b = example();
    immutable c = example();
    immutable r = example();

    immutable f1 = fun(a, b);
    assert(f1.argument.equals(a));
    assert(f1.result.equals(b));
    assert(f1.equals(fun(a, b)));

    immutable f2 = fun(a, b, c);
    assert(f2.argument.equals(a));
    assert(f2.result.equals(fun(b, c)));
    assert(f2.equals(fun(a, b, c)));

    immutable f3 = fun(a, b, c, r);
    assert(f3.argument.equals(a));
    assert(f3.result.equals(fun(b, c, r)));
    assert(f3.equals(fun(a, b, c, r)));
}


/**
Immutable function.
*/
alias Function = immutable(CFunction);

