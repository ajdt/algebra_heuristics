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

                        ### HELPER FUNCTIONS ###
def makeSanitizedFile(file_name):
    """remove comments. Save to new file"""
    file_obj    = open(file_name, 'r')
    code        = re.sub('%.*\n', '\n', file_obj.read()) # remove comments
    code        = re.sub('#.*\n', '\n', code) # remove comments

    # create new file and write new code to file, return temp file name
    # NOTE: new_file_name should be deleted by caller
    new_file_obj   = tempfile.NamedTemporaryFile(mode='w', delete=False)
    new_file_obj.write(code)
    file_obj.close()
    new_file_obj.close()
    return new_file_obj.name

def getRulesListFromFile(file_name):
    temp_file_name  = makeSanitizedFile(file_name)
    rules_list      = par.parseRulesFromFile(temp_file_name)
    os.remove(temp_file_name)
    return rules_list

def parseFiles(file_list):
    rules_list = []
    for rule_file in file_list:
        rules_list += getRulesListFromFile(rule_file)

    # populate manager from rules_list
    template_mgr    = ExplanationManager()
    for rule in rules_list:
        #print makeExplanationForRule(rule)
        template_mgr.addExplanationTemplate(rule)
    #for template in template_mgr.templates.values():
        ##if template.rule.head.name == '_applicable':
            ##nested_pred = template.rule.head.args[1]
            ##print '## ', nested_pred.args[0]
            ###print nested_pred.name, nested_pred.args, nested_pred.args[1].__class__.__name__
            ##for sentence in  template.makeExplanation({})[1]:
                ##print str(sentence)
        #for sentence in template.makeExplanation({})[1]:
            #print str(sentence)
    return template_mgr

def parseRules():
    """ parse rules file and initialize an explanation manager for the parsed rules"""
    return parseFiles(['rules.lp'])

## convert predicate name from camelcase to proper explanation
def convertFromCamelCase(name):
    """ Takes a string like 'ILikePuppies' and returns 'i like puppies' """
    # NOTE: this code is not mine!!
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()
    s3 = re.sub('_', ' ', s2)
    return s3


                        ### EXPLANATION CLASSES ###
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

    def lookupTemplateFor(self, predicate_key, var_assignment=[], explanation_depth=1):
        """generate an explanation for the given predicate_name and arity.
        explanation_depth controls how detailed the generated explanation is
        NOTE: predicate_key  should be generated using ExplanationManager.makeRuleKey(rule)
        """
        template_obj = self.templates[predicate_key]

        # applicable predicates have nested variables as in...
        # _applicable(Time, _rule(condition, _operands(<nested_vars>)))

        if template_obj.rule.head.name == '_applicable':
            var_names = template_obj.rule.head.args[1].args[1].args
        else:
            var_names = template_obj.rule.head.args

        assignment_dict     = dict(zip(var_names, var_assignment))
        # makeExplanation() returns (predicat_name, sentence_objects)
        sentence_objects    = template_obj.makeExplanation(assignment_dict)[1]

        return [sentence.injectVariables(assignment_dict) for sentence in sentence_objects if sentence != None]

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
        self.sentence, self.variables = sentence, variables

    def injectVariables(self, var_assignments={}):
        var_names = list(self.variables)

        # remove Time variable; won't be used
        if 'Time' in var_names:
            var_names.remove('Time')

        # substitute values for assigned variables, keep unassigned variables same
        vars_to_inject = []
        for variable in var_names:
            if var_assignments.has_key(variable):
                vars_to_inject.append(var_assignments[variable])
            else:
                vars_to_inject.append(variable)

        # predicate name contains 'of', then assume desired string is 'Var1 <predicate description> Var2'
        if 'of' in self.sentence.split():
            return ' '.join([vars_to_inject[0], self.sentence,vars_to_inject[1]])

        # 'of' isn't in predicate name, so generate var string in format 'Var1, Var2, ... and VarN'
        if len(vars_to_inject) < 2:
            vars_str = ', '.join(vars_to_inject)
        else:
            vars_str = ', '.join(vars_to_inject[:-1]) + ' and ' + vars_to_inject[-1]

        # prepend vars to the sentence
        return vars_str + ' ' + self.sentence

    def __str__(self):
        # TODO: should work whether template is filled or unfilled
        return self.injectVariables()
        
        
# extract predicate and variables from a given
# I've written this function mostly to verify that everything works
def main(files):
    parseFiles(files)
if __name__ == '__main__':
    #files_to_parse = ['rules.lp', 'eqn_generator.lp', 'nodes.lp', 'polynomial.lp', 'heuristics.lp']
    files_to_parse = ['rules.lp', 'nodes.lp']
    main(files_to_parse)


