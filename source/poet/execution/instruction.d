/**
Instruction module.
*/
module poet.execution.instruction;

import poet.context : ScopeID;
import poet.execution.execution : Execution;
import poet.fun : FunctionType;
import poet.utils : List;
import poet.value.fun_value : Function;

@safe:

/**
Instruction interface.
*/
immutable interface IInstruction
{
    /**
    Execute instruction.

    Params:
        e = execution context.
    */
    void execute(scope Execution e) pure scope
        in (e !is null);
}

alias Instruction = immutable(IInstruction);

/**
Apply function instruction.
*/
final immutable class CApplyFunction : IInstruction
{
    override void execute(scope Execution e) pure scope
    in (false)
    {
        immutable f = cast(Function) e.get(f_);
        immutable a = e.get(a_);
        e.push(f.apply(a));
    }

private:

    this()(scope auto ref const(Execution.Variable) f, scope auto ref const(Execution.Variable) a,)
    {
        this.f_ = f;
        this.a_ = a;
    }

    Execution.Variable f_;
    Execution.Variable a_;
}

alias ApplyFunction = immutable(CApplyFunction);

/**
create function instruction.
*/
final immutable class CCreateFunction : IInstruction
{
    /**
    Params:
        type = function type.
        scopeID = function defined scope ID.
        instructions = function instructions. (nullable)
        result = function result variable.
    */
    this(
        FunctionType type,
        ScopeID scopeID,
        Instruction[] instructions,
        Execution.Variable result) @nogc nothrow pure scope
    in (type !is null)
    {
        this.type_ = type;
        this.scopeID_ = scopeID;
        this.instructions_ = instructions;
        this.result_ = result;
    }

    override void execute(scope Execution e) pure scope
    in (false)
    {
        auto startPoint = e.save();
        e.push(new Function(this, startPoint));
    }

    @property @nogc nothrow pure scope
    {
        FunctionType type()
        out (r; r !is null)
        {
            return type_;
        }

        ScopeID scopeID()
        {
            return scopeID_;
        }

        scope Instruction[] instructions() return
        {
            return instructions_;
        }

        scope ref const(Execution.Variable) result() return
        {
            return result_;
        }
    }

private:
    FunctionType type_;
    ScopeID scopeID_;
    Instruction[] instructions_;
    Execution.Variable result_;
}

///
nothrow pure unittest
{
    import poet.context : VariableIndex;
    import poet.example : example;
    import poet.fun : funType;

    immutable t = example();
    immutable f = funType(t, t);
    immutable scopeID = ScopeID(123);
    immutable result = Execution.Variable(scopeID, VariableIndex.init);
    immutable createFunction = new CreateFunction(f, scopeID, [], result);
    assert(createFunction.type is f);
    assert(createFunction.scopeID == scopeID);
    assert(createFunction.instructions[] == []);
    assert(createFunction.result == result);
}

alias CreateFunction = immutable(CCreateFunction);

