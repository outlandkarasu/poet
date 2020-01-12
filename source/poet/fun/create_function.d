/**
Create function instruction module.
*/
module poet.fun.create_function;

import poet.context : Context, ScopeID, Variable;
import poet.fun.type : FunctionType;
import poet.fun.value : FunctionValue;
import poet.instruction.instruction : Instruction, IInstruction;

@safe:

/**
create function instruction.
*/
final immutable class CCreateFunctionInstruction : IInstruction
{
    /**
    Constructor.

    Params:
        type = function type.
        instructions = function instructions.
        result = function result variable.
        scopeID = function scope ID.
    */
    this(
        FunctionType type,
        Instruction[] instructions,
        Variable result,
        ScopeID scopeID) @nogc nothrow pure scope
    in (type !is null)
    {
        this.type_ = type;
        this.instructions_ = instructions;
        this.result_ = result;
        this.scopeID_ = scopeID;
    }

    override void execute(scope Context context) pure scope
    in (false)
    {
        immutable value = new FunctionValue(type_, instructions_, result_, scopeID_, context.save);
        context.push(value);
    }

private:
    FunctionType type_;
    Instruction[] instructions_;
    Variable result_;
    ScopeID scopeID_;
}

///
pure unittest
{
    import poet.context : VariableIndex;
    import poet.example : example;
    import poet.fun : funType;

    immutable t = example();
    immutable f = funType(t, t);

    auto c = new Context();
    immutable cfi = new CreateFunctionInstruction(f, [], Variable(ScopeID(1), VariableIndex.init), ScopeID(1));
    cfi.execute(c);

    immutable fv = cast(FunctionValue) c.get(Variable(c.scopeID, VariableIndex(1)));
    assert(fv !is null);
    assert(fv.type.equals(f));

    immutable tv = t.createValue();
    assert(fv.execute(tv) is tv);
}

alias CreateFunctionInstruction = immutable(CCreateFunctionInstruction);

