/**
Inductive type module.
*/
module poet.inductive;

import std.algorithm : equal, map, reduce;
import std.array : array;
import std.exception : enforce;
import std.range : enumerate;
import std.typecons : Typedef;

import poet.definition : define, Definition, toExecutionVariable;
import poet.exception : UnmatchTypeException;
import poet.execution : Execution, IInstruction, Instruction;
import poet.fun : FunctionType, funType, isMatchArguments;
import poet.type : IType, Type;
import poet.value : Function, IValue, Value;

@safe:

alias ConstructorID = Typedef!(size_t, size_t.init, "ConstructorID");

/**
Inductive type.
*/
final immutable class CInductiveType : IType
{
    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        return this is other;
    }

    ///
    pure unittest
    {
        immutable self = new InductiveSelfType();
        immutable t = new InductiveType(self, []);
        immutable u = new InductiveType(self, []);
        assert(t.equals(t));
        assert(!t.equals(u));
    }

    /**
    Returns:
        Constructor values and functions.
    */
    @property Value[] constructors() @nogc nothrow pure scope
    {
        return constructors_;
    }

private:

    Value[] constructors_;

    this(scope InductiveSelfType self, scope Type[][] constructors) pure scope
    in (self !is null)
    {
        this.constructors_ = constructors.enumerate.map!((e) {
            auto id = ConstructorID(e.index);
            if (e.value.length == 0)
            {
                return cast(Value) new InductiveValue(this, id, []);
            }

            // replace self to this.
            auto replaced = e.value.map!((t) => (t is self) ? this : t).array;
            immutable ctor = createConstructor(this, id, replaced);
            return cast(Value) ctor;
        }).array;
    }
}

alias InductiveType = immutable(CInductiveType);

/**
Inductive type definition.

Params:
    def = definition delegate. argument is self type.
Returns:
    defined inductive type.
*/
InductiveType defineInductiveType(scope Type[][] delegate(Type) @safe pure nothrow def) pure
in (def !is null)
out (r; r !is null)
{
    immutable self = new InductiveSelfType();
    return new InductiveType(self, def(self));
}

///
pure unittest
{
    immutable peano = defineInductiveType((self) => [
        [],
        [ self ]
    ]);
    assert(peano !is null);
}

/**
Inductive value.
*/
final immutable class CInductiveValue : IValue
{
    @property @nogc nothrow pure scope
    {
        override InductiveType type()
        {
            return type_;
        }

        ConstructorID constructorID()
        {
            return constructorID_;
        }

        Value[] values()
        {
            return values_;
        }
    }

private:

    InductiveType type_;
    ConstructorID constructorID_;
    Value[] values_;

    this(InductiveType type, ConstructorID id, Value[] values) @nogc nothrow pure scope
    in (type !is null)
    {
        this.type_ = type;
        this.constructorID_ = id;
        this.values_ = values;
    }
}

alias InductiveValue = immutable(CInductiveValue);

private:

final immutable class CConstructInductiveValue : IInstruction
{
    void execute(scope Execution e) pure scope
    in (false)
    {
        immutable index = cast(size_t) constructorID_;
        immutable ctor = cast(FunctionType) type_.constructors[index].type;
        enforce!UnmatchTypeException(ctor);

        immutable values = arguments_.map!((a) => e.get(a)).array;
        enforce!UnmatchTypeException(ctor.isMatchArguments(values.map!"a.type".array));

        e.push(new InductiveValue(type_, constructorID_, values));
    }

private:

    this(InductiveType type, ConstructorID id, scope const(Execution.Variable)[] arguments) nothrow pure scope
    in (type !is null)
    {
        this.type_ = type;
        this.constructorID_ = id;
        this.arguments_ = arguments.idup;
    }

    InductiveType type_;
    ConstructorID constructorID_;
    immutable(Execution.Variable)[] arguments_;
}

alias ConstructInductiveValue = immutable(CConstructInductiveValue);

Function createConstructor(InductiveType result, ConstructorID id, scope Type[] arguments) pure
in (result !is null)
in (arguments.length > 0)
out (r; r !is null)
{
    immutable type = (arguments.length > 1)
        ? funType(arguments[0], arguments[1], arguments[2 .. $] ~ result)
        : funType(arguments[0], result);

    return define(type, delegate(scope d, a) {
        auto argumentVariables = arguments[1 .. $].map!((e) => d.begin().toExecutionVariable).array;
        immutable instruction = new ConstructInductiveValue(result, id, argumentVariables);
        return reduce!((r, a) => d.end(r))(d.pushInstruction(result, instruction), arguments[1 .. $]);
    });
}

final immutable class CInductiveSelfType : IType
{
    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        return this is other;
    }
}

alias InductiveSelfType = immutable(CInductiveSelfType);

