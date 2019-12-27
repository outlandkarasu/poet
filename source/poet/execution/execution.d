/**
Execution module.
*/
module poet.execution.execution;

import std.exception : enforce;

import poet.context : Context, ScopeID;
import poet.exception : UnmatchTypeException;
import poet.fun : FunctionType;
import poet.type : Type;
import poet.value : Value;

@safe:

/**
Execution context.
*/
final class Execution 
{
    /**
    Execution variable type.
    */
    alias Variable = Ctx.Variable;

    /**
    push value.

    Params:
        value = pushing value.
    Returns:
        pushed value variable.
    */
    Variable push(Value value) nothrow pure scope
    in (value !is null)
    {
        return context_.push(value);
    }

    /**
    get variable value.

    Params:
        v = variable.
    Returns:
        variable value.
    */
    Value get()(auto scope ref const(Variable) v) pure scope
    out (r; r !is null)
    {
        return context_.getValue(v);
    }

    /**
    push new scope.

    Params:
        id = scope ID.
        resultType = result type.
        argument = function argument value.
    Returns:
        argument variable.
    */
    Variable pushScope()(ScopeID id, Type resultType, auto scope ref const(Variable) argument) pure scope
    in (resultType !is null)
    {
        return context_.pushScope(id, resultType, get(argument));
    }

    /**
    pop current scope.

    Params:
        result = result value.
    Returns:
        result variable.
    */
    Variable popScope()(scope auto ref const(Variable) result) pure scope
    {
        immutable resultValue = get(result);
        immutable resultType = resultValue.type;
        enforce!UnmatchTypeException(resultType.equals(context_.scopeValue));

        context_.popScope();
        return context_.push(resultValue);
    }

private:
    alias Ctx = Context!(Type, Value);

    Ctx context_;

    this(Type resultType, Value argument) nothrow pure scope
    in (resultType !is null)
    in (argument !is null)
    out (r; context_ !is null)
    {
        this.context_ = new Ctx(resultType, argument);
    }
}

///
pure unittest
{
    import std.exception : assertThrown;
    import poet.example : example;
    import poet.context :
        ScopeNotStartedException,
        OutOfScopeException;

    auto t = example();
    auto v1 = t.createValue();

    // create new execution.
    auto execution = new Execution(t, v1);
    auto vv1 = Execution.Variable.init;
    assert(execution.get(vv1) is v1);

    // push value.
    auto u = example();
    auto v2 = u.createValue();
    auto av2 = execution.push(v2);
    assert(execution.get(av2) is v2);

    // push new scope.
    auto vv2 = execution.pushScope(ScopeID(1), t, av2);
    assert(execution.get(vv1) is v1);
    assert(execution.get(vv2) is v2);
    assertThrown!UnmatchTypeException(execution.popScope(vv2));

    // pop scope.
    auto v3 = execution.popScope(vv1);
    assert(execution.get(vv1) is v1);
    assert(execution.get(v3) is v1);
    assertThrown!OutOfScopeException(execution.get(vv2));

    // cannot pop root scope.
    assertThrown!ScopeNotStartedException(execution.popScope(vv1));
}

