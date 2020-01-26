/**
Match instruction.
*/
module poet.inductive.match_instruction;

import std.exception : enforce;
import std.typecons : Rebindable;

import poet.context : Context, next, ScopeID, Variable, VariableIndex;
import poet.exception : UnmatchTypeException;
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
    /**
    Constructor.

    Params:
        context = current context
        selfFunctionType = self function type
        argument = match argument
        caseFunctions = case function variables
    */
    this(
        scope Context context,
        FunctionType selfFunctionType,
        Variable argument,
        immutable(Variable)[] caseFunctions) nothrow pure
    in (selfFunctionType !is null)
    {
        this.argument_ = argument;
        this.caseFunctions_ = caseFunctions;

        immutable nextScopeID = context.scopeID.next;
        this.selfFunction_ = new FunctionValue(
            selfFunctionType,
            [this],
            Variable(nextScopeID, VariableIndex(1)),
            nextScopeID,
            context.save);
    }

    override void execute(scope Context context) pure scope
    in (false)
    {
        immutable argument = enforce!UnmatchTypeException(
                cast(InductiveValue) context.get(argument_));
        immutable caseVariable = caseFunctions_[cast(size_t) argument.index];
        immutable caseFunction = enforce!UnmatchTypeException(
                cast(FunctionValue) context.get(caseVariable));

        Rebindable!Value r = caseFunction.execute(selfFunction_);
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
    FunctionValue selfFunction_;
}

alias MatchInstruction = immutable(CMatchInstruction);

