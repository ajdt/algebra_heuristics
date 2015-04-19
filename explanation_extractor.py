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
from model_manager import ModelManager
from collections import defaultdict

# 
heuristic_to_strategy = {
'thisFractionCanBeSimplifiedToOne': 'cancel',
'weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms': 'combine',
'weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead': 'rearrange',
'soTheNumeratorOfThisFractionMustBeEqualToZero': 'cancel',
'weCanSimplifyByAddingTheseTwoTermsTogether': 'combine',
'weCanSimplifyByCombiningTheseIntoASingleTerm': 'combine',
'weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator': 'cancel',
'weCanSimplifyByFactoringThisExpression': 'expand',
'weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction': 'combine',
'weCanSimplifyByDistributingTheSingleFactor': 'expand',
'weCanSimplifyByCancellingTheDenominatorOfThisFraction': 'cancel',
'weCanSimplifyByCancellingTheZero': 'cancel',
'weCanSimplifyBySubstitutingTheFactorsOfTheTerm': 'expand',
'weCanSimplifyByFactoringOutAFACTORA': 'expand',
'theProductOfTheseTermsIsZero': 'combine',
'weCanSimplifyByCancellingTheOne': 'combine',
'weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM': 'expand',
'weCanSimplifyByCancellingTheseTerms': 'cancel',
'weCanSimplifyBySubtractingTheTermFromBothSides': 'move',
'weCanSimplifyBySubtractingTheVariableTermFromBothSides': 'move',
'weCanSimplifyBySubtractingTheNonZeroTermFromBothSides': 'move',
'weCanSimplifyByMultiplyingBothSidesOfTheEquationByThisDenominator': 'expand',
'weCanDivideBothSidesByTheCoefficientOfTheLeftSide': 'rearrange',
'weCanSimplifyBySubstitutingYForFACTORA': 'expand',
'weCanSimplifyByMultiplyingTheNumeratorByTheTerm': 'combine'
}

# make heuristics also accessible by the strategy the belong to 
strategy_to_heuristic = defaultdict(list)
for heur, strategy in heuristic_to_strategy.items():
    strategy_to_heuristic[strategy].append(heur)
list_of_heuristics = heuristic_to_strategy.keys()

# Singleton explanation manager exposed outside this module
TEMPLATE_MANAGER = None
def getTemplateManager(): # used to manage singleton template_manager
    global TEMPLATE_MANAGER
    if TEMPLATE_MANAGER == None:
        TEMPLATE_MANAGER = parseRules()
    return TEMPLATE_MANAGER

                        ### HELPER FUNCTIONS ###

##
# remove preprocessing directives line beginning with '#' and comments (begin with '%')
# from files that are parsed for explanations
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

##
# @param file_name an ASP file containing rules
# @return a list of parsed rules 
def getRulesListFromFile(file_name):
    temp_file_name  = makeSanitizedFile(file_name)
    rules_list      = par.parseRulesFromFile(temp_file_name)
    os.remove(temp_file_name)
    return rules_list

##
# parse a list of files into rule objects
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

##
# parse rules.lp to obtain explanations for the heuristics used by ASP
def parseRules():
    """ parse rules file and initialize an explanation manager for the parsed rules"""
    return parseFiles(['rules.lp'])

## 
# convert predicate name from camelcase to proper explanation
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

##
# manages a set of explanation objects and handles lookups
# of those objects based on predicate key
class ExplanationManager(object):
    """manages a set of explanations extracted from ASP gringo files"""
    def __init__(self):
        super(ExplanationManager, self).__init__()
        self.templates = {} # (predicate_name, arity) --> ExplanationTemplate instance
        self.heuristic_to_heur_key = {}

    ##
    # instantiate new ExplanationTemplate instance for given predicate 
    def addExplanationTemplate(self, rule):
        rule_key = ExplanationManager.makeRuleKey(rule)
        if self.templates.has_key(rule_key):
            self.templates[rule_key].addAdditionalExplanation(rule)
        else:
            self.templates[rule_key] = ExplanationTemplate(rule, self)
        
        # TODO: ugly fix, required to store heuristic --> heur_key mapping
        if rule_key[0] in list_of_heuristics:
            self.heuristic_to_heur_key[rule_key[0]] = rule_key

    # TODO: I want to handle these lookups more cleanly, rewrite later
    def lookupHeuristicKey(self, heur_string):
        return self.heuristic_to_heur_key[heur_string]

    ##
    # Return an ExplanationTemplate instance for given predicate_key
    # predicate_ key = (predicate_name, arity)
    # NOTE: predicate_key  should be generated using ExplanationManager.makeRuleKey(rule) 
    #           or makePredKey()
    def lookupTemplateFor(self, predicate_key):
        if predicate_key in self.templates.keys():
            return self.templates[predicate_key]
        else:
            return None

    ##
    # return predicate key for given rule
    @staticmethod
    def makeRuleKey(rule):
        return ExplanationManager.makePredKey(rule.head)

    ##
    # heuristics have a key determined by condition and arity of their operands. 
    # Other predicates are indexed by their own predicate name and arity
    @staticmethod
    def makePredKey(predicate):
        if predicate.name != '_applicable':
            return (predicate.name, predicate.arity)

        # heuristic predicate
        nested_pred     = predicate.args[1]     # either a rule() or condition pred
        condition_name  = nested_pred.args[0]
        operands        = nested_pred.args[1]    # contains Operands(...) nested predicate
        # need to count time as an operand too
        heur_key        = (condition_name, operands.arity+1)
        return heur_key

    ##
    # @return true if an explanation object is stored for the given predicate
    def hasExplanationForPredicate(self, predicate):
        predicate_key = ExplanationManager.makePredKey(predicate)
        return predicate_key in self.templates.keys()
        
##
# contains the logic to generate an explanation for one predicate from 
# the rule that derives it
class ExplanationTemplate(object):
    ##
    # @param manager the ExplanationManager storing this object
    def __init__(self, rule, manager):
        super(ExplanationTemplate, self).__init__()
        self.rule       = rule
        self.manager    = manager   # manager called to generate explanations of depth > 1

    def addAdditionalExplanation(self, rule):
        """Some predicates can be derived in more than one way"""
        pass

    ##
    # @param condition a Predicate object
    # @param var_assignment a hashmap (var_name --> var_value)
    # @return true if every variable in the condition is defined in var_assignment
    @staticmethod
    def isUnified(condition, var_assignment):
        variables = ExplanationTemplate.getPredicateVariables(condition)
        # ensure every variable has an assignment
        return all(map(lambda x: x in var_assignment.keys(), variables))

    ##
    # @param var_names a list of variable names
    # @param var_assignment a hashmap (var_name --> var_value) 
    # @return a list where every var_name is replaced with its value or None
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
    
    ##
    # the template for a predicate p1 may use different variable names than
    # when p1 is used as a condition for another rule
    # This method changes the names to the template naming system
    # @return a new dictionary of variable assignments
    @staticmethod
    def translateVarsToTemplateNames(template, var_assignment, old_variables):
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
    ##
    # make explanation for the body of self.rule
    # @param var_assignments hashmap containing values of variables
    # @param depth explanation depth
    # @param model_manager a ModelManager instance containing all predicates true for this step
    # @param factor_data used only if we factored in this step
    # @return a list of explanations for this step
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
    ##
    # @param pred_list a list of predicate objects
    # @param var_assignments a hashmap of variable assignments
    # @param factor_data hashmap containing data (used only if we factored during this step)
    # @return a list of TemplateSentence objects
    def predListToSentences(self, pred_list, var_asignments, factor_data):
        return [ self.makePredicateExplanation(pred, var_asignments, factor_data) for pred in filterUnusedConditions(pred_list)]

    ##
    # @param predicate a predicate object
    # @return the variables used by the predicate
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

    ##
    # @return a TemplateSentence instance for the give predicate using the 
    # given hashmap of var_assignments
    def makePredicateExplanation(self, predicate, var_assignments, factor_data={}):
        sentence    = self.spliceInFactorData(predicate.name, factor_data)
        variables   = ExplanationTemplate.getPredicateVariables(predicate)    
        return TemplateSentence(sentence, variables, var_assignments)
    ##
    # splice Factor predicates into the explanations generated with predicate names
    # NOTE: for some predicates we need auxillary information to form a good explanation
    # this auxillary explanation is provided by factor(..) predicates
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



##
# Encapsulates a single sentence of a template along with var substitution functionality.
# Also decides order of vars w.r.t. explanation
class TemplateSentence(object):
    def __init__(self, sentence, variables, var_assignments = {}):
        super(TemplateSentence, self).__init__()
        self.sentence, self.variables   = sentence, list(variables)
        self.var_values                 = var_assignments

        # remove Time variable; won't be used
        if 'Time' in self.variables:
            self.variables.remove('Time')

    ##
    # @return list containing variables and strings to be joined
    def updateVariables(self, var_assignments={}):
        self.var_values = var_assignments

    ##
    # @return a list of variables and explanation extracted from predicate name
    # that must be joined to obtain a full explanation
    def getSentenceFragments(self):
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
        
        
# TODO: code borrowed form explanation_extractor to avoid mutual dependency of files
def isPredicate(condition):
    return isinstance(condition, par.Predicate)
def isSkippedPredicate(predicate):
    return isPredicate(predicate) and '__' in predicate.name
def isNotPredicate(condition): 
    return not isPredicate(condition)

##
# @return true if variable assignment can be used to make
# a ground instance of cond that is in the mgr
def condIsTrueUnderAssignment(cond, assign_dict, mgr):
    # NOTE: None will be inserted if there is no assignment of a variable
    var_assign = [assign_dict.get(variable) for variable in cond.args]
    pred_key = ExplanationManager.makePredKey(cond)
    for grounding in mgr.getAllGroundInstancesOf(pred_key):
        if mgr.matches(grounding, var_assign):
            return True
    return False

# TODO: combine with existing code
# returns all predicates constituting level two explanation of pred_key
def getLevelTwoPredicates(pred_key):
    template    = getTemplateManager().lookupTemplateFor(pred_key)

    # get template for each body predicate, then extract rules
    body_templates = getBodyTemplateObjects(template)
    body_rules = [b.rule for b in body_templates]
    
    # from the body rules, extract all conditions 
    if len(body_rules) == 1:
        level_two_preds = body_rules[0].body
    else:
        level_two_preds = reduce(lambda x,y: x.body + y.body, body_rules)

    return level_two_preds

##
# @return a list of assignments along with the one predicate that isn't satisfied
def findAlmostMatchesPredicates(pred_key, model_mgr):
    level_two_preds = getLevelTwoPredicates(pred_key) 
    almost_fire     = []
    for excluded, other_cond in makeListOfAlmostFireConditions(level_two_preds):
        for assign in getAllSatisfyingAssignments(other_cond, model_mgr):
            if condIsTrueUnderAssignment(excluded, assign, model_mgr):
                continue
            else:
                almost_fire.append((excluded, assign))
    return almost_fire

##
# for a given predicate key see find all instances of 'almost firing' and
# return any associated explanations in a list
def makeAlmostFireExplanations(pred_key, model_mgr):
    rule_obj    = getTemplateManager().lookupTemplateFor(pred_key).rule
    explanations = []
    for excluded, assign in findAlmostMatchesPredicates(pred_key, model_mgr):
        # rule head looks like : _applicable(T, _rule(HeurName, _operands(..)))
        heur_name       = rule_obj.head.args[1].args[0] 
        operand_vars    = rule_obj.head.args[1].args[1].args
        sent = 'it looks like we can ' 
        sent += heuristic_to_strategy[heur_name] + ' these terms'
        operands = ExplanationTemplate.substituteVariableValues(operand_vars, assign)
        explanations.append([sent, operands])

        snd_sent = "but we cannot because this condition is untrue:" 
        snd_sent += convertFromCamelCase(excluded.name) 
        snd_oper = ExplanationTemplate.substituteVariableValues(excluded.args, assign)
        explanations.append([snd_sent, snd_oper])

    return explanations

##
# return a hashmap of satisfying variable --> value mappings
# for the condition list, based on predicates in model_mgr
def getAllSatisfyingAssignments(conditions, model_mgr):
    all_assignments = []
    findAssign(conditions, model_mgr, {}, all_assignments)
    return all_assignments

##
# find a all assignments that satisfy condition list recursively
def findAssign(cond_list, mgr, assign, all_assign):
    if cond_list == []:
        if assign != {}: # make sure we actually found a satisfying assignment
            all_assign.append(assign)
        return
    for match in getAllCompatibleMatches(cond_list[0], mgr, assign):
        new_assign =    dict(assign)
        match_dict =    dict(zip(cond_list[0].args, match))
        new_assign.update(match_dict)
        findAssign(cond_list[1:], mgr, new_assign, all_assign)

##
# generator function that yields every grounding of a condition 
# that is compatible with existing variable assignments 
def getAllCompatibleMatches(cond, mgr, assign):
    pred_key = ExplanationManager.makePredKey(cond)
    # NOTE: lazy bug fix, some modules expect predicates without '_'; model_manager does
    pred_key = (pred_key[0].replace('_',''), pred_key[1])
    for ground_pred in mgr.getAllGroundInstancesOf(pred_key):
        # convert grounding to variable_name --> value mapping
        ground_dict = dict(zip(cond.args, ground_pred))
        if isCompatibleWith(ground_dict, assign):
            yield ground_pred

##
# @return true if there are no assignment conflicts
# between variables in both dictionaries
def isCompatibleWith(ground_dict, assign_dict):
    for common_key in set(ground_dict.keys()).intersection( set(assign_dict.keys())):
        if ground_dict[common_key] != assign_dict[common_key]:
            return False
    return True


##
# Given a template object 
# @return list of templates for it's body explanations
def getBodyTemplateObjects(template):
    template_obj = []
    #print template.rule.head
    for pred_obj in filterUnusedConditions(template.rule.body):
        if not template.manager.hasExplanationForPredicate(pred_obj):
            continue
        pred_key    = ExplanationManager.makePredKey(pred_obj)
        pred_temp   = template.manager.lookupTemplateFor(pred_key)
        template_obj.append(pred_temp)
    return template_obj

##
# given a list of conditions
# @return a list of tuples, each tuple is an excluded
# condition and the remaining conditions
# TODO: make this a generator function
def makeListOfAlmostFireConditions(list_of_conditions):
    for index in range(0, len(list_of_conditions)):
        excluded_cond = list_of_conditions[index]
        if isNotPredicate(excluded_cond) or isSkippedPredicate(excluded_cond) : 
            continue
        other_cond = list_of_conditions[:index] + list_of_conditions[index+1:]
        yield (excluded_cond, other_cond)


# TODO: test code delete later        
def getTestModelMgr():
    mgr = ModelManager()
    mgr.addPredicate('_areBeingMultiplied(_time(0,1), _id(2,1), _id(2,2))')
    mgr.addPredicate('__isLessThan(_id(2,1), _id(2,2))')
    #mgr.addPredicate('_isSumOfTerms(_time(0,1), _id(2,1))')

    return mgr

def main(files):
    parseFiles(files)
    # TODO: delete this, for testing purposes only
    print makeAlmostFireExplanations(('weCanSimplifyByDistributingTheSingleFactor', 3), getTestModelMgr())
if __name__ == '__main__':
    files_to_parse = ['rules.lp']
    #files_to_parse = ['rules.lp', 'eqn_generator.lp', 'nodes.lp', 'polynomial.lp', 'heuristics.lp']
    #files_to_parse = ['rules.lp', 'nodes.lp']
    main(files_to_parse)

