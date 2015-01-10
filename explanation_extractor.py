#!/usr/bin/env python

# accept as input what files to parse for predicates to ignore
# read each file, record any new predicates in some reliable storage
# return a set object which contains all the predicates we can ignore

# functions needed
# getIgnoredPredicatesFromFile
# get 
# may be easier in bash?
# TODO: at some point may be wise to replace this code with a full-on context-free grammar parser
#

import re
import tempfile
import os       # for file deletion at the end 
import parse_asp_rules as par

# just testing out regular expression
def makeSanitizedFile(file_name):
    """remove comments, then extract rules. Save to new file"""
    file_obj    = open(file_name, 'r')
    code        = re.sub('%.*\n', '\n', file_obj.read()) # remove comments

    new_file_obj   = tempfile.NamedTemporaryFile(mode='w', delete=False)
    # extract each matching corresponding to a rule
    # TODO: do we still need to sanitize file??
    new_file_obj.write(code)
    #for matching in re.findall(r'[\w]+\(?[^\.:]*:-[^\.]*\.', code):
        #if len(matching.split(':-')) > 2:
            #continue
        #new_file_obj.write(matching)

    file_obj.close()
    new_file_obj.close()
    return new_file_obj.name

def parseRules():
    temp_file_name  = makeSanitizedFile('rules.lp')
    rules_list      = par.parseRulesFromFile(temp_file_name)

    for rule in rules_list:
        #print makeExplanationForRule(rule)
        if isinstance(rule, par.Rule):  # TODO: fix so that only rules are provided in list
            print makeExplanationForRule(rule)

    os.remove(temp_file_name)

def makeExplanationForRule(rule):
    return [ makeConditionExplanation(cond) for cond in rule.body]

# each of these returns a list with text explanations
def makeConditionExplanation(condition, stop_depth=0, depth=0):
    if isinstance(condition, par.Predicate):
        return makePredicateExplanation(condition, stop_depth, depth)
def makePredicateExplanation(predicate, stop_depth=0, depth=0):
    # for now just generate explanation for this predicate ignore depth input
    return convertFromCamelCase(predicate.name)
def makeComparisonExplanation(comparison, stop_depth=0, depth=0):
    pass
def makePredcountExplanation(predcount, stop_depth=0, depth=0):
    pass


## code to convert camelcase to proper explanation
def convertFromCamelCase(name):
    """ Takes a string like 'ILikePuppies' and returns 'i like puppies' """
    # NOTE: this code is not mine!!
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()
    s3 = re.sub('_', ' ', s2)
    return s3


# extract predicate and variables from a given
# I've written this function mostly to verify that everything works
def main():
    name =  makeSanitizedFile('nodes.lp')
    print 'filename', name
    print open(name, 'r').read()
    os.remove(name)
    print 'file now deleted'

if __name__ == '__main__':
    #main()
    parseRules()


# code design for generating explanations
# extractExplanationForRule -- given rule create an explanation template for it: shold also have a depth parameter to suggest how much detail to go into
# extractExplanationForPredicate -- see above, but works only for predicates recursively calls extractExplanationForRule if necessary
# extractExplanationForPredCount
# extractExplanationForComparison
# template class? contains list of all variables, can substitute values in for the variables?
#   stores predicate that it defines, stores explanation code, stores depth level of the explanation
#   how do the variables get matched to equation elements? Decide this later
#   stores elements as a list
#   whatever calls explanation generation code creates this template 
# code to process predicate explanations:
#   convert camel case to underscores, split and then join with spaces
#   include place for variables
# need global container for all rules that have been parse!!


# Code TODOs
    # XX be able to generate explanations first
    # fix mismatched input errors
    # figure out how non-rule namedtuples end up in returned list of parsed objects
    # create template class for each parsed rule
    # merge multiple explanations for same predicate
    # create a manager class to deal with lookups of predicates etc
