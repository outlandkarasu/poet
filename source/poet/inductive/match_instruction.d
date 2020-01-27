/**
Match instruction.
*/
module poet.inductive.match_instruction;

import std.exception : basicExceptionCtors, enforce;
import std.typecons : Rebindable;

import poet.context : Context, next, ScopeID, Variable, VariableIndex;
import poet.exception : PoetException, UnmatchTypeException;
import poet.fun : FunctionType, FunctionValue;
import poet.inductive.value : InductiveValue;
import poet.instruction.instruction : Instruction, IInstruction;
import poet.value : Value;

@safe:

/**
Match instruction.
*/
final immutable class CMatchInstruction : IInstruction
{
    override void execute(scope Context context) pure scope
    in (false)
    {
        immutable currentFunction = enforce!UnexpectedExecutionException(
                context.currentFunction);
        immutable argument = enforce!UnmatchTypeException(
                cast(InductiveValue) context.get(argument_));
        immutable caseVariable = caseFunctions_[cast(size_t) argument.index];
        immutable caseFunction = enforce!UnmatchTypeException(
                cast(FunctionValue) context.get(caseVariable));

        Rebindable!Value r = caseFunction.execute(currentFunction);
        foreach (v; argument.values)
        {
            Value rv = r;
            r = enforce!UnmatchTypeException(cast(FunctionValue) rv).execute(v);
        }

        context.push(r);
    }

private:
    Variable argument_;
    immutable(Variable)[] caseFunctions_;

    /**
    Constructor.

    Params:
        argument = match argument
        caseFunctions = case function variables
    */
    this(Variable argument, immutable(Variable)[] caseFunctions) nothrow pure
    {
        this.argument_ = argument;
        this.caseFunctions_ = caseFunctions;
    }
}

alias MatchInstruction = immutable(CMatchInstruction);

/**
Unexpected execution exception.
*/
class UnexpectedExecutionException : PoetException
{
    ///
    mixin basicExceptionCtors;
}

