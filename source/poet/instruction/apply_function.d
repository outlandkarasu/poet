/**
Apply function instruction module.
*/
module poet.instruction.apply_function;

import std.exception : enforce;

import poet.context : Context, Variable;
import poet.exception : UnmatchTypeException;
import poet.fun : FunctionType, FunctionValue;
import poet.instruction.instruction : Instruction, IInstruction;

@safe:

/**
apply function instruction.
*/
final immutable class CApplyFunctionInstruction : IInstruction
{
    /**
    Constructor.

    Params:
        f = function variable.
        a = argument variable.
    */
    this(Variable f, Variable a) @nogc nothrow pure scope
    {
        this.function_ = f;
        this.argument_ = a;
    }

    override void execute(scope Context context) pure scope
    in (false)
    {
        immutable f = enforce!UnmatchTypeException(cast(FunctionValue) context.get(function_));
        immutable result = f.execute(context.get(argument_));
        context.push(result);
    }

private:
    Variable function_;
    Variable argument_;
}

alias ApplyFunctionInstruction = immutable(CApplyFunctionInstruction);

