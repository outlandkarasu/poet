/**
Immutable list module.
*/
module poet.list;

@safe:

/**
Immutable list.

Params:
    T = item type.
*/
immutable final class CList(T)
{
    @property @nogc nothrow pure scope
    {
        /**
        Returns:
            list head.
        */
        ref immutable(T) head() return
        {
            return head_;
        }

        /**
        Returns:
            list head.
        */
        immutable(CList!T) tail()
        {
            return tail_;
        }

        /**
        Returns:
            true if this is end item.
        */
        bool end()
        {
            return tail_ is null;
        }
    }

    /**
    append new list item.

    Params:
        item = new item.
    Returns:
        appended list.
    */
    immutable(CList!T) append(T item) nothrow pure
    {
        return new immutable(CList!T)(item, this);
    }

private:

    this(T h, immutable(CList!T) t) @nogc nothrow pure scope
    {
        this.head_ = h;
        this.tail_ = t;
    }

    T head_;
    immutable(CList!T) tail_;
}

/**
create new list.

Params:
    item = first item.
Returns:
    new list.
*/
List!T list(T)(T item) nothrow pure
{
    return new List!T(item, null);
}

///
nothrow pure unittest
{
    immutable l = list(123);
    assert(l.head == 123);
    assert(l.tail is null);
    assert(l.end);

    immutable l2 = l.append(1234);
    assert(l2.head == 1234);
    assert(l2.tail is l);
    assert(!l2.end);
}

/**
Immutable list.

Params:
    T = item type.
*/
alias List(T) = immutable(CList!T);

