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
import pdb
from pyparsing import Word, alphas, nums, ParseException


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

class GeneratedAnswerSet(object):
    def __init__(self, generated_problems):
        self.generated_problems_dict = generated_problems
    def getMathProblems(self):
        return self.generated_problems_dict.values()
    def toJSONFormat(self):
        return dict( [(num, prob.toJSONFormat()) for num, prob in self.generated_problems_dict.items() ])
class EquationStepParser:
    """ encapsulates the state of an equation during one step."""
    def __init__(self):
        # one dictionary per predicate type
        self.node_types                     = {}
        self.degree_of                      = {}
        self.coeff_of                       = {}
        self.node_children                  = defaultdict(list)
        self.numer_of                       = {}
        self.denom_of                       = {}
        self.operands                       = [] 
        self.action                         = None
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
        return string

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

    def makeMonomial(self, node_name):
        """ Given a node name, construct the monomial referenced by that node"""
        deg     = self.degree_of[node_name]
        coeff   = self.coeff_of[node_name]
        if coeff == '0' or deg == '0':
            return coeff
        elif deg == '1' and coeff == '1':
            return 'x'
        elif coeff == '1':
            return 'x^' + deg
        elif deg == '1':
            return coeff + '*x'
        else:
            return  coeff + '*x^' + deg
    def addOperands(self, operands):
        self.operands = operands
    def getOperands(self):
        return list(self.operands)
    def addActionPred(self, action_name):
        self.action = action_name


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
    def __init__(self):
        self.solution_steps = defaultdict(EquationStepParser)
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
        self.actions.append(action_name)
    def addOperands(self, time, operands):
        step = time[0]
        self.solution_steps[step].addOperands(operands)
    def getProblem(self):
        return self.solution_steps[0].getStepString()
    def getOperands(self):
        return [(step_number, step_parser.getOperands()) for step_number, step_parser in self.solution_steps.items()]
    def getEqnSteps(self):
        return [step.getEqnString() for step in self.solution_steps.values()]
    def getActions(self):
        return list(self.actions)
    def addApplicableAction(self, action_name):
        self.applicable_actions.add(action_name)
    def getApplicableActions(self):
        return list(set(self.applicable_actions))
    def jsonFriendlyFormat(self):
        # add necessary equation parameters
        eqn_params = { 'equation_steps': self.getEqnSteps(),
                         'operands': self.getOperands(),
                         'selected_heuristics': self.getActions(),
                         'applicable_heur': self.getApplicableActions()}
        return GeneratedProblem(eqn_params)

class AnswerSetParser(object):
    def __init__(self, predicates):
        self.math_problems_dict = dict()
        self.parseAnsSetFromPredicates(predicates)
    def parseAnsSetFromPredicates(self, predicates_list):
        """ compose as a string every solution in the predicate list given"""
        problem_parsers = defaultdict(MathProblemParser)
        for predicate in predicates_list:
            parser, tokens  = self.findParserMatchingPredicate(predicate)
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
                time        = int(tokens[2])
                soln_num    = int(tokens[4])
                action_name = tokens[7]
                problem_parsers[soln_num].addActionPred(time, action_name)
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
        return [ self.encode(ans).replace('\n', '')  for ans in self.answer_sets]
    def printAnswerSets(self, json_printing=False):
        """display all answer sets in user-friendly way"""
        if json_printing:
            for ans_set in self.getAnsSetsAsJSON():
                print ans_set
        else:
            for ans_set in self.answer_sets:
                for problem in ans_set.getMathProblems():
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
    manager.printAnswerSets(json_printing=json_output)

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


