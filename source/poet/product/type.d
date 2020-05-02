/**
Product type module.
*/
module poet.product.type;

import poet.type : IType, Type;

@safe:

/**
Product type.
*/
final immutable class CProductType : IType
{
    /**
    Params:
        head = head type.
        tail = tail type.
    */
    this(Type head, Type tail) @nogc nothrow pure scope
    in (head !is null)
    in (tail !is null)
    {
        this.head_ = head;
        this.tail_ = tail;
    }

    ///
    nothrow pure unittest
    {
        import poet.example : example;

        immutable t = example();
        immutable u = example();
        immutable p = new ProductType(t, u);
        assert(p.head is t);
        assert(p.tail is u);
    }

    override bool equals(scope Type other) @nogc nothrow pure scope
    {
        if (this is other)
        {
            return true;
        }

        immutable o = cast(ProductType) other;
        if (!o)
        {
            return false;
        }

        return head.equals(o.head) && tail.equals(o.tail);
    }

    ///
    nothrow pure unittest
    {
        import poet.example : example;

        immutable t = example();
        immutable u = example();
        immutable p = new ProductType(t, u);
        assert(p.equals(p));
        assert(p.equals(new ProductType(t, u)));
        assert(!p.equals(new ProductType(t, t)));
        assert(!p.equals(new ProductType(u, u)));
        assert(!p.equals(new ProductType(u, t)));
    }

    @property const @nogc nothrow pure scope
    {
        Type head() return
        out (r; r !is null)
        {
            return head_;
        }

        Type tail() return
        out (r; r !is null)
        {
            return tail_;
        }
    }

private:
    Type head_;
    Type tail_;
}

alias ProductType = immutable(CProductType);

