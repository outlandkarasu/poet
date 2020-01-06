/**
No operation Instruction module.
*/
module poet.instruction.noop;

import poet.context : Context;
import poet.instruction.instruction : IInstruction;

@safe:

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

