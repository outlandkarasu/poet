/**
Match module.
*/
module poet.inductive.match;

import poet.context : Context, next, ROOT_VALUE, ScopeID, Variable;
import poet.fun :
    DefineFunctionMode,
    FunctionType,
    FunctionValue,
    funType,
    ModeConflictException,
    NotInstructionException;
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
        this.type_ = type;
        this.resultType_ = resultType;
        this.startScopeID_ = context.scopeID;
        this.scopeID_ = context.lastScopeID.next;

        context.pushScope(scopeID_, ROOT_VALUE);
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

private:
    Context context_;
    InductiveType type_;
    Type resultType_;
    ScopeID startScopeID_;
    ScopeID scopeID_;
}

