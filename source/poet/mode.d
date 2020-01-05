/**
Context mode module.
*/
module poet.mode;

import poet.context2 : Context, ScopeID;
import poet.fun : FunctionType;
import poet.type : IType, Type;
import poet.value : IValue;

@safe:

/**
Function defintion mode.
*/
final class DefineFunctionMode
{
    /**
    Params:
        context = definition context
        type = function type
    */
    this(Context context, FunctionType type) @nogc nothrow pure scope
    in (context !is null)
    in (type !is null)
    {
        this.context_ = context;
        this.type_ = type;
        this.startScopeID_ = context.scopeID;
    }

private:
    Context context_;
    FunctionType type_;
    ScopeID startScopeID_;
}

private:

final immutable class CArgumentType : IType
{
    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        return other is this;
    }

    static @property immutable(CArgumentType) instance() @nogc nothrow pure
    out (r; r !is null)
    {
        return instance_;
    }

private:
    static immutable(CArgumentType) instance_ = new immutable CArgumentType();
}

///
nothrow pure unittest
{
    import poet.example : example;

    assert(ArgumentType.instance.equals(ArgumentType.instance));
    assert(!ArgumentType.instance.equals(example()));
}

alias ArgumentType = immutable(CArgumentType);

final immutable class CArgumentValue : IValue
{
    this(Type valueType) @nogc nothrow pure scope
    in (valueType !is null)
    {
        this.valueType_ = valueType;
    }

    @property @nogc nothrow pure scope
    {
        override Type type()
        {
            return ArgumentType.instance;
        }

        Type valueType()
        {
            return valueType_;
        }
    }

private:
    Type valueType_;
}

///
nothrow pure unittest
{
    import poet.example : example;

    immutable t = example();
    immutable v = new ArgumentValue(t);
    assert(v.type.equals(ArgumentType.instance));
    assert(v.valueType.equals(t));
}

alias ArgumentValue = immutable(CArgumentValue);

