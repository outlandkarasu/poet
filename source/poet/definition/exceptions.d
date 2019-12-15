/**
Definition exceptions module.
*/
module poet.definition.exceptions;

import std.exception : basicExceptionCtors;

import poet.exception : PoetException;

@safe:
/**
Variable out of scope exception.
*/
class OutOfScopeException : PoetException
{
    ///
    mixin basicExceptionCtors;
}

/**
Variable index not found exception.
*/
class VariableIndexNotFoundException : PoetException
{
    ///
    mixin basicExceptionCtors;
}

/**
Function not started exception.
*/
class FunctionNotStartedException : PoetException
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

/**
Not function type exception.
*/
class NotFunctionTypeException : PoetException
{
    ///
    mixin basicExceptionCtors;
}

