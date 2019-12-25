/**
Poet base exception.
*/
module poet.exception;

import std.exception : basicExceptionCtors;

@safe:

/**
Poet base exception.
*/
class PoetException : Exception
{
    ///
    mixin basicExceptionCtors;
}

/**
Unmatch type exception.
*/
class UnmatchTypeException : PoetException
{
    ///
    mixin basicExceptionCtors;
}

