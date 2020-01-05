/**
Context mode module.
*/ module poet.mode;

import std.exception : basicExceptionCtors, enforce;

import poet.context : Context, ContextException, next, ScopeID;
import poet.instruction : Instruction;
import poet.fun : FunctionType;
import poet.type : IType, Type;
import poet.value : IValue, Value;

@safe:

/**
Function defintion mode.
*/
final class DefineFunctionMode
{
    /**
    start definition by context and function type.

    Params:
        context = definition context
        type = function type
    */
    this(Context context, FunctionType type) pure scope
    in (context !is null)
    in (type !is null)
    {
        this.context_ = context;
        this.type_ = type;
        this.startScopeID_ = context.scopeID;

        auto argumentValue = new ArgumentValue(type.argument);
        context.pushScope(context.lastScopeID.next, argumentValue);
    }

    ///
    pure unittest
    {
        import poet.context : Variable, VariableIndex;
        import poet.example : example;
        import poet.fun : funType;

        immutable t = example();
        immutable u = example();
        immutable f = funType(t, u);

        auto c = new Context();
        auto df = new DefineFunctionMode(c, f);
        assert(c.lastScopeID == ScopeID(1));
        assert(c.scopeID == ScopeID(1));

        immutable a = cast(ArgumentValue) c.get(Variable(ScopeID(1), VariableIndex.init));
        assert(a.type.equals(ArgumentType.instance));
        assert(a.valueType.equals(t));
    }

    /**
    End definition.
    */
    void end()
    {
        enforce!ModeConflictException(context_.beforeScopeID == startScopeID_);

        Instruction[] instructions;
        foreach (Value v; context_)
        {
            immutable instructionValue = enforce!NotInstructionException(cast(InstructionValue) v);
            instructions ~= instructionValue.instruction;
        }

        context_.popScope();
    }

private:
    Context context_;
    FunctionType type_;
    ScopeID startScopeID_;
}

/**
Context mode unmatch scope ID exception.
*/
class ModeConflictException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

/**
Unexpected not instruction type exception.
*/
class NotInstructionException : ContextException
{
    ///
    mixin basicExceptionCtors;
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

final immutable class CInstructionType : IType
{
    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        return other is this;
    }

    static @property immutable(CInstructionType) instance() @nogc nothrow pure
    out (r; r !is null)
    {
        return instance_;
    }

private:
    static immutable(CInstructionType) instance_ = new immutable CInstructionType();
}

///
nothrow pure unittest
{
    import poet.example : example;

    assert(InstructionType.instance.equals(InstructionType.instance));
    assert(!InstructionType.instance.equals(example()));
}

alias InstructionType = immutable(CInstructionType);

final immutable class CInstructionValue : IValue
{
    this(Type valueType, Instruction instruction) @nogc nothrow pure scope
    in (valueType !is null)
    in (instruction !is null)
    {
        this.valueType_ = valueType;
        this.instruction_ = instruction;
    }

    @property @nogc nothrow pure scope
    {
        override Type type()
        {
            return InstructionType.instance;
        }

        Type valueType()
        out (r; r !is null)
        {
            return valueType_;
        }

        Instruction instruction()
        out (r; r !is null)
        {
            return instruction_;
        }
    }

private:
    Type valueType_;
    Instruction instruction_;
}

///
nothrow pure unittest
{
    import poet.example : example;
    import poet.instruction : NoopInstruction;

    immutable t = example();
    immutable v = new InstructionValue(t, NoopInstruction.instance);
    assert(v.type.equals(InstructionType.instance));
    assert(v.valueType.equals(t));
    assert(v.instruction is NoopInstruction.instance);
}

alias InstructionValue = immutable(CInstructionValue);

