/**
Poet base exception.
*/
module poet.exception;

import std.exception : basicExceptionCtors;

@safe:

class PoetException : Exception
{
    ///
    mixin basicExceptionCtors;
}

