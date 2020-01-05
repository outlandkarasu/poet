/**
Create function instruction module.
*/
module poet.instruction.create_function;

import poet.context : Context, Variable;
import poet.fun : FunctionType;
import poet.instruction.instruction : Instruction, IInstruction;

@safe:

/**
create function instruction.
*/
final immutable class CCreateFunctionInstruction : IInstruction
{
    this(FunctionType type, Instruction[] instructions, Variable result)
    in (type !is null)
    {
        this.type_ = type;
        this.instructions_ = instructions;
        this.result_ = result;
    }

    override void execute(scope Context context) pure scope
    in (false)
    {
    }

private:
    FunctionType type_;
    Instruction[] instructions_;
    Variable result_;
}

alias CreateFunctionInstruction = immutable(CCreateFunctionInstruction);

