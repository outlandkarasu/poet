/**
Function value module.
*/
module poet.fun.value;

import std.exception : enforce;

import poet.context : Context, SavePoint, ScopeID, Variable;
import poet.exception : UnmatchTypeException;
import poet.fun.type : FunctionType;
import poet.instruction : Instruction;
import poet.value : IValue, Value;

@safe:

/**
Function value.
*/
final immutable class CFunctionValue : IValue
{
    /**
    Constructor.

    Params:
        type = function type.
        instructions = function instructions.
        result = function result variable.
        scopeID = function scope ID.
        startPoint = context start point.
    */
    this(
        FunctionType type,
        Instruction[] instructions,
        Variable result,
        ScopeID scopeID,
        SavePoint startPoint) @nogc nothrow pure scope
    in (type !is null)
    {
        this.type_ = type;
        this.instructions_ = instructions;
        this.result_ = result;
        this.scopeID_ = scopeID;
        this.startPoint_ = startPoint;
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
    Value execute(Value argument) pure
    out (r; r !is null && r.type.equals(type_.result))
    {
        enforce!UnmatchTypeException(argument.type.equals(type_.argument));
        scope c = new Context(startPoint_);
        c.pushFunctionScope(scopeID_, this, argument);

        foreach (i; instructions_)
        {
            i.execute(c);
        }

        immutable resultValue = c.get(result_);
        enforce!UnmatchTypeException(resultValue.type.equals(type_.result));
        return resultValue;
    }

private:
    FunctionType type_;
    Instruction[] instructions_;
    Variable result_;
    ScopeID scopeID_;
    SavePoint startPoint_;
}

///
pure unittest
{
    import std.exception : assertThrown;

    import poet.context : VariableIndex;
    import poet.example : example;
    import poet.fun : funType;

    immutable t = example();
    immutable f = funType(t, t);

    auto c = new Context();
    immutable fv = new FunctionValue(f, [], Variable(ScopeID(1), VariableIndex.init), ScopeID(1), c.save);

    immutable tv = t.createValue();
    assert(fv.execute(tv) is tv);

    // unmatch argument type.
    immutable uv = example().createValue();
    assertThrown!UnmatchTypeException(fv.execute(uv));
}

alias FunctionValue = immutable(CFunctionValue);

