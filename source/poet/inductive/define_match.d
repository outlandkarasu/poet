/**
Match module.
*/
module poet.inductive.define_match;

import std.algorithm : map;
import std.exception : basicExceptionCtors, enforce;
import std.range : array;

import poet.context : Context, ContextException, next, ScopeID, Variable;
import poet.exception : UnmatchTypeException;
import poet.fun :
    DefineFunctionMode,
    FunctionType,
    FunctionValue,
    funType,
    InstructionValue,
    ModeConflictException,
    NotInstructionException;
import poet.inductive.match_instruction : MatchInstruction;
import poet.inductive.type : InductiveIndex, InductiveType;
import poet.type : Type;

@safe:

/**
match definition mode.
*/
final class DefineMatchMode
{
    /**
    start definition by context and function type.

    Params:
        context = definition context
        type = function type
        resultType = result type
    */
    this(Context context, InductiveType type, Type resultType) pure scope
    in (context !is null)
    in (type !is null)
    in (resultType !is null)
    {
        this.context_ = context;
        this.mode_ = new DefineFunctionMode(context, funType(type, resultType));
        this.caseMode_ = null;
        this.type_ = type;
        this.argument_ = context.lastVariable;
        this.caseTypes_ = type.constructors
            .map!((c) => funType(type ~ c.argumentTypes ~ resultType)).array;
    }

    ///
    pure unittest
    {
        import poet.context : Variable, VariableIndex;
        import poet.example : example;
        import poet.inductive : InductiveType, SELF_TYPE;

        immutable t = new InductiveType([], [SELF_TYPE]);
        immutable u = example();

        auto c = new Context();
        auto df = new DefineMatchMode(c, t, u);
        assert(c.lastScopeID == ScopeID(1));
        assert(c.scopeID == ScopeID(1));
    }

    /**
    Define constructor case.

    Returns:
        define case function mode.
    */
    DefineFunctionMode defineCase() pure
    out (r; r !is null)
    {
        enforce!CaseNotCompleteException(caseMode_ !is null);
        enforce!CaseAlreadyDefinedException(caseIndex_ >= caseTypes_.length);

        // create case function mode.
        caseMode_ = new DefineFunctionMode(context_, caseTypes_[caseIndex_]);
        ++caseIndex_;
        return caseMode_;
    }

    /**
    End case definition.

    Params:
        result = result variable.
    */
    void endCase()(auto scope ref const(Variable) result)
    {
        enforce!CaseNotStartException(caseMode_ is null);

        caseMode_.endAndPush(result);
        caseMode_ = null;
    }

    /**
    End define match mode and create function value.

    Returns:
        match function value.
    */
    InstructionValue end() pure
    out (r; r !is null)
    {
        // check and gather case variables.
        auto caseVariable = argument_.next;
        immutable(Variable)[] caseVariables;
        foreach (t; caseTypes_)
        {
            enforce!UnmatchTypeException(mode_.getType(caseVariable).equals(t));
            caseVariables ~= caseVariable;
            caseVariable = caseVariable.next;
        }

        immutable match = new MatchInstruction(argument_, caseVariables);
        immutable resultVariable = mode_.pushInstruction(mode_.resultType, match);
        return mode_.end(resultVariable);
    }

private:
    Context context_;
    DefineFunctionMode mode_;
    DefineFunctionMode caseMode_;
    InductiveType type_;
    Variable argument_;
    size_t caseIndex_;
    FunctionType[] caseTypes_;
}

/**
Case already defined.
*/
class CaseAlreadyDefinedException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

/**
Case not complete.
*/
class CaseNotCompleteException : ContextException
{
    ///
    mixin basicExceptionCtors;
}

