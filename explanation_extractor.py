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
    """ parse rules file and initialize an explanation manager for the parsed rules"""
    temp_file_name  = makeSanitizedFile('rules.lp')
    rules_list      = par.parseRulesFromFile(temp_file_name)

    template_mgr    = ExplanationManager()
    for rule in rules_list:
        #print makeExplanationForRule(rule)
        template_mgr.addExplanationTemplate(rule)
    # TODO: for testing purposes only; remove later
    for template in template_mgr.templates.values():
        if template.rule.head.name == '_applicable':
            print template.rule.head.name
            nested_pred = template.rule.head.args[1]
            print nested_pred.name, nested_pred.args, nested_pred.args[1].__class__.__name__
        #print template.makeExplanation({})

    os.remove(temp_file_name)
    return template_mgr



## code to convert camelcase to proper explanation
def convertFromCamelCase(name):
    """ Takes a string like 'ILikePuppies' and returns 'i like puppies' """
    # NOTE: this code is not mine!!
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()
    s3 = re.sub('_', ' ', s2)
    return s3


class ExplanationManager(object):
    """manages a set of explanations extracted from ASP gringo files"""
    def __init__(self):
        super(ExplanationManager, self).__init__()
        self.templates = {} # (predicate_name, arity) --> ExplanationTemplate instance

    def addExplanationTemplate(self, rule):
        """instantiate new ExplanationTemplate instance for given predicate """
        rule_key = ExplanationManager.makeRuleKey(rule)
        if self.templates.has_key(rule_key):
            self.templates[rule_key].addAdditionalExplanation(rule)
        else:
            self.templates[rule_key] = ExplanationTemplate(rule, self)

    def lookupTemplateFor(self, predicate_name, arity, explanation_depth=1):
        """generate an explanation for the given predicate_name and arity.
        explanation_depth controls how detailed the generated explanation is
        """
        pass

    @staticmethod
    def makeRuleKey(rule):
        """ heuristics have a key determined by condition and arity of their operands. Other predicates
        are indexed by their own predicate name and arity"""
        if rule.head.name != '_applicable':
            return (rule.head.name, rule.head.arity)

        nested_pred     = rule.head.args[1]     # either a rule() or condition pred
        condition_name  = nested_pred.args[0]
        operands        = nested_pred.args[1]    # contains Operands(...) nested predicate
        heur_key        = (condition_name, operands.arity)
        print heur_key
        return heur_key
        
class ExplanationTemplate(object):
    """stores the explanation logic for a single predicate type. A predicate type
    is defined by both predicate name and arity."""
    def __init__(self, rule, manager):
        super(ExplanationTemplate, self).__init__()
        self.rule       = rule
        self.manager    = manager   # manager called to generate explanations of depth > 1

    def addAdditionalExplanation(self, rule):
        """Some predicates can be derived in more than one way"""
        pass

    def makeExplanation(self, var_assignments, depth=1):
        """ var_assignments is a list of variable values to substitute in the explanation"""
        return (self.rule.head.name, [ self.makeConditionExplanation(cond) for cond in self.rule.body] )

    # each of these returns a list with text explanations
    def makeConditionExplanation(self, condition, stop_depth=0, depth=0):
        if isinstance(condition, par.Predicate):
            return self.makePredicateExplanation(condition, stop_depth, depth)

    def makePredicateExplanation(self, predicate, stop_depth=0, depth=0):
        # for now just generate explanation for this predicate ignore depth input
        sentence    = convertFromCamelCase(predicate.name)
        variables   = predicate.args
        return TemplateSentence(sentence, variables)

    def makeComparisonExplanation(self, comparison, stop_depth=0, depth=0):
        pass
    def makePredcountExplanation(self, predcount, stop_depth=0, depth=0):
        pass


class TemplateSentence(object):
    """encapsulates a single sentence of a template along with var substitution functionality
    Also decides order of vars w.r.t. explanation
    """
    def __init__(self, sentence, variables):
        super(TemplateSentence, self).__init__()
        self.sentence, variables = sentence, variables
    def fillTemplate(self, variable_values):
        """replace variables with given values and return the filled in sentence as string"""
        pass
    def __str__(self):
        # TODO: should work whether template is filled or unfilled
        return self.sentence
        
        
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
    # XX fix mismatched input errors
    # XX figure out how non-rule namedtuples end up in returned list of parsed objects
    # create template class for each parsed rule
    # merge multiple explanations for same predicate
    # create a manager class to deal with lookups of predicates etc
