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
    return s3.replace('1', ' 1').replace('0', ' 0') # XXX: quick bandaid fix, I'll do something better later


                        ### EXPLANATION CLASSES ###
def isPredicate(condition):
    return isinstance(condition, par.Predicate)
def isHeuristicPredicate(predicate):
    return isPredicate(predicate) and predicate.name == '_applicable'
def isSkippedPredicate(predicate):
    return isPredicate(predicate) and '__' in predicate.name
def filterUnusedConditions(condition_list):
    # filter out predicates that are explicitly skipped or anything that isn't a predicate
    pred_filter = lambda cond: isPredicate(cond) and not isSkippedPredicate(cond)
    return filter(pred_filter, condition_list)

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

    def lookupTemplateFor(self, predicate_key):
        """Return an ExplanationTemplate instance for given predicate_key
        predicate_ key = (predicate_name, arity)
        NOTE: predicate_key  should be generated using ExplanationManager.makeRuleKey(rule) or makePredKey()
        """
        if predicate_key in self.templates.keys():
            return self.templates[predicate_key]
        else:
            return None

    @staticmethod
    def makeRuleKey(rule):
        """ return predicate key for given rule """
        return ExplanationManager.makePredKey(rule.head)

    @staticmethod
    def makePredKey(predicate):
        """ heuristics have a key determined by condition and arity of their operands. Other predicates
        are indexed by their own predicate name and arity"""
        if predicate.name != '_applicable':
            return (predicate.name, predicate.arity)

        # heuristic predicate
        nested_pred     = predicate.args[1]     # either a rule() or condition pred
        condition_name  = nested_pred.args[0]
        operands        = nested_pred.args[1]    # contains Operands(...) nested predicate
        # need to count time as an operand too
        heur_key        = (condition_name, operands.arity+1)
        return heur_key

    def hasExplanationForPredicate(self, predicate):
        predicate_key = ExplanationManager.makePredKey(predicate)
        return predicate_key in self.templates.keys()
        
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

    @staticmethod
    def isUnified(condition, var_assignment):
        variables = ExplanationTemplate.getPredicateVariables(condition)
        # ensure every variable has an assignment
        return all(map(lambda x: x in var_assignment.keys(), variables))

    @staticmethod
    def substituteVariableValues(var_names, var_assignment):
        # returns a list where variables are substitued for with values where possible
        # where not possible None is used instead
        values = []
        for variable in var_names:
            if var_assignment.has_key(variable):
                values.append(var_assignment[variable])
            else:
                values.append(None)
        return values
    
    @staticmethod
    def translateVarsToTemplateNames(template, var_assignment, old_variables):
        # the template for a predicate p1 may use different variable names than
        # when p1 is used as a condition for another rule
        # This method changes the names to the template naming system
        # @return a new dictionary of variable assignments
        substituted             = ExplanationTemplate.substituteVariableValues(old_variables, var_assignment)
        new_vars_with_values    = zip(ExplanationTemplate.getPredicateVariables(template.rule.head), substituted)
        
        # remove cases where no assignment was found, and create new dictionary
        return dict(filter(lambda tup: tup[1] != None, new_vars_with_values))

    @staticmethod
    def unify(var_assignment, conditions, model_mgr):
        if len(conditions) == 0:
            return var_assignment

        first_cond = conditions[0]
        if ExplanationTemplate.isUnified(first_cond, var_assignment):
            return ExplanationTemplate.unify(var_assignment, conditions[1:], model_mgr)

        # first condition isn't unified
        cond_vars = ExplanationTemplate.getPredicateVariables(first_cond)
        cond_assign = ExplanationTemplate.substituteVariableValues(cond_vars, var_assignment)
        cond_key = ExplanationManager.makePredKey(first_cond)

        # XXX: model_manager removes leading '_' characters, so this is necessary
        cond_key = (cond_key[0].replace('_', ''), cond_key[1])

        # look up possible assignments for not-unified variables and update
        # a copy of var_assignment, recurse on update
        for assignment in model_mgr.unify(cond_key, cond_assign):
            temp_assign = dict(var_assignment)
            temp_assign.update(zip(cond_vars, assignment)) # add new Variable assignments

            # recurse on new assignment, if succeed in assigning for other conditions then return
            new_assign = ExplanationTemplate.unify(temp_assign, conditions[1:], model_mgr)
            if new_assign != None:
                return new_assign
        return None
    def unifyVars(self, var_dictionary, model_manager):
        predicates_only = filterUnusedConditions(self.rule.body)
        #for cond in predicates_only:
            #print cond.name
        return ExplanationTemplate.unify(var_dictionary, predicates_only, model_manager)
    def makeExplanation(self, var_values, model_manager=None, depth=1, factor_data = {}):
        """ return list of template sentences containing explanation"""
        # create mapping from variables used to their values
        var_assignments     = dict(zip(ExplanationTemplate.getPredicateVariables(self.rule.head), var_values))

        # generate head/body explanations
        head_expl           = self.makeHeadExplanation(var_assignments, factor_data)
        body_expl           = self.unifyAndMakeBodyExplanation(var_assignments, model_manager, depth, factor_data)
        return [head_expl] + body_expl

    def makeHeadExplanation(self, var_assignments, factor_data={}):
        if isHeuristicPredicate(self.rule.head):
            # heuristic predicates have explanation component extracted from nested value
            condition_name  = self.rule.head.args[1].args[0]
            sentence        = self.spliceInFactorData(condition_name, factor_data)
            variables       = ExplanationTemplate.getPredicateVariables(self.rule.head)
            return TemplateSentence(sentence, variables, var_assignments)
        else:
            return self.makePredicateExplanation(self.rule.head, var_assignments)
    def unifyAndMakeBodyExplanation(self, var_assignments, model_manager=None, depth=1, factor_data={}):
        # unify variables first, then make explanations
        unified_vars = self.unifyVars(var_assignments, model_manager)
        if unified_vars != None:
            var_assignments = unified_vars
        return self.makeBodyExplanation(var_assignments, model_manager, depth, factor_data)
    def makeBodyExplanation(self, var_assignments, model_manager=None, depth=1, factor_data={}):
        # at desired explanation depth, return body explanations
        if depth <= 1:
            return self.predListToSentences(filterUnusedConditions(self.rule.body), var_assignments, factor_data)
        else:
            # recursive case -- go to greater depth if possible
            explanations = []
            for pred in filterUnusedConditions(self.rule.body):
                if self.manager.hasExplanationForPredicate(pred):
                    pred_definition = self.manager.lookupTemplateFor(ExplanationManager.makePredKey(pred))

                    # have to translate variable names to those used in pred_definition template
                    old_variables       = ExplanationTemplate.getPredicateVariables(pred)
                    translated_assign   = ExplanationTemplate.translateVarsToTemplateNames(pred_definition, var_assignments, old_variables)

                    explanations += pred_definition.unifyAndMakeBodyExplanation(translated_assign, model_manager, depth - 1)
                else:
                    explanations += self.predListToSentences([pred], var_assignments, factor_data)
            return explanations
    def predListToSentences(self, pred_list, var_asignments, factor_data):
        return [ self.makePredicateExplanation(pred, var_asignments, factor_data) for pred in filterUnusedConditions(pred_list)]
    @staticmethod
    def getPredicateVariables(predicate):
        """return a list of variables referenced by given predicate"""
        if isHeuristicPredicate(predicate):
            # heuristic rules have nested variables: 
            # _applicable(Time, _rule(condition, _operands(var1, var2, ... varN)))
            # return time and the nested predicates too
            return [predicate.args[0]] + predicate.args[1].args[1].args
        else:
            return predicate.args
    def makePredicateExplanation(self, predicate, var_assignments, factor_data={}):
        sentence    = self.spliceInFactorData(predicate.name, factor_data)
        variables   = ExplanationTemplate.getPredicateVariables(predicate)    
        return TemplateSentence(sentence, variables, var_assignments)
    def spliceInFactorData(self, raw_predicate_name, factor_data):
        splitA = raw_predicate_name.split('FACTORA')
        if len(splitA) > 1:
            raw_predicate_name = splitA[0] +  ' ' + factor_data['FACTORA'] + ' '   + splitA[1]
        splitB = raw_predicate_name.split('FACTORB')
        if len(splitB) > 1:
            raw_predicate_name = splitB[0] +  ' ' + factor_data['FACTORB'] + ' '   + splitB[1]
        splitX = raw_predicate_name.split('FACTORX')
        if len(splitX) > 1:
            raw_predicate_name = splitX[0] +  ' ' + factor_data['FACTORX'] + ' '   + splitX[1]
        splitY = raw_predicate_name.split('FACTORY')
        if len(splitY) > 1:
            raw_predicate_name = splitY[0] +  ' ' + factor_data['FACTORY'] + ' '   + splitY[1]
        return convertFromCamelCase(raw_predicate_name)



class TemplateSentence(object):
    """encapsulates a single sentence of a template along with var substitution functionality
    Also decides order of vars w.r.t. explanation
    """
    def __init__(self, sentence, variables, var_assignments = {}):
        super(TemplateSentence, self).__init__()
        self.sentence, self.variables   = sentence, list(variables)
        self.var_values                 = var_assignments

        # remove Time variable; won't be used
        if 'Time' in self.variables:
            self.variables.remove('Time')

    def updateVariables(self, var_assignments={}):
        """ returns list containing variables and strings to be joined """
        self.var_values = var_assignments
    def getSentenceFragments(self):
        """ returns a list of variables and explanation extracted from predicate name
            that must be joined to obtain a full explanation
        """
        # substitute values for assigned variables, keep unassigned variables same
        vars_to_inject = []
        for variable in self.variables:
            if self.var_values.has_key(variable):
                vars_to_inject.append(self.var_values[variable])
            else:
                vars_to_inject.append(variable)

        return [self.sentence, vars_to_inject]
    def __str__(self):
        return ' '.join(self.getSentenceFragments())
        
        
# extract predicate and variables from a given
# I've written this function mostly to verify that everything works
def main(files):
    parseFiles(files)
if __name__ == '__main__':
    files_to_parse = ['rules.lp', 'eqn_generator.lp', 'nodes.lp', 'polynomial.lp', 'heuristics.lp']
    #files_to_parse = ['rules.lp', 'nodes.lp']
    main(files_to_parse)


