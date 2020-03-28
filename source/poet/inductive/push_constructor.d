/**
Inductive push constructor module.
*/
module poet.inductive.push_constructor;

import std.algorithm : map;
import std.range : array, enumerate;
import std.typecons : rebindable;

import poet.context : Context, Variable;
import poet.fun : DefineFunctionMode, funType, FunctionType;
import poet.inductive.type : InductiveIndex, InductiveType;
import poet.inductive.value : InductiveValue;
import poet.inductive.create_inductive : CreateInductiveInstruction;
import poet.value : Value;

@safe:

/**
Push inductive constructors to context.

Params:
    context = current context.
    type = inductive type.
Returns:
    constructor variables.
*/
immutable(Variable)[] pushInductiveConstructor(Context context, InductiveType type) pure
in (context !is null)
in (type !is null)
out (r; r.length == type.constructors.length)
{
    return type.constructors
        .enumerate
        .map!((e) => pushInductiveConstructor(context, type, InductiveIndex(e.index)))
        .array.idup;
}

///
pure unittest
{
    import poet.context : VariableIndex;
    import poet.fun : FunctionValue;
    import poet.inductive.type : InductiveConstructor, SELF_TYPE;
    import poet.example : example;

    immutable et = example();
    immutable t = new InductiveType([], [et], [SELF_TYPE]);

    auto c = new Context();
    auto constructors = c.pushInductiveConstructor(t);
    assert(constructors.length == 3);

    // inductive base value.
    immutable base = cast(InductiveValue) c.get(constructors[0]);
    assert(base !is null);
    assert(base.type.equals(t));
    assert(base.values.length == 0);

    // inductive constructor.
    immutable constructor = cast(FunctionValue) c.get(constructors[1]);
    assert(constructor !is null);
    assert(constructor.type.argument.equals(et));
    assert(constructor.type.result.equals(t));

    immutable etv = et.createValue();
    immutable result = cast(InductiveValue) constructor.execute(etv);
    assert(result !is null);
    assert(result.type.equals(t));
    assert(result.values.length == 1);
    assert(result.values[0] is etv);

    // recursive constructor.
    immutable rec = cast(FunctionValue) c.get(constructors[2]);
    assert(rec !is null);
    assert(rec.type.argument.equals(t));
    assert(rec.type.result.equals(t));

    immutable recResult = cast(InductiveValue) rec.execute(base);
    assert(recResult !is null);
    assert(recResult.type.equals(t));
    assert(recResult.values.length == 1);
    assert(recResult.values[0] is base);
}

private:

Variable pushInductiveConstructor(Context context, InductiveType type, InductiveIndex index) pure
in (context !is null)
in (type !is null)
in (index < type.constructors.length)
{
    immutable argumentTypes = type.constructors[cast(size_t) index].argumentTypes;
    if (argumentTypes.length == 0)
    {
        // base pattern. retuern value.
        return context.push(InductiveValue.create(type, index, []));
    }

    // constructor function pattern.
    // gather parameters.
    immutable(Variable)[] constructorParameters;
    scope DefineFunctionMode[] modes;
    for (auto f = rebindable(funType(argumentTypes ~ type));
        f !is null;
        f = cast(FunctionType) f.result)
    {
        modes ~= new DefineFunctionMode(context, f);
        constructorParameters ~= context.lastVariable;
    }

    // new and push instruction.
    immutable instruction = new CreateInductiveInstruction(type, index, constructorParameters);
    auto result = modes[$ - 1].pushInstruction(type, instruction);

    // return inductive results.
    foreach_reverse (m; modes[1 .. $])
    {
        result = m.endAndPush(result);
    }

    return modes[0].endAndCreate(result);
}

///
pure unittest
{
    import poet.context : VariableIndex;
    import poet.fun : FunctionValue;
    import poet.inductive : InductiveConstructor;
    import poet.example : example;

    immutable et = example();
    immutable t = new InductiveType([], [et]);

    auto c = new Context();

    // create inductive base value.
    auto constructor0Variable = c.pushInductiveConstructor(t, InductiveIndex(0));
    immutable constructor0 = cast(InductiveValue) c.get(constructor0Variable);
    assert(constructor0 !is null);
    assert(constructor0.values.length == 0);
    assert(constructor0.type.equals(t));

    // create inductive constructor function.
    auto constructor1Variable = c.pushInductiveConstructor(t, InductiveIndex(1));
    immutable constructor1 = cast(FunctionValue) c.get(constructor1Variable);
    assert(constructor1 !is null);
    assert(constructor1.type.result.equals(t));

    // create inductive value by constructor function.
    immutable etv = et.createValue();
    immutable result = cast(InductiveValue) constructor1.execute(etv);
    assert(result !is null);
    assert(result.type.equals(t));
    assert(result.values.length == 1);
    assert(result.values[0] is etv);
}

