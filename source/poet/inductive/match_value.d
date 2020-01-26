/**
Match function value module.
*/
module poet.inductive.match_value;

import std.exception : enforce;
import std.typecons : rebindable;

import poet.context : Context, Variable;
import poet.exception : UnmatchTypeException;
import poet.fun : FunctionType, FunctionValue, funType;
import poet.inductive.type : InductiveType;
import poet.inductive.value : InductiveValue;
import poet.type : Type;
import poet.value : IValue, Value;

@safe:

/**
Function value.
*/
final immutable class CMatchValue : IValue
{
    /**
    Constructor.

    Params:
        argumentType = argument inductive type.
        resultType = result type.
        caseFunctions = case functions.
    */
    this(InductiveType argumentType, Type resultType, FunctionValue[] caseFunctions) nothrow pure scope
    in (argumentType !is null)
    in (resultType !is null)
    in (argumentType.constructors.length == caseFunctions.length)
    {
        this.type_ = funType(argumentType, resultType);
        this.caseFunctions_ = caseFunctions;
    }

    override @property FunctionType type() @nogc nothrow pure scope
    {
        return type_;
    }

    /**
    Execute function.

    Params:
        argument = function argument.
    Returns:
        function result.
    */
    Value execute(Value argument) pure scope
    out (r; r !is null && r.type.equals(type_.result))
    {
        enforce!UnmatchTypeException(argument.type.equals(type_.argument));
        immutable inductiveValue = enforce!UnmatchTypeException(
                cast(InductiveValue) argument);

        auto resultValue = caseFunctions_[cast(size_t) inductiveValue.index]
                .execute(this).rebindable;
        foreach (v; inductiveValue.values)
        {
            resultValue = (cast(FunctionValue) (cast(Value) resultValue)).execute(v);
        }

        enforce!UnmatchTypeException(resultValue.type.equals(type_.result));
        return resultValue;
    }

private:
    FunctionType type_;
    FunctionValue[] caseFunctions_;
}

alias MatchValue = immutable(CMatchValue);

