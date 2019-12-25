/**
Instruction module.
*/
module poet.execution.instruction;

import poet.execution.execution : Execution;

@safe:

/**
Instruction interface.
*/
immutable interface IInstruction
{
    /**
    Execute instruction.

    Params:
        e = execution context.
    */
    void execute(scope Execution e) pure scope
        in (e !is null);
}

alias Instruction = immutable(IInstruction);

