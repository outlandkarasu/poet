/**
Function type module.
*/
module poet.fun.type;

import poet.type : IType, Type;

@safe:

/**
Function type.
*/
final immutable class CFunctionType : IType
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
        auto otherFunction = cast(FunctionType) other;
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
    types = arguments and result.
Returns:
    new function type.
*/
FunctionType funType(scope Type[] types ...) nothrow pure
in (types.length >= 2)
out (r; r !is null)
{
    if (types.length == 2)
    {
        return new FunctionType(types[0], types[1]);
    }

    return new FunctionType(types[0], funType(types[1 .. $]));
}

///
nothrow pure unittest
{
    import poet.example : example;

    immutable t = example();
    immutable u = example();
    immutable f = funType(t, u);

    assert(f.argument.equals(t));
    assert(f.result.equals(u));

    assert(f.equals(f));
    assert(f.equals(funType(t, u)));

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

    immutable f1 = funType(a, b);
    assert(f1.argument.equals(a));
    assert(f1.result.equals(b));
    assert(f1.equals(funType(a, b)));

    immutable f2 = funType(a, b, c);
    assert(f2.argument.equals(a));
    assert(f2.result.equals(funType(b, c)));
    assert(f2.equals(funType(a, b, c)));

    immutable f3 = funType(a, b, c, r);
    assert(f3.argument.equals(a));
    assert(f3.result.equals(funType(b, c, r)));
    assert(f3.equals(funType(a, b, c, r)));
}


/**
Immutable function type.
*/
alias FunctionType = immutable(CFunctionType);

/**
Check argument types.

Params:
    f = function type.
    types = argument types.
Return:
    true if match all types.
*/
bool isMatchArguments(scope FunctionType f, scope Type[] types...) @nogc nothrow pure
in (f !is null)
{
    if (types.length == 0 || !types[0].equals(f.argument))
    {
        return false;
    }

    immutable result = cast(FunctionType) f.result;
    if (!result)
    {
        return types.length == 1;
    }

    return result.isMatchArguments(types[1 .. $]);
}

///
nothrow pure unittest
{
    import poet.example : example;

    immutable t = example();
    immutable u = example();
    immutable v = example();
    immutable f = funType(t, u, v);

    assert(f.isMatchArguments(t, u));
    assert(!f.isMatchArguments(t));
    assert(!f.isMatchArguments(u));
    assert(!f.isMatchArguments(t, u, v));
    assert(!f.isMatchArguments());
}

