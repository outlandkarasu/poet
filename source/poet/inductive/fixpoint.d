/**
Fixpoint module.
*/
module poet.inductive.fixpoint;

import poet.context : Context;

@safe:

/**
Fixpoint definition mode.
*/
final class DefineFixpointMode
{
    /**
    start definition by context and function type.

    Params:
        context = definition context
        type = function type
    */
    this(Context context, InductiveType type) pure scope
    in (context !is null)
    in (type !is null)
    {
        this.context_ = context;
        this.type_ = type;
    }

private:
    Context context_;
    InductiveType type_;
}
