/**
Immutable list module.
*/
module poet.list;

import std.typecons : Rebindable;

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
    Returns:
        list range.
    */
    @property ListRange!T range() @nogc nothrow pure
    {
        return ListRange!T(this);
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

///
nothrow pure unittest
{
    import std.range : isForwardRange;

    auto r = list(1).append(2).append(3).range;
    static assert(isForwardRange!(typeof(r)));

    auto saved = r.save;

    assert(!r.empty && r.front == 3 && r.list && r.list.head == 3);
    r.popFront();
    assert(!r.empty && r.front == 2 && r.list && r.list.head == 2);
    r.popFront();
    assert(!r.empty && r.front == 1 && r.list && r.list.head == 1);
    r.popFront();
    assert(r.empty && r.list is null);

    import std.algorithm : find;
    assert(saved.find!"a == 2".front == 2);
    assert(saved.find!"a == 1".front == 1);
    assert(saved.find!"a == 999".empty);
}


/**
Immutable list.

Params:
    T = item type.
*/
alias List(T) = immutable(CList!T);

/**
List forward range.

Params:
    T = item type.
*/
struct ListRange(T)
{
    @property @nogc nothrow pure const scope
    {
        /**
        Returns:
            current item.
        */
        ref immutable(T) front()
        in (!empty)
        {
            return current_.head;
        }

        /**
        Returns:
            current item.
        */
        bool empty()
        {
            return current_ is null;
        }

        /**
        Returns:
            saved range.
        */
        ListRange!T save()
        {
            return ListRange!T(current_);
        }

        /**
        Returns:
            current list.
        */
        immutable(CList!T) list()
        {
            return current_;
        }
    }

    /**
    Pop current item.
    */
    void popFront() @nogc nothrow pure scope
    in (!empty)
    {
        current_ = current_.tail;
    }

private:
    Rebindable!(immutable(CList!T)) current_;

    this(immutable(CList!T) list) @nogc nothrow pure scope
    {
        this.current_ = list;
    }
}

