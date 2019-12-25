/**
Function definition module.
*/
module poet.definition.definition;

import std.exception : enforce;

import poet.context : Context;
import poet.exception : UnmatchTypeException;
import poet.fun : FunctionType;
import poet.type : Type;

import poet.definition.exceptions :
    ImcompleteDefinitionException,
    NotFunctionTypeException;

@safe:

/**
Function definition.
*/
final class Definition
{
    /**
    Variable type.
    */
    alias Variable = Ctx.Variable;

    /**
    Begin function definition.

    Params:
        f = target function variable.
    */
    Variable begin() pure scope
    out (r; getType(r))
    {
        immutable functionType = cast(FunctionType) context_.scopeValue.result;
        enforce!NotFunctionTypeException(functionType);

        return context_.pushScope(functionType, functionType.argument);
    }

    /**
    Apply function.

    Params:
        f = function variable.
        a = function argument variable.
    Returns:
        function result variable.
    */
    Variable apply()(auto scope ref const(Variable) f, auto scope ref const(Variable) a) pure scope
    out (r; getType(r).equals((cast(FunctionType) getType(f)).result))
    {
        immutable functionType = cast(FunctionType) getType(f);
        enforce!NotFunctionTypeException(functionType);

        immutable argumentType = getType(a);
        enforce!UnmatchTypeException(functionType.argument.equals(argumentType));

        return context_.push(functionType.result);
    }

    /**
    End function definition.

    Params:
        result = result variable.
    Returns:
        defined function type.
    */
    Variable end()(auto scope ref const(Variable) result) pure scope
    out (r; getType(r))
    {
        immutable resultType = getType(result);
        immutable targetType = context_.scopeValue;
        enforce!UnmatchTypeException(resultType.equals(targetType.result));

        context_.popScope();
        return context_.push(targetType);
    }

private:
    alias Ctx = Context!(FunctionType, Type);

    Ctx context_;

    this(FunctionType target) nothrow pure scope
    in (target !is null)
    out (r; context_ !is null)
    {
        this.context_ = new Ctx(target, target.argument);
    }

    Type getType()(auto scope ref const(Variable) v) pure scope
    out (r; r !is null)
    {
        return context_.getValue(v);
    }
}

/**
define function.

Params:
    target = target function type.
    def = define delegate.
*/
void define(
        FunctionType target,
        scope Definition.Variable delegate(scope Definition, const(Definition.Variable)) @safe pure def) pure
in (target !is null)
in (def !is null)
{
    scope d = new Definition(target);
    auto result = def(d, Definition.Variable.init);
    enforce!UnmatchTypeException(d.getType(result).equals(target.result));
    enforce!ImcompleteDefinitionException(d.context_.rootScope);
}

///
pure unittest
{
    import poet.example : example;
    import poet.fun : funType;

    auto t = example();
    auto u = example();
    auto v = example();
    auto f = funType(funType(t, u), funType(u, v), funType(t, v));

    // (t -> u) -> (u -> v) -> (t -> v)
    define(f, (scope d, a) {
        assert(d.getType(a).equals(funType(t, u)));

        // (u -> v) -> (t -> v)
        auto argumentUtoV = d.begin();
        assert(d.getType(argumentUtoV).equals(funType(u, v)));

        // t -> v
        auto argumentT = d.begin();
        assert(d.getType(argumentT).equals(t));

        auto resultU = d.apply(a, argumentT);
        assert(d.getType(resultU).equals(u));

        auto resultV = d.apply(argumentUtoV, resultU);
        assert(d.getType(resultV).equals(v));

        auto resultTtoV = d.end(resultV);
        assert(d.getType(resultTtoV).equals(funType(t, v)));

        auto resultUtoV_TtoV = d.end(resultTtoV);
        assert(d.getType(resultUtoV_TtoV).equals(funType(funType(u, v), funType(t, v))));

        return resultUtoV_TtoV;
    });
}

///
pure unittest
{
    import poet.context : OutOfScopeException;
    import poet.example : example;
    import poet.fun : funType;

    auto t = example();
    auto u = example();
    auto v = example();
    auto f = funType(funType(t, u), funType(u, v), funType(t, v));

    import std.exception : assertThrown;

    assertThrown!NotFunctionTypeException(
        define(f, (scope d, a) {
            d.begin(); // (u -> v) -> (t -> v)
            d.begin(); // t -> v
            return d.begin(); // error
        }));

    assertThrown!UnmatchTypeException(
        define(f, (scope d, a) {
            auto argumentUtoV = d.begin();
            auto argumentT = d.begin();
            auto resultU = d.apply(a, argumentT);
            auto resultV = d.apply(argumentUtoV, resultU);
            auto resultTtoV = d.end(resultU); // error
            auto resultUtoV_TtoV = d.end(resultTtoV);
            return resultUtoV_TtoV;
        }));

    assertThrown!OutOfScopeException(
        define(f, (scope d, a) {
            auto argumentUtoV = d.begin();
            auto argumentT = d.begin();
            auto resultU = d.apply(a, argumentT);
            auto resultV = d.apply(argumentUtoV, resultU);
            auto resultTtoV = d.end(resultV);
            auto resultUtoV_TtoV = d.end(resultV); // error
            return resultUtoV_TtoV;
        }));
}

