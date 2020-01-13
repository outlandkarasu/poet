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
Variable[] pushInductiveConstructor(Context context, InductiveType type)
in (context !is null)
in (type !is null)
out (r; r.length == type.constructors.length)
{
    return type.constructors
        .enumerate
        .map!((e) => pushInductiveConstructor(context, type, InductiveIndex(e.index)))
        .array;
}

private:

Variable pushInductiveConstructor(Context context, InductiveType type, InductiveIndex index)
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

