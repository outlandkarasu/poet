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

/**
No operation instruction.
*/
final immutable class CNoopInstruction : IInstruction
{
    ///
    override void execute(scope Context context) pure scope
    in (false)
    {
        // do nothing.
    }

    static @property immutable(CNoopInstruction) instance() @nogc nothrow pure
    out (r; r !is null)
    {
        return instance_;
    }

private:
    static immutable(CNoopInstruction) instance_ = new immutable CNoopInstruction();

    this() @nogc nothrow pure scope
    {
    }
}

alias NoopInstruction = immutable(CNoopInstruction);

