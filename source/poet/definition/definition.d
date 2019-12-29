/**
Function definition module.
*/
module poet.definition.definition;

import std.exception : enforce;
import std.typecons : Rebindable;

import poet.context : Context;
import poet.exception : UnmatchTypeException;
import poet.execution :
    ApplyFunction,
    CreateFunction,
    Execution,
    Instruction;
import poet.fun : FunctionType;
import poet.type : Type;
import poet.utils : List;
import poet.value : Function;

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

        return context_.pushScope(functionType, StackElement(functionType.argument));
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

        immutable applyInstruction = new ApplyFunction(
                toExecutionVariable(f), toExecutionVariable(a));
        return pushInstruction(functionType.result, applyInstruction);
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
        immutable targetType = context_.scopeValue;
        immutable currentFunction = createCurrentFunction(result);
        context_.popScope();
        return pushInstruction(targetType, currentFunction);
    }

    /**
    Push an instruction.

    Params:
        result = instruction result type.
        instruction = push instruction.
    Returns:
        instruction result variable.
    */
    Variable pushInstruction(Type result, Instruction instruction) nothrow pure scope
    in (result !is null)
    in (instruction !is null)
    {
        return context_.push(StackElement(result, instruction));
    }

private:

    struct StackElement
    {
        Type type;
        Instruction instruction;
    }

    alias Ctx = Context!(FunctionType, StackElement);

    Ctx context_;

    this(FunctionType target) nothrow pure scope
    in (target !is null)
    out (r; context_ !is null)
    {
        this.context_ = new Ctx(target, StackElement(target.argument));
    }

    Type getType()(auto scope ref const(Variable) v) pure scope
    out (r; r !is null)
    {
        return context_.getValue(v).type;
    }

    static Execution.Variable toExecutionVariable()(
            auto scope ref const(Variable) v) @nogc nothrow pure
    {
        return Execution.Variable(v.scopeID, v.index);
    }

    CreateFunction createCurrentFunction()(auto scope ref const(Variable) result) pure scope
    out (r; r !is null)
    {
        immutable resultType = getType(result);
        immutable targetType = context_.scopeValue;
        enforce!UnmatchTypeException(resultType.equals(targetType.result));

        Instruction[] instructions;
        foreach (e; context_)
        {
            if (e.instruction)
            {
                instructions ~= e.instruction;
            }
        }

        return new CreateFunction(
                targetType,
                context_.scopeID,
                instructions,
                toExecutionVariable(result));
    }
}

/**
define function.

Params:
    target = target function type.
    def = define delegate.
Returns:
    defined function.
*/
Function define(
        FunctionType target,
        scope Definition.Variable delegate(scope Definition, Definition.Variable) @safe pure def) pure
in (target !is null)
in (def !is null)
out (r; r !is null)
{
    scope d = new Definition(target);
    auto result = def(d, Definition.Variable.init);
    enforce!ImcompleteDefinitionException(d.context_.rootScope);

    immutable createFunction = d.createCurrentFunction(result);
    auto e = Execution.createEmpty();
    createFunction.execute(e);
    return cast(Function) e.get(e.lastVariable);
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
    immutable functionValue = define(f, (scope d, a) {
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

    assert(functionValue.type.equals(f));
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

