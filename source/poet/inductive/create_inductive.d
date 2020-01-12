/**
Create inductive instruction.
*/
module poet.inductive.create_inductive;

import std.algorithm : map;
import std.range : array;

import poet.context : Context, Variable;
import poet.inductive.type : InductiveIndex, InductiveType;
import poet.inductive.value : InductiveValue;
import poet.instruction : IInstruction;

@safe:

/**
create inductive instruction.
*/
final immutable class CCreateInductiveInstruction : IInstruction
{
    /**
    Constructor.

    Params:
        type = inductive type.
        index = inductive index.
        variables = inductive contained values.
    */
    this(InductiveType type, InductiveIndex index, immutable(Variable)[] variables) @nogc nothrow pure scope
    in (type !is null)
    in (index < type.constructors.length)
    in (type.constructors[cast(size_t) index].argumentTypes.length == variables.length)
    {
        this.type_ = type;
        this.index_ = index;
        this.variables_ = variables;
    }

    override void execute(scope Context context) pure scope
    in (false)
    {
        immutable values = variables_.map!((v) => context.get(v)).array;
        immutable inductive = InductiveValue.create(type_, index_, values);
        context.push(inductive);
    }

private:
    InductiveType type_;
    InductiveIndex index_;
    immutable(Variable)[] variables_;
}

///
pure unittest
{
    import poet.context : VariableIndex;
    import poet.inductive : InductiveConstructor;
    import poet.example : example;

    immutable et = example();
    immutable t = new InductiveType([[et]]);

    auto c = new Context();
    auto v = et.createValue();
    auto vv = c.push(v);

    immutable cii = new CreateInductiveInstruction(t, InductiveIndex(0), [vv]);
    cii.execute(c);

    immutable inductiveValue = cast(InductiveValue) c.get(c.lastVariable);
    assert(inductiveValue !is null);
    assert(inductiveValue.type.equals(t));
    assert(inductiveValue.index == 0);
    assert(inductiveValue.values.length == 1);
    assert(inductiveValue.values[0] is v);
}

alias CreateInductiveInstruction = immutable(CCreateInductiveInstruction);

