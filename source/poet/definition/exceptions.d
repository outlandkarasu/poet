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

