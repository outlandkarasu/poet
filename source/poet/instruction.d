/**
Instruction module.
*/
module poet.instruction;

import poet.context : Context;

@safe:

/**
Instruction module.
*/
immutable interface IInstruction
{
    /**
    Execute instruction.

    Params:
        context = target context.
    */
    void execute(scope Context context) pure scope
    in (context !is null);
}

alias Instruction = immutable(IInstruction);

