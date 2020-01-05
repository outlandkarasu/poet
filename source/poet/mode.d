/**
Context mode module.
*/
module poet.mode;

import poet.context2 : Context, ScopeID;
import poet.fun : FunctionType;
import poet.type : IType, Type;

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

