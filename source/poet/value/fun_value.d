/**
Function value module.
*/
module poet.value.fun_value;

import std.exception : enforce;

import poet.context : ScopeID;
import poet.exception : UnmatchTypeException;
import poet.execution : CreateFunction, Execution, Instruction;
import poet.fun : FunctionType;
import poet.utils : List;
import poet.value.value : Value;

@safe:

immutable class CFunction : Value
{
    /**
    Params:
        createFunction = base create function instruction.
        startPoint = function start point.
    */
    this()(CreateFunction createFunction, auto ref const(Execution.SavePoint) startPoint) immutable @nogc nothrow pure scope
    in (createFunction !is null)
    {
        this.createFunction_ = createFunction;
        this.startPoint_ = startPoint;
    }

    override @property FunctionType type() @nogc nothrow pure scope
    {
        return createFunction_.type;
    }

    /**
    Apply function.

    Params:
        argument = function argument.
    Returns:
        apply result.
    */
    Value apply(Value argument) pure scope
    in (argument !is null)
    out (r; r !is null)
    {
        enforce!UnmatchTypeException(type.argument.equals(argument.type));

        // start a new scope.
        scope execution = new Execution(startPoint_);
        execution.pushScope(createFunction_.scopeID, type.result, argument);

        // execute instructions.
        foreach (i; createFunction_.instructions)
        {
            i.execute(execution);
        }

        // close a scope and get result.
        immutable resultVariable = execution.popScope(createFunction_.result);
        return execution.get(resultVariable);
    }

private:
    CreateFunction createFunction_;
    Execution.SavePoint startPoint_;
}

///
nothrow pure unittest
{
    import poet.example : example;
    import poet.execution : CreateFunction;
    import poet.fun : funType;

    immutable t = example();
    immutable u = example();

    auto execution = new Execution(t, t.createValue());
    immutable ftype = funType(t, u);
    immutable cf = new CreateFunction(ftype, ScopeID(123), [], Execution.Variable.init);
    auto s = execution.save();
    immutable f = new Function(cf, s);
    assert(f.type is ftype);
}

alias Function = immutable(CFunction);

