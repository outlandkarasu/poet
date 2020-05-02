/**
Create product instruction module.
*/
module poet.product.create_product;

import poet.context : Context, Variable;
import poet.instruction : IInstruction;
import poet.product.type : ProductType;
import poet.product.value : ProductValue;

@safe:

/**
create inductive instruction.
*/
final immutable class CCreateProductInstruction : IInstruction
{
    /**
    Constructor.

    Params:
        head = head variable.
        tail = tail variable.
    */
    this(Variable head, Variable tail) @nogc nothrow pure scope
    {
        this.head_ = head;
        this.tail_ = tail;
    }

    override void execute(scope Context context) pure scope
    in (false)
    {
        immutable head = context.get(head_);
        immutable tail = context.get(tail_);
        immutable product = ProductValue.create(head, tail);
        context.push(product);
    }

private:
    Variable head_;
    Variable tail_;
}

///
pure unittest
{
    import poet.example : example;
    import poet.product.type : ProductType;

    immutable h = example();
    immutable t = example();

    auto c = new Context();
    auto hv = h.createValue();
    auto tv = t.createValue();
    auto hvv = c.push(hv);
    auto tvv = c.push(tv);

    immutable cpi = new CreateProductInstruction(hvv, tvv);
    cpi.execute(c);

    immutable productValue = cast(ProductValue) c.get(c.lastVariable);
    assert(productValue !is null);
    assert(productValue.type.equals(new ProductType(h, t)));
    assert(productValue.head is hv);
    assert(productValue.tail is tv);
}

alias CreateProductInstruction = immutable(CCreateProductInstruction);

