#!/usr/bin/env python
#
# Author:   Armando Diaz Tolentino <ajdt@cs.washington.edu> 
#
# Desc:     Provides functions to convert a predicate string into a namedtuple()
#           (the simplest parsing I could think to do), and helpers to 
#           extract useful information once a predicate is in this format.
#
from collections import namedtuple
ParsedPredicate = namedtuple('ParsedPredicate', ['name', 'args'])
Time            = namedtuple('Time', ['step', 'stream'])

# @param [string] a predicate string like 'this_is_apred(with, some, args)'
# @return a ParsedPredicate (namedtuple) instance 
def predicateStringToParsedPredicate(string):
    # string has arguments
    if '(' in string:
        name_string, arg_string = splitOnOutermostParens(string)
        return ParsedPredicate(name_string, parsePredicateArguments(arg_string))
    else:
        return ParsedPredicate(string, None)

# split a predicate string into name and argument strings
# example: 'somePred(a,b,c(d,e))' ---> ('somePred', 'a,b,c(d,e)'
# @return tuple splitting on outermost string
def splitOnOutermostParens(string):
    left_index  = string.find('(')
    right_index = string.rfind(')')
    # use str() constructor to avoid unicode strings
    return (str(string[:left_index]), str(string[left_index+1:right_index]))

# split an argument string into separate arguments and
# @return a list() of ParsedPredicate objects
def parsePredicateArguments(arg_string):
    separated_arguments     = []
    unmatched_paren_count   = 0
    current_start_index     = 0

    # iterate through string and isolate the separate arguments
    for index in range(0, len(arg_string)):
        if arg_string[index] == '(':
            unmatched_paren_count += 1
        elif arg_string[index] == ')':
            unmatched_paren_count -= 1
        elif arg_string[index] == ',' and unmatched_paren_count == 0:
            # we've found the stop index of a 
            separated_arguments.append(arg_string[current_start_index:index])
            current_start_index = index+1
        else: 
            continue
    # add last argument in arg_string (all other arguments are preceded by ',' )
    # but loop above misses last one
    separated_arguments.append(arg_string[current_start_index:])

    return [predicateStringToParsedPredicate(arg) for arg in separated_arguments]

# NOTE: can be called with either pred_obj or a string (required for argsToListOfStrings)
def predObjectToString(pred_obj):
    if isinstance(pred_obj, str):
        return pred_obj # accidentally called with a string instance
    elif pred_obj.args == None:
        return str(pred_obj.name)
    else:
        arg_string = ','.join([ predObjectToString(arg) for arg in pred_obj.args])
        return str(pred_obj.name + '(' + arg_string + ')')
# return a Time() named tuple for a predicate
def getTimeFromPredObject(pred_obj):
    if pred_obj.name == 'time':
        step    =   int(pred_obj.args[0].name)
        stream  =   int(pred_obj.args[1].name)
        return Time(step, stream)
    elif pred_obj.args != None:
        time_pred = findInArgList(pred_obj, 'time')
        if time_pred != None:
            return getTimeFromPredObject(time_pred)
    else:
        return None

# find first matching predicate by name within a
# pred_objects arguments
def findInArgList(pred_obj, pred_name):
    if pred_obj.args == None:
        return None
    else:
        matches_name = lambda arg: isinstance(arg, ParsedPredicate) and arg.name == pred_name
        return next( iter([arg for arg in pred_obj.args if matches_name(arg)]), None)
# @param [pred_obj] an instance of ParsedPredicate
# @return a list of strings pertaining to 
def argsToListOfStrings(pred_obj):
    if pred_obj.args == None:
        return []
    else:
        return [predObjectToString(arg) for arg in pred_obj.args]


# return a 3 element list containing [id, field, value] for a parsed holds predicate
def holdsObjectToNodeFieldValue(holds_pred):
    if holds_pred.name != 'holds':
        return None
    # get fact predicate and associated field data
    fact_pred   = findInArgList(holds_pred, 'fact')
    field_data  = findInArgList(fact_pred, 'nodeField')
    # get node and it's assigned field/value pairs
    node        = predObjectToString(findInArgList(fact_pred, 'id'))
    data        = argsToListOfStrings(field_data)
    return [node] + data
