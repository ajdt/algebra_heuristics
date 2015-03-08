#!/usr/bin/env python
#
# Author:   Armando Diaz Tolentino <ajdt@cs.washington.edu> 
#
# Desc:     A simple visualizer for the equations generated by the ASP program, eqn_generator.lp
#
# NOTE: 
#       requires asp output in json format. As of gringo4 this is possible with
#       clingo --outf=2 <gringo_file.lp>
#       
#       expects output from stdin, pipe clingo output to this program

import argparse
import sys
import json
import re
import sympy as sp
from collections import defaultdict
from collections import namedtuple
import pdb
from pyparsing import Word, alphas, nums, ParseException

import explanation_extractor as explain

# parse all heuristics from list_of_heuristics.txt file 
# NOTE: assumes file exists and is complete: to generate file just run the command "bash make_heur_list.sh"
Heuristic           =   namedtuple('Heuristic', ['name', 'priority', 'trigger'])
heur_file = open('list_of_heuristics.txt', 'r')
HEUR_INFO = {}
for line in heur_file:
    #print line.split(' ')
    heur_name, priority, trigger = [item.strip() for item in line.split(' ') ]
    HEUR_INFO[heur_name] = Heuristic(heur_name, priority, trigger)
heur_file.close()

# template manager
TEMPLATE_MANAGER = None
def getTemplateManager(): # used to manage singleton template_manager
    global TEMPLATE_MANAGER
    if TEMPLATE_MANAGER == None:
        TEMPLATE_MANAGER = explain.parseRules()
    return TEMPLATE_MANAGER

# values is a list of dictionaries, each dictionary contains one solution.
# each dictionary has one key called 'Value' which refers to a list of predicates and their values

# primitive parsers
number_parser   =   Word(nums + '-')
word_parser     =   Word(alphas)

node_parser     =   'id(' + number_parser + ',' + number_parser + ')'
coeff           =   number_parser
deg             =   number_parser
poly_parser     =   number_parser
time_parser     =   'time(' + Word(nums) + ',' + Word(nums) + ')'
action_parser   = 'selectedHeuristic(' +  time_parser + ',' + word_parser + ')'
factora_parser  =   'factor1(' + time_parser + ',' + number_parser + ',' + number_parser + ')'
factorb_parser  =   'factor2(' + time_parser + ',' + number_parser + ',' + number_parser + ')'
#_selectedHeurOperands(_time(0,1),_operands(_id(1,1)))
binary_operand_parser   = 'selectedHeurOperands(' + time_parser + ',' + 'operands(' + node_parser + ',' + node_parser + ')' + ')'
unary_operand_parser    = 'selectedHeurOperands(' + time_parser + ',' + 'operands('  + node_parser + ')' + ')'

def composeParsers(left, middle, right):
    return left + middle + right

wrapNodeFact        =   lambda parser: composeParsers('fact('+ node_parser + ',', parser, ')')
wrapPolyFact        =   lambda parser: composeParsers('fact('+ poly_parser + ',', parser, ')')
wrapKeyValuePair    =   lambda parser: composeParsers('nodeField(', parser, ')')
wrapWithMonomial    =   lambda parser: composeParsers('mono(', parser, ')')
wrapWithHolds       =   lambda fluent: composeParsers('holds(',time_parser, ',' + fluent + ')')

# composite parsers
word_word_parser        = composeParsers(word_parser, ',' , word_parser)
number_number_parser    = composeParsers(number_parser, ',' , number_parser)
word_number_parser      = composeParsers(word_parser, ',' , number_parser)
word_node_parser        = composeParsers(word_parser, ',' , node_parser)


# predicate parsers 
wrapInKeyValueAndFact       =   lambda parser: wrapWithHolds(wrapNodeFact(wrapKeyValuePair(parser)))
type_parser             =   wrapInKeyValueAndFact(word_word_parser)
deg_coeff_parser        =   wrapInKeyValueAndFact(word_number_parser)
child_parser            =   wrapInKeyValueAndFact(word_node_parser)
applicable_heur_parser  = 'applicableHeuristic(' + time_parser + ',' + word_parser + ')'

all_parsers     =   [ type_parser, child_parser, deg_coeff_parser, action_parser, binary_operand_parser, unary_operand_parser, applicable_heur_parser]
factor_parsers  =   [factora_parser, factorb_parser]
op_symbols      =   {'add' : '+' , 'div' : '/' , 'mul' : '*' , 'neg' : '-'}

class GeneratedProblem(object):
    def __init__(self, eqn_params_dict):
        self.equation_parameters = dict(eqn_params_dict)
    def getSolutionString(self, as_latex=False, json_output=False):
        return '\n'.join(self.equation_parameters['equation_steps'])
    def toJSONFormat(self):
        return self.equation_parameters
    def getProblemString(self):
        return self.equation_parameters['equation_steps'][0]

    def getSolutionStringWithExplanations(self):
        steps               = self.equation_parameters['equation_steps']
        step_explanations   = self.equation_parameters['explanations']
        merge               =   lambda x : ' '.join(x)
        # TODO: this code is confusing, rewrite or or change way explanations are
        #   stored in equation_parameters
        # step_explanations: contains one list of sentences per step, 
        # each sentence list is a list of strings
        # NOTE: sentences is actually a list of fragments that must be joined
        # to form a sentence. like ['id(2,1)', 'equals' , 'id(3,3)']
        combined = [ step + '\n' + '\n'.join(map(merge, sentences)) for step, sentences in zip(steps, step_explanations)]

        return '\n'.join(combined)

    def getSelectedHeuristics(self):
        return set(self.equation_parameters['selected_heuristics'])
    def getApplicableHeuristics(self):
        return set(self.equation_parameters['applicable_heur'])

class GeneratedAnswerSet(object):
    def __init__(self, generated_problems):
        self.generated_problems_dict = generated_problems
    def getMathProblems(self):
        return self.generated_problems_dict.values()
    def toJSONFormat(self):
        return dict( [(str(num), prob.toJSONFormat()) for num, prob in self.generated_problems_dict.items() ])
class EquationStepParser:
    """ encapsulates the state of an equation during one step."""
    def __init__(self, model_mgr=None):
        self.model_mgr                      = model_mgr
        # one dictionary per predicate type
        self.node_types                     = {}
        self.degree_of                      = {}
        self.coeff_of                       = {}
        self.node_children                  = defaultdict(list)
        self.numer_of                       = {}
        self.denom_of                       = {}
        self.operands                       = [] 
        self.action                         = None
        self.time                           = None
        self.factor_data                    = {}
    def parseStepInfo(self, tokens):
        """ given a set of tokens return the node, field and value fields in the token array"""
        # peel fact() predicate first
        tokens = tokens[1:-1]
        node = ''.join(tokens[:5])
        fact    = tokens[6:]        # contents are ['nodeInfo(', <field>,  ',' , <value> , ')' ]
        field   = fact[1]
        if field in ['activechild', 'numer', 'denom'] :
            value = ''.join(fact[3:8])      # value is a node
        else:
            value = fact[3]
        return (node, field, value, 'node')

    def addPredicate(self, pred_array):
        node, field, value, pred_type = self.parseStepInfo(pred_array)
        if pred_type == 'node':
            if field == 'type':
                self.node_types[node] = value
            elif field == 'degree':
                self.degree_of[node] = value
            elif field == 'coeff':
                self.coeff_of[node] = value
            elif field == 'numer':
                child = value
                self.numer_of[node] = child
            elif field == 'denom':
                child = value
                self.denom_of[node] = child
            elif field == 'activechild':
                child = value
                self.node_children[node].append(child)
        else:
            poly, deg, coeff = (node, field, value)
            self.monoms_of_polys[poly].append((deg, coeff))

    def add_factor_data(self, factor_data):
        # NOTE: factor data stores deg/coeff info about terms used to factor an equation
        self.factor_data.update(factor_data)
    def getEqnString(self, as_latex=False, json_output=False):
        left    = self.makeEqnString('id(1,1)')
        right   = self.makeEqnString('id(1,2)')
        if as_latex:
            left_latex  = sp.latex( sp.sympify(left, evaluate=False))
            right_latex = sp.latex( sp.sympify(right, evaluate=False))
            string =  '$$' + left_latex + '=' + right_latex + '$$'
        else:
            if left[0] == '(':# NOTE: slicing to avoid outermost parens
                left = left[1:-1]
            if right[0] == '(':
                right = right[1:-1]
            string = left + '=' + right
        return str(string)

    # TODO: simplify getting string for a step
    # getStepString will output both the eqn for a given step as well as operands and heuristic applied
    def getStepString(self, as_latex=False, json_output=False):
        eqn_string = self.getEqnString(as_latex, json_output)
        if json_output:
            return json.dumps({ 'eqn' : eqn_string , 'operands' : self.operands, 'heuristic' : self.action })
        else:
            # get action name and operands
            action_str = ''
            operand_str = ''
            if self.action != None:
                action_str += '\t\theur: ' + self.action 
            # display operands too
            for op in self.operands:
                operand_str = [ 'op: ' + self.makeEqnString(oper) for oper in self.operands ]# TODO: just keep as a list
                operand_str = '\t' + ', '.join(operand_str)

        return eqn_string + action_str + operand_str
        
    def makeEqnString(self, root_node):
        if self.node_types[root_node] == 'mono':
            return  self.makeMonomial(root_node) 
        # root node is a fraction, ensure numer and denom are put together correctly
        if self.node_types[root_node] == 'div':
            numer = self.numer_of[root_node]
            denom = self.denom_of[root_node]
            oper_symbol = op_symbols[self.node_types[root_node]]
            return '(' + self.makeEqnString(numer) + oper_symbol + self.makeEqnString(denom) + ')'
        elif self.node_types[root_node] == 'neg':
            child_str = self.makeEqnString(self.node_children[root_node][0])
            return '-'  + '(' + child_str + ')'
        else: # root_node is an add or mul node
            child_strings = []
            # compose a string representation of every child first
            for child in self.node_children[root_node]:
                child_strings.append( self.makeEqnString(child) )
            oper_symbol = op_symbols[self.node_types[root_node]]
            return '(' + oper_symbol.join(child_strings) + ')'

    def getExplanationSentences(self):
        if self.action is None: # last step has no action string
            return []
        operands        = [self.time] + self.getRawOperands()
        #operands        = [self.time] + self.getOperands()
        condition       = HEUR_INFO[self.action].trigger
        arity           = len(operands)
        template_key    = (condition, arity)

        # get manager and sentence templates
        template_mgr    = getTemplateManager()
        template        = template_mgr.lookupTemplateFor(template_key)
        sentence_temp   = template.makeExplanation(operands, self.model_mgr, 1, self.factor_data)

        # NOTE: we have to translate the node ids used by the explanation sentences
        # Nell's code uses a binary tree representation, my ASP representation 
        # allows for trees with 3 or more children
        explanations    = [ temp.getSentenceFragments() for temp in sentence_temp]
        translate_dict  = self.getBinaryTreeTranslation()
        return [ self.translateSingleExplanation(expl, translate_dict) for expl in explanations]

    def translateSingleExplanation(self, explain_array, translation_dict):
        # NOTE: we translate a single explanation array
        # NOTE: we also use str(..) to convert to utf-8 strings instead of unicode so that we don't
        # get u' prefix on strings during json output
        translated = []
        for fragment in explain_array:
            if fragment in translation_dict.keys():
                translated.append(str(translation_dict[fragment]))
            else:
                translated.append(str(fragment))
        return translated


    @staticmethod
    def makeMonomialFromData(deg, coeff):
        if coeff == '0' or deg == '0':
            return coeff
        elif deg == '1' and coeff == '1':
            return 'x'
        elif coeff == '1':
            return 'x^' + deg
        elif deg == '1':
            return coeff + 'x'
        else:
            return  coeff + 'x^' + deg
    def makeMonomial(self, node_name):
        """ Given a node name, construct the monomial referenced by that node"""
        deg     = self.degree_of[node_name]
        coeff   = self.coeff_of[node_name]
        return EquationStepParser.makeMonomialFromData(deg, coeff)
    def addOperands(self, operands):
        self.operands = operands
    def addTime(self, time):
        # want to store time as a string not tuple
        self.time = 'time' + ''.join(str(time).split())
    def getOperands(self):
        return [ self.makeEqnString(operand) for operand in self.operands ]
    def getRawOperands(self):
        return list(self.operands)
    def getTranslatedRawOperands(self):
        operand_translation = self.getBinaryTreeTranslation()
        return [operand_translation[oper] for oper in self.operands]
    def addActionPred(self, action_name):
        self.action = str(action_name)

    def getTreeStructure(self):
        left = self.getTreeStructureOfNode('id(1,1)')
        right = self.getTreeStructureOfNode('id(1,2)')
        return {'type': '=', 'children':[left, right]}
    def getTreeStructureOfNode(self, node_string):
        if self.node_types[node_string] == 'mono':
            return {'id' : node_string, 'type': 'monomial', 'coeff': self.coeff_of[node_string], 'degree': self.degree_of[node_string]}
        else:
            children = [ self.getTreeStructureOfNode(child) for child in self.node_children[node_string]]
            type_symbol = op_symbols[self.node_types[node_string]]
            return {'id' : node_string, 'type': type_symbol, 'children': children }
    def getAsAlgebraNode(self, node_string):
        if self.node_types[node_string] == 'mono':
            return AlgebraNode(node_string, [])
        else:
            children = [ self.getAsAlgebraNode(child) for child in self.node_children[node_string]]
            return AlgebraNode(node_string, children)
    def getBinaryTreeTranslation(self):
        left = self.getAsAlgebraNode('id(1,1)')
        right = self.getAsAlgebraNode('id(1,2)')
        # convert to binary
        left.convertTopLevelTreeToBinary()
        right.convertTopLevelTreeToBinary()
        # get old and new tags
        translation = left.oldTagsAndNewTags()
        translation.update(right.oldTagsAndNewTags())
        return translation
        

class AlgebraNode(object):
    """encodes an algebra expression tree: used to convert node ids to binary tree format"""
    def __init__(self, node_name, children):
        super(AlgebraNode, self).__init__()
        self.node_name, self.children = node_name, children
    def convertTopLevelTreeToBinary(self):
        self.toBinaryTree()
        if self.node_name == 'id(1,1)':
            self.tagBinaryTree(1, 1)
        else:
            self.tagBinaryTree(1,2) # XXX: assumes this is being called at toplevel!! 
    def toBinaryTree(self):
        # change tree to a binary tree inplace 
        while len(self.children) > 2:
            self.compressBottomTwoChildren()
        for child in self.children:
            child.toBinaryTree()
    def compressBottomTwoChildren(self):
        if len(self.children) <= 2 :
            return
        fst = self.children[0]
        snd = self.children[1]
        self.children = [AlgebraNode(None, [fst, snd])] + self.children[2:]

    def tagBinaryTree(self, current_depth, node_num):
        self.new_id = 'id(' + str(current_depth) + ',' + str(node_num) + ')'
        if self.children == []:
            return
        self.children[0].tagBinaryTree(current_depth+1, node_num*2 -1 )
        if len(self.children) < 2:
            return
        self.children[1].tagBinaryTree(current_depth+1, node_num*2)
    def oldTagsAndNewTags(self):
        tags = {self.node_name : self.new_id}
        for child in self.children:
            tags.update(child.oldTagsAndNewTags())
        return tags
        
        

def peelHolds(tokens):
    """ extract time and fact from tokens"""
    step            = int(tokens[2])
    soln_number     = int(tokens[4])
    time            = (step, soln_number)   # return time as a tuple
    misc_tokens     = tokens[7:-1]
    return time, misc_tokens

class MathProblemParser(object):
    """ 
    parse a single solution to a problem. This is done by adding
    predicates one at a time to the parser, then calling 
    getSolutionString().
    """
    def __init__(self, model_mgr=None):
        self.solution_steps = defaultdict(lambda : EquationStepParser(model_mgr))
        self.actions = []
        self.applicable_actions = set()
    def addPredicate(self, time, pred_array):
        step = time[0]
        self.solution_steps[step].addPredicate(pred_array)
    def getSolutionString(self, as_latex=False, json_output=False):
        all_steps = []
        if json_output:
            all_steps = {}
            for solve_step in sorted(self.solution_steps.keys()):
                all_steps[str(solve_step)] = self.solution_steps[solve_step].getStepString(as_latex, json_output)
                # add applicable and selected heuristics too
                all_steps['applicableHeuristics']   = list(self.getApplicableActions())
                all_steps['selectedHeuristics']     = list(self.getActions())
            return json.dumps(all_steps)
        else:
            for solve_step in sorted(self.solution_steps.keys()):
                all_steps.append( str(solve_step) + ': ' + self.solution_steps[solve_step].getStepString())
            return '\n'.join(all_steps) 
        
    def addActionPred(self, step, action_name):
        self.solution_steps[step].addActionPred(action_name)
        self.actions.append(str(action_name))

    def addFactorPred(self, time_step, factor_data):
        self.solution_steps[time_step].add_factor_data(factor_data)
    def addOperands(self, time, operands):
        step = time[0]
        self.solution_steps[step].addOperands(operands)
    def addTime(self, time):
        step = time[0]
        self.solution_steps[step].addTime(time)
    def getProblem(self):
        return self.solution_steps[0].getStepString()
    def getOperands(self):
        return [step_parser.getOperands() for step_number, step_parser in self.solution_steps.items()]
    def getEqnSteps(self):
        return [step.getEqnString() for step in self.solution_steps.values()]
    def getEqnTrees(self):
        return [step.getTreeStructure() for step in self.solution_steps.values()]
    def getActions(self):
        return list(self.actions)
    def getExplanationsForSteps(self):
        return [step.getExplanationSentences() for step in self.solution_steps.values()]
    def addApplicableAction(self, action_name):
        self.applicable_actions.add(str(action_name))
    def getApplicableActions(self):
        return list(set(self.applicable_actions))
    def jsonFriendlyFormat(self):
        # add necessary equation parameters
        eqn_params = { 'equation_steps': self.getEqnSteps(),
                         #'operands': self.getOperands(),
                         'selected_heuristics': self.getActions(),
                         'applicable_heur': self.getApplicableActions(),
                         #'expression_trees': self.getEqnTrees(),
                         'explanations': self.getExplanationsForSteps()}
        return GeneratedProblem(eqn_params)

class ModelManager(object):
    """records every atom for a generated model (answer set)"""
    # NOTE: I actually use a different ModelManager for each time step within a given model
    def __init__(self):
        super(ModelManager, self).__init__()
        self.model_predicates = defaultdict(list)
    def addPredicate(self, predicate_string):
        """add grounded predicate to model"""
        pred_name, operands = ModelManager.splitPredicate(predicate_string)
        pred_key = (pred_name, len(operands))
        self.model_predicates[pred_key].append(operands)

    def unify(self, pred_key, partial_assign):
        if not self.model_predicates.has_key(pred_key):
            return []
        match_key = self.model_predicates[pred_key]
        return [grounding for grounding in match_key if self.matches(grounding, partial_assign)]

    def matches(self, grounding, partial_assign):
        # checks if partial assignment of variables is consistent with given grounding
        return all(map(lambda x,y: x == y or y == None, grounding, partial_assign))

    # TODO: remove, for testing purposes only
    def printModel(self):
        for pred_key, val_list in self.model_predicates.items():
            print pred_key[0]
            for values in val_list:
                print '\t\t', values

    @staticmethod
    def splitPredicate(pred_string):
        """return predicate name and list of operands from predicate string"""
        # remove all whitespace first
        pred_string = ''.join(pred_string.split())
        open_paren  = pred_string.find('(')
        close_paren = pred_string.rfind(')')

        if open_paren == -1 or close_paren == -1:
            return (pred_string, [])
            
        pred_name       = pred_string[:open_paren]
        operand_str     = pred_string[open_paren+1:close_paren]
        # split operands into an array
        start_idx       = 0
        paren_level     = 0

        operands = []
        for index in range(0, len(operand_str)):
            if operand_str[index] == '(':
                paren_level += 1
            elif operand_str[index] == ')':
                paren_level -= 1
            elif operand_str[index] == ',' and paren_level == 0:
                operands.append(operand_str[start_idx:index])
                start_idx = index + 1
                continue

            # add the last operand
            if index == len(operand_str) - 1 and paren_level == 0: 
                operands.append(operand_str[start_idx:])
                
        return (pred_name, operands)
        
class AnswerSetParser(object):
    def __init__(self, predicates):
        self.math_problems_dict = dict()
        self.parseAnsSetFromPredicates(predicates)
    def parseAnsSetFromPredicates(self, predicates_list):
        """ compose as a string every solution in the predicate list given"""
        model_manager   = ModelManager()
        problem_parsers = defaultdict(lambda : MathProblemParser(model_manager))
        for predicate in predicates_list:
            parser, tokens  = self.findParserMatchingPredicate(predicate)
            model_manager.addPredicate(predicate)
            if parser == binary_operand_parser:
                time, remaining_tokens = peelHolds(tokens)
                soln_num = time[1]
                fst_oper = ''.join(remaining_tokens[1:6])
                snd_oper = ''.join(remaining_tokens[7:-1])
                problem_parsers[soln_num].addOperands(time, [fst_oper, snd_oper])
            elif parser == unary_operand_parser:
                time, remaining_tokens = peelHolds(tokens)
                soln_num = time[1]
                operand = ''.join(remaining_tokens[1:-1])
                problem_parsers[soln_num].addOperands(time, [operand])
            elif parser == applicable_heur_parser:
                # tokens = ['applicableHeuristic(', '_time(', 'step', ',' 'solnNum', ')', ',' , 'actionName' , ')']
                soln_num = int(tokens[4])
                action_name = tokens[-2]
                problem_parsers[soln_num].addApplicableAction(action_name)
            elif parser != None and parser != action_parser:
                # parsing was successful
                time, remaining_tokens = peelHolds(tokens)
                soln_num = time[1]      # time is a tuple (step, soln_number)
                problem_parsers[soln_num].addPredicate(time, remaining_tokens)
            elif parser == action_parser:
                time_step   = int(tokens[2])
                soln_num    = int(tokens[4])
                time        = (time_step, soln_num)
                action_name = tokens[7]
                problem_parsers[soln_num].addActionPred(time_step, action_name)
                # TODO: added time predicate temporarily
                problem_parsers[soln_num].addTime(time)
            elif parser == None:    # look for factor predicates
                parser, tokens = self.parseForFactorPredicates(predicate)
                if parser == factora_parser:
                    time_step   = int(tokens[2])
                    soln_num    = int(tokens[4])
                    time        = (time_step, soln_num)
                    factor_data =   {'FACTORA': EquationStepParser.makeMonomialFromData(tokens[7], tokens[9]) }
                    problem_parsers[soln_num].addFactorPred(time_step, factor_data)
                if parser == factorb_parser:
                    time_step   = int(tokens[2])
                    soln_num    = int(tokens[4])
                    time        = (time_step, soln_num)
                    factor_data =   {'FACTORB': EquationStepParser.makeMonomialFromData(tokens[7], tokens[9]) }
                    problem_parsers[soln_num].addFactorPred(time_step, factor_data)
        # NOTE: important, we don't want to save the parser objects, just the relevant parts of the generated problems
        # So we save GeneratedProblem instances instead
        self.math_problems_dict = dict( [(prob_number, parser.jsonFriendlyFormat() ) for prob_number, parser in problem_parsers.items()])
    def findParserMatchingPredicate(self, predicate, parser_list=all_parsers):
        """ if any parser successfully parses the predicate, return tokens and the parser"""
        for parser in parser_list:
            try:
                parse_output = parser.parseString(predicate)
            except ParseException:
                continue
            return (parser, parse_output)
        return (None, [])
    def parseForFactorPredicates(self, predicate):
        """ if any parser successfully parses the predicate, return tokens and the parser"""
        for parser in factor_parsers:
            try:
                parse_output = parser.parseString(predicate)
            except ParseException:
                continue
            return (parser, parse_output)
        return (None, [])
    def getMathProblems(self):
        return self.math_problems_dict.values()
    def getGeneratedAnsSet(self):
        return GeneratedAnswerSet(self.math_problems_dict)

class AnswerSetManager(json.JSONEncoder):
    """This class parses answer sets from stdin or json file, outputs to file in json format or user-friendly format"""
    def __init__(self, cmdline_args):
        # initialize MathProblemParser for each solution generated
        self.cmdline_args = cmdline_args
        self.answer_sets = []

        json.JSONEncoder.__init__(self)

    def getGeneratedAnsSets(self):
        return list(self.answer_sets)
    def getGeneratedProblems(self):
        """ returns a flat list of all problems contained by answer set manager"""
        probs = []
        for ans_set in self.answer_sets:
            probs += ans_set.getMathProblems()
        return probs

    def initFromSTDIN(self):
        """load answer sets from stdin NOTE: expects JSON input via clingo --outf=2"""
        all_answer_sets = self.__getJSONAnswerSetsFromSTDIN()
        # parse the answer sets
        for answer_set in all_answer_sets:
            predicates = answer_set['Value']
            ans_set= AnswerSetParser(predicates).getGeneratedAnsSet()
            self.answer_sets.append(ans_set)

    def __getJSONAnswerSetsFromSTDIN(self):
        """ read json from stdin, remove underscores, load via json module and return answer sets """
        clingo_output = ''.join(sys.stdin.xreadlines())
        decoded_output = json.loads(clingo_output.replace('_', ''))
        return decoded_output['Call'][0]['Witnesses'] # clingo provides lots of info, we just want answer sets

    def default(self, answer_set):
        """
        :param answer_set: answers set to save
        :return: json encoded answer set (a string)
        """
        return answer_set.toJSONFormat()

    @classmethod
    def __recoverAnswerSetFromJSON(cls, json_string):
        """ create a GeneratedAnswerSet instance from given json string and return it"""
        # decode json_string into dict and create GeneratedProblem for each prob in answer set
        answer_set_dict = dict()
        for prob_num, prob_data in json.JSONDecoder().decode(json_string).items():
            answer_set_dict[prob_num] = GeneratedProblem(prob_data)
        return GeneratedAnswerSet(answer_set_dict)


    def initFromJSONFile(self, file_name):
        json_file = open(file_name, 'r')
        for encoded_answer_set in json_file:
            self.answer_sets.append(AnswerSetManager.__recoverAnswerSetFromJSON(encoded_answer_set))
        json_file.close()

    def getAnsSetsAsJSON(self):
        #return [ self.encode(ans).replace('\n', '')  for ans in self.answer_sets]
        return [ ans.toJSONFormat()  for ans in self.answer_sets]
    def printAnswerSets(self, json_printing=False, with_explanation=False):
        """display all answer sets in user-friendly way"""
        if json_printing:
            # print answer sets as one json object
            all_ans_sets = dict()
            for index, ans_set in enumerate(self.getAnsSetsAsJSON()):
                all_ans_sets[str(index+1)] = ans_set
            print json.dumps(all_ans_sets)
        else:
            for ans_set in self.answer_sets:
                for problem in ans_set.getMathProblems():
                    if with_explanation:
                        print problem.getSolutionStringWithExplanations() + '\n\n'
                    else:
                        print problem.getSolutionString(as_latex=False, json_output=json_printing) + '\n\n'
            print 30*"-"

def main(cmd_line_args):
    """ get cmd line args, initialize manager, set stdout if needed """
    # get cmd line args as dictionary
    cmd_line_args = vars(cmd_line_args)

    # create ans set manager and load with answer sets
    manager = AnswerSetManager(cmd_line_args)
    if cmd_line_args['json_input']:
        manager.initFromJSONFile(cmd_line_args['json_input'])
    else:
        manager.initFromSTDIN()

    # set stdout accordingly
    old_stdout = sys.stdout
    if cmd_line_args['save_file']:
        sys.stdout = open(cmd_line_args['save_file'], 'w')

    # print results. NOTE: prints to file if save_file parameter is used
    json_output = cmd_line_args['json_output'] == 'true'
    manager.printAnswerSets(json_printing=json_output, with_explanation=True)

    # restore stdout
    sys.stdout = old_stdout


def getCmdLineArgs():
    cmd_parser = argparse.ArgumentParser(description='Visualizer for ASP code')
    cmd_parser.add_argument('--json_output', default=False, required=False)
    cmd_parser.add_argument('--save_file', default=False, required=False) # provides file name for saving result
    cmd_parser.add_argument('--json_input', default=False, required=False)
    return cmd_parser.parse_args()

if __name__ == "__main__":
    main(getCmdLineArgs())


