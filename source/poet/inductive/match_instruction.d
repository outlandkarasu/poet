/**
Match instruction.
*/
module poet.inductive.match_instruction;

import std.exception : enforce;
import std.typecons : Rebindable;

import poet.context : Context, Variable;
import poet.exception : UnmatchTypeException;
import poet.fun : FunctionValue;
import poet.inductive.value : InductiveValue;
import poet.instruction.instruction : Instruction, IInstruction;
import poet.value : Value;

@safe:

/**
Match instruction.
*/
final immutable class CMatchInstruction : IInstruction
{
    /**
    Constructor.

    Params:
        argument = match argument
        self = self function variable
        caseFunctions = case function variables
    */
    this(Variable argument, Variable self, immutable(Variable)[] caseFunctions) @nogc nothrow pure scope
    {
        this.argument_ = argument;
        this.self_ = self;
        this.caseFunctions_ = caseFunctions;
    }

    override void execute(scope Context context) pure scope
    in (false)
    {
        immutable argument = enforce!UnmatchTypeException(
                cast(InductiveValue) context.get(argument_));
        immutable caseVariable = caseFunctions_[cast(size_t) argument.index];
        immutable caseFunction = enforce!UnmatchTypeException(
                cast(FunctionValue) context.get(caseVariable));
        immutable selfFunction = enforce!UnmatchTypeException(
                cast(FunctionValue) context.get(self_));

        Rebindable!Value r = caseFunction.execute(selfFunction);
        foreach (v; argument.values)
        {
            Value rv = r;
            r = enforce!UnmatchTypeException(cast(FunctionValue) rv).execute(v);
        }

        context.push(r);
    }

private:
    Variable argument_;
    Variable self_;
    immutable(Variable)[] caseFunctions_;
}

alias MatchInstruction = immutable(CMatchInstruction);


