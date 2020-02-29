/**
Define function mode module.
*/
module poet.fun.define_function;

import std.exception : basicExceptionCtors, enforce;

import poet.context : Context, ContextException, next, ScopeID, Variable;
import poet.exception : UnmatchTypeException;
import poet.fun.apply_function : ApplyFunctionInstruction;
import poet.fun.create_function : CreateFunctionInstruction;
import poet.fun.type : FunctionType;
import poet.instruction : Instruction;
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
        this.scopeID_ = context.lastScopeID.next;

        auto argumentValue = new ArgumentValue(type.argument);
        context.pushScope(scopeID_, argumentValue);
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

        immutable a = cast(ArgumentValue) c.get(c.lastVariable);
        assert(a.type.equals(ArgumentType.instance));
        assert(a.valueType.equals(t));
    }

    @property const @nogc nothrow pure scope
    {
        FunctionType type()
        out (r; r !is null)
        {
            return type_;
        }

        Type resultType()
        out (r; r !is null)
        {
            return type_.result;
        }

        Type argumentType()
        out (r; r !is null)
        {
            return type_.argument;
        }

        ScopeID scopeID()
        {
            return scopeID_;
        }
    }

    /**
    Apply function.

    Params:
        f = function variable.
        a = argument variable.
    Returns:
        result variable.
    */
    Variable apply()(auto scope ref const(Variable) f, auto scope ref const(Variable) a)
    out (r; getType(r).equals((cast(FunctionType) getType(f)).result))
    {
        immutable functionType = enforce!NotFunctionException(cast(FunctionType) getType(f));
        enforce!UnmatchTypeException(functionType.argument.equals(getType(a)));

        immutable applyFunction = new ApplyFunctionInstruction(f, a);
        return pushInstruction(functionType.result, applyFunction);
    }

    ///
    pure unittest
    {
        import poet.context : Variable, VariableIndex;
        import poet.example : example;
        import poet.fun : funType;

        immutable t = example();
        immutable u = example();
        immutable f1 = funType(t, u);
        immutable f2 = funType(f1, u);

        auto c = new Context();
        immutable tv = c.push(t.createValue());
        auto df = new DefineFunctionMode(c, f2);
        immutable rv = df.apply(c.lastVariable, tv);
        assert(c.get(rv).type.equals(InstructionType.instance));
        assert((cast(InstructionValue) c.get(rv)).valueType.equals(u));
    }

    /**
    Push instruction.

    Params:
        resultType = instruction result type.
        instruction = pushing instruction.
    Returns:
        result variable.
    */
    Variable pushInstruction()(Type resultType, Instruction instruction)
    out (r; getType(r).equals(resultType))
    {
        return context_.push(new InstructionValue(resultType, instruction));
    }

    /**
    End definition.

    Params:
        result = result variable.
    Returns:
        create function instruction value.
    */
    InstructionValue end()(auto scope ref const(Variable) result)
    out (r; r !is null)
    out (r; r.valueType.equals(type_))
    {
        enforce!ModeConflictException(context_.beforeScopeID == startScopeID_);
        enforce!UnmatchTypeException(getType(result).equals(type_.result));

        Instruction[] instructions;
        foreach (Value v; context_)
        {
            // skip argument.
            if (v.type.equals(ArgumentType.instance))
            {
                continue;
            }

            immutable instructionValue = enforce!NotInstructionException(cast(InstructionValue) v);
            instructions ~= instructionValue.instruction;
        }

        // create a function constructor.
        immutable createFunction = new CreateFunctionInstruction(type_, instructions, result, scopeID_);
        immutable createFunctionValue = new InstructionValue(type_, createFunction);

        // close definition scope.
        context_.popScope();

        return createFunctionValue;
    }

    ///
    pure unittest
    {
        import poet.context : Variable, VariableIndex;
        import poet.example : example;
        import poet.fun : funType, FunctionValue;

        immutable t = example();
        immutable f = funType(t, t);

        auto c = new Context();
        auto df = new DefineFunctionMode(c, f);
        immutable createFunction = df.end(Variable(ScopeID(1), VariableIndex.init));
        assert(createFunction.valueType.equals(f));
        assert(c.scopeID == ScopeID.init);
        assert(c.lastScopeID == ScopeID(1));

        // execute created function.
        createFunction.instruction.execute(c);
        immutable fv = c.get(Variable(ScopeID.init, VariableIndex(1)));
        assert(fv.type.equals(f));

        immutable tv = t.createValue();
        assert((cast(FunctionValue) fv).execute(tv) is tv);
    }

    /**
    End definition and push instruction.

    Params:
        result = result variable.
    Returns:
        create function instruction variable.
    */
    Variable endAndPush()(auto scope ref const(Variable) result)
    out (r; getType(r).equals(type_))
    out (r; context_.get(r).type.equals(InstructionType.instance))
    {
        immutable createFunctionValue = end(result);
        return context_.push(createFunctionValue);
    }

    ///
    pure unittest
    {
        import poet.context : Variable, VariableIndex;
        import poet.example : example;
        import poet.fun : funType, FunctionValue;

        immutable t = example();
        immutable f = funType(t, t);

        auto c = new Context();
        auto df = new DefineFunctionMode(c, f);
        immutable createFunctionVariable = df.endAndPush(Variable(ScopeID(1), VariableIndex.init));
        immutable result = cast(InstructionValue) c.get(createFunctionVariable);
        assert(result !is null);
        assert(result.valueType.equals(f));

        // execute created function.
        result.instruction.execute(c);
        immutable fv = c.get(Variable(ScopeID.init, VariableIndex(2)));
        assert(fv.type.equals(f));

        immutable tv = t.createValue();
        assert((cast(FunctionValue) fv).execute(tv) is tv);
    }

    /**
    End definition and create function.

    Params:
        result = result variable.
    Returns:
        created function variable.
    */
    Variable endAndCreate()(auto scope ref const(Variable) result)
    out (r; getType(r).equals(type_))
    out (r; context_.get(r).type.equals(type_))
    {
        immutable createFunctionValue = end(result);
        createFunctionValue.instruction.execute(context_);
        return context_.lastVariable;
    }

    ///
    pure unittest
    {
        import poet.context : Variable, VariableIndex;
        import poet.example : example;
        import poet.fun : funType, FunctionValue;

        immutable t = example();
        immutable f = funType(t, t);

        auto c = new Context();
        auto df = new DefineFunctionMode(c, f);
        immutable functionVariable = df.endAndCreate(Variable(ScopeID(1), VariableIndex.init));
        immutable result = cast(FunctionValue) c.get(functionVariable);
        assert(result !is null);
        assert(result.type.equals(f));

        // execute created function.
        immutable tv = t.createValue();
        assert(result.execute(tv) is tv);
    }

    /**
    Get variable type in runtime.

    Params:
        v = target variable.
    Returns:
        variable type in runtime.
    */
    Type getType()(auto scope ref const(Variable) v) pure scope
    out (r; r !is null)
    {
        immutable value = context_.get(v);
        if (value.type.equals(ArgumentType.instance))
        {
            return (cast(ArgumentValue) value).valueType;
        }

        if (value.type.equals(InstructionType.instance))
        {
            return (cast(InstructionValue) value).valueType;
        }

        return value.type;
    }

private:

    Context context_;
    FunctionType type_;
    ScopeID startScopeID_;
    ScopeID scopeID_;
}

///
pure unittest
{
    import poet.context : Variable, VariableIndex;
    import poet.example : example;
    import poet.fun : funType, FunctionValue;

    immutable x = example();
    immutable y = example();
    immutable z = example();

    immutable xy = funType(x, y);
    immutable yz = funType(y, z);
    immutable xz = funType(x, z);
    immutable f = funType(xy, yz, xz);

    // start definition (X -> Y) -> (Y -> Z) -> (X -> Z)
    auto c = new Context();

    // introduce (X -> Y), target (Y -> Z) -> (X -> Z)
    auto defXYYZXZ = new DefineFunctionMode(c, f);
      auto varXY = c.lastVariable;

      // introduce (Y -> Z), target (X -> Z)
      auto defYZXZ = new DefineFunctionMode(c, funType(yz, xz));
        auto varYZ = c.lastVariable;

        // introduce X, target Z
        auto defXZ = new DefineFunctionMode(c, xz);
          auto varX = c.lastVariable;

          // (X -> Y) x
          auto resultY = defXZ.apply(varXY, varX);

          // (Y -> Z) y
          auto resultZ = defXZ.apply(varYZ, resultY);
        auto resultXZ = defXZ.endAndPush(resultZ);
      auto resultYZXZ = defYZXZ.endAndPush(resultXZ);

    // create target function value.
    auto result = defXYYZXZ.endAndCreate(resultYZXZ);
    immutable functionValue = cast(FunctionValue) c.get(result);

    assert(functionValue !is null);
    assert(functionValue.type.equals(f));
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

/**
Unexpected not function type exception.
*/
class NotFunctionException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

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

