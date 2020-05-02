/**
Product value module.
*/
module poet.product.value;

import poet.product.type : ProductType;
import poet.value: IValue, Value;

@safe:

final immutable class CProductValue : IValue
{
    @property @nogc nothrow pure scope
    {
        override ProductType type()
        {
            return type_;
        }

        Value head() return
        out (r; r !is null)
        {
            return head_;
        }

        Value tail() return
        out (r; r !is null)
        {
            return tail_;
        }
    }

    /**
    Create a product value.

    Params:
        head = head value.
        tail = tail value.
    Returns:
        product value.
    */
    static ProductValue create(Value head, Value tail) nothrow pure
    in (head !is null)
    in (tail !is null)
    out (r; r.type.head is head.type)
    out (r; r.type.tail is tail.type)
    out (r; r.head is head)
    out (r; r.tail is tail)
    {
        immutable t = new ProductType(head.type, tail.type);
        return new ProductValue(t, head, tail);
    }

    ///
    nothrow pure unittest
    {
        import poet.example : example;

        immutable h = example().createValue();
        immutable t = example().createValue();
        immutable p = ProductValue.create(h, t);
        assert(p.type.head.equals(h.type));
        assert(p.type.tail.equals(t.type));
        assert(p.head is h);
        assert(p.tail is t);
    }

private:

    this(ProductType type, Value head, Value tail) @nogc nothrow pure scope
    in (type !is null)
    in (head !is null)
    in (tail !is null)
    in (type.head.equals(head.type))
    in (type.tail.equals(tail.type))
    {
        this.type_ = type;
        this.head_ = head;
        this.tail_ = tail;
    }

    ProductType type_;
    Value head_;
    Value tail_;
}

alias ProductValue = immutable(CProductValue);

