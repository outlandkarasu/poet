/**
Match module.
*/
module poet.inductive.match;

import poet.context : Context;
import poet.inductive.type : InductiveType;

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
    }

private:
    Context context_;
    InductiveType type_;
    Type resultType_;
}

