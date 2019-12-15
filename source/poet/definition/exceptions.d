/**
Definition exceptions module.
*/
module poet.definition.exceptions;

import std.exception : basicExceptionCtors;

import poet.exception : PoetException;

@safe:

/**
definition exception.
*/
class DefinitionException : PoetException
{
    ///
    mixin basicExceptionCtors;
}

/**
Variable out of scope exception.
*/
class OutOfScopeException : DefinitionException
{
    ///
    mixin basicExceptionCtors;
}

/**
Variable index not found exception.
*/
class VariableIndexNotFoundException : DefinitionException
{
    ///
    mixin basicExceptionCtors;
}

/**
Function not started exception.
*/
class FunctionNotStartedException : DefinitionException
{
    ///
    mixin basicExceptionCtors;
}

/**
Unmatch type exception.
*/
class UnmatchTypeException : DefinitionException
{
    ///
    mixin basicExceptionCtors;
}

/**
Not function type exception.
*/
class NotFunctionTypeException : DefinitionException
{
    ///
    mixin basicExceptionCtors;
}

/**
Imcomplete definition exception.
*/
class ImcompleteDefinitionException : DefinitionException
{
    ///
    mixin basicExceptionCtors;
}

