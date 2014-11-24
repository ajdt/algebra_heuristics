#!/usr/bin/env python
#
# Author:	Armando Diaz Tolentino <ajdt@cs.washington.edu> 
#
# Desc:		A simple visualizer for the equations generated by the ASP program, eqn_generator.lp
#
# NOTE: 
#		requires asp output in json format. As of gringo4 this is possible with
#		clingo --outf=2 <gringo_file.lp>
#		
#		expects output from stdin, pipe clingo output to this program

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
number_parser	=	Word(nums + '-')
word_parser		=	Word(alphas)

node_parser		=	'id(' + number_parser + ',' + number_parser + ')'
coeff			=	number_parser
deg				=	number_parser
poly_parser     =	number_parser
time_parser		=	'time(' + Word(nums) + ',' + Word(nums) + ')'
action_parser 	= 'selectedHeuristic(' +  time_parser + ',' + word_parser + ')'
#_selectedHeurOperands(_time(0,1),_operands(_id(1,1)))
binary_operand_parser	= 'selectedHeurOperands(' + time_parser + ',' + 'operands(' + node_parser + ',' + node_parser + ')' + ')'
unary_operand_parser	= 'selectedHeurOperands(' + time_parser + ',' + 'operands('  + node_parser + ')' + ')'

def composeParsers(left, middle, right):
	return left + middle + right

wrapNodeFact		=	lambda parser: composeParsers('fact('+ node_parser + ',', parser, ')')
wrapPolyFact		=	lambda parser: composeParsers('fact('+ poly_parser + ',', parser, ')')
wrapKeyValuePair	=	lambda parser: composeParsers('nodeField(', parser, ')')
wrapWithMonomial	=	lambda parser: composeParsers('mono(', parser, ')')
wrapWithHolds		=	lambda fluent: composeParsers('holds(',time_parser, ',' + fluent + ')')

# composite parsers
word_word_parser		= composeParsers(word_parser, ',' , word_parser)
number_number_parser	= composeParsers(number_parser, ',' , number_parser)
word_number_parser		= composeParsers(word_parser, ',' , number_parser)
word_node_parser		= composeParsers(word_parser, ',' , node_parser)


# predicate parsers 
wrapInKeyValueAndFact		=	lambda parser: wrapWithHolds(wrapNodeFact(wrapKeyValuePair(parser)))
type_parser				=	wrapInKeyValueAndFact(word_word_parser)
deg_coeff_parser		=	wrapInKeyValueAndFact(word_number_parser)
child_parser 			= 	wrapInKeyValueAndFact(word_node_parser)

all_parsers 	=	[ type_parser, child_parser, deg_coeff_parser, action_parser, binary_operand_parser, unary_operand_parser]
op_symbols 		= 	{'add' : '+' , 'div' : '/' , 'mul' : '*' , 'neg' : '-'}


class StepParser:
	""" encapsulates the state of an equation during one step."""
	def __init__(self):
		# one dictionary per predicate type
		self.node_types						= {}
		self.degree_of			    		= {}
		self.coeff_of			    		= {}
		self.node_children					= defaultdict(list)
		self.numer_of						= {}
		self.denom_of						= {}
		self.operands						= [] 
		self.action 						= None
	def parseStepInfo(self, tokens):
		""" given a set of tokens return the node, field and value fields in the token array"""
		# peel fact() predicate first
		tokens = tokens[1:-1]
		node = ''.join(tokens[:5])
		fact	= tokens[6:]		# contents are ['nodeInfo(', <field>,  ',' , <value> , ')' ]
		field	= fact[1]
		if field in ['activechild', 'numer', 'denom'] :
			value = ''.join(fact[3:8]) 		# value is a node
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

	def getStepString(self, as_latex=False, json_output=False):
		left	= self.makeEqnString('id(1,1)')
		right	= self.makeEqnString('id(1,2)')
		if as_latex:
			string =  '$$' + sp.latex( sp.sympify(left, evaluate=False)) + '=' + sp.latex( sp.sympify(right, evaluate=False)) + '$$'
		else:
			if left[0] == '(':# NOTE: slicing to avoid outermost parens
				left = left[1:-1]
			if right[0] == '(':
				right = right[1:-1]
			string = left + '=' + right 

		if json_output:
			return json.dumps({ 'eqn' : string , 'operands' : self.operands, 'heuristic' : self.action })
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

		return string + action_str + operand_str
		
	def makeEqnString(self, root_node):
		if self.node_types[root_node] == 'mono':
			return  self.makeMonomial(root_node) 
		# root node is a fraction, ensure numer and denom are put together correctly
		if self.node_types[root_node] == 'div':
			numer = self.numer_of[root_node]
			denom = self.denom_of[root_node]
			oper_symbol	= op_symbols[self.node_types[root_node]]
			return '(' + self.makeEqnString(numer) + oper_symbol + self.makeEqnString(denom) + ')'
		elif self.node_types[root_node] == 'neg':
			child_str = self.makeEqnString(self.node_children[root_node][0])
			return '-'  + '(' + child_str + ')'
		else: # root_node is an add or mul node
			child_strings = []
			# compose a string representation of every child first
			for child in self.node_children[root_node]:
				child_strings.append( self.makeEqnString(child) )
			oper_symbol	= op_symbols[self.node_types[root_node]]
			return '(' + oper_symbol.join(child_strings) + ')'

	def makeMonomial(self, node_name):
		""" Given a node name, construct the monomial referenced by that node"""
		deg		= self.degree_of[node_name]
		coeff	= self.coeff_of[node_name]
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
	def addOperands(self, operands):
		self.operands = operands
	def addActionPred(self, action_name):
		self.action = action_name

		
def peelHolds(tokens):
	""" extract time and fact from tokens"""
	step			= int(tokens[2])
	soln_number		= int(tokens[4])
	time 			= (step, soln_number)	# return time as a tuple
	misc_tokens 	= tokens[7:-1]
	return time, misc_tokens

class SolnParser(object):
	""" 
	parse a single solution to a problem. This is done by adding
	predicates one at a time to the parser, then calling 
	getSolutionString().
	"""
	def __init__(self):
		self.solution_steps = defaultdict(StepParser)
		self.actions = []
	def addPredicate(self, time, pred_array):
		step = time[0]
		self.solution_steps[step].addPredicate(pred_array)
	def getSolutionString(self, as_latex=False, json_output=False):
		all_steps = []
		if json_output:
			all_steps = {}
			for solve_step in sorted(self.solution_steps.keys()):
				all_steps[str(solve_step)] = self.solution_steps[solve_step].getStepString(as_latex, json_output)
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
	def getActions(self):
		return list(self.actions)
def findParserMatchingPredicate(predicate, parser_list=all_parsers):
	""" if any parser successfully parses the predicate, return tokens and the parser"""
	for parser in parser_list:
		try:
			parse_output = parser.parseString(predicate)
		except ParseException:
			continue
		return (parser, parse_output)
	return (None, [])

def parseSolutions(predicates_list, soln_parser=SolnParser):
	""" compose as a string every solution in the predicate list given"""
	all_solutions = defaultdict(soln_parser)
	for predicate in predicates_list:
		parser, tokens	= findParserMatchingPredicate(predicate)
		if parser == binary_operand_parser:
			time, remaining_tokens = peelHolds(tokens)
			soln_num = time[1]
			fst_oper = ''.join(remaining_tokens[1:6])
			snd_oper = ''.join(remaining_tokens[7:-1])
			all_solutions[soln_num].addOperands(time, [fst_oper, snd_oper])
		elif parser == unary_operand_parser:
			time, remaining_tokens = peelHolds(tokens)
			soln_num = time[1]
			operand = ''.join(remaining_tokens[1:-1])
			all_solutions[soln_num].addOperands(time, [operand])
		elif parser != None and parser != action_parser:
			# parsing was successful
			time, remaining_tokens = peelHolds(tokens)
			soln_num = time[1]		# time is a tuple (step, soln_number)
			all_solutions[soln_num].addPredicate(time, remaining_tokens)
		elif parser == action_parser:
			time		= int(tokens[2])
			soln_num	= int(tokens[4])
			action_name	= tokens[7]
			all_solutions[soln_num].addActionPred(time, action_name)
	return all_solutions

def parseSolutionsAndGetStrings(predicates_list, json_output=False):
	all_solutions = parseSolutions(predicates_list)
	return [soln.getSolutionString(as_latex=False, json_output=json_output) for soln in all_solutions.values() ]

def printProbsAndSolutions(all_prob, json_output=False):
	""" parse each generated problem, and display all solutions found for each problem"""
	for problem in all_prob:
		print '\n\n'.join(parseSolutionsAndGetStrings(problem['Value'], json_output))
		if not json_output:
			print 30*"-"
def getAllSolnFromJSON(json_output):
	sanitized_json = json_output.replace('_', '')
	decoded = json.loads(sanitized_json)
	all_soln = decoded['Call'][0]['Witnesses']
	return all_soln

def main(cmd_line_args):
	""" read solutions in json format from stdin"""
	clasp_output = ''.join(sys.stdin.xreadlines())
	all_soln = getAllSolnFromJSON(clasp_output)
	if vars(cmd_line_args)['json_output'] == 'true':
		printProbsAndSolutions(all_soln, json_output=True)
	else:
		printProbsAndSolutions(all_soln)

def getCmdLineArgs():
	cmd_parser = argparse.ArgumentParser(description='Visualizer for ASP code')
	cmd_parser.add_argument('--json_output', default=False, required=False)
	return cmd_parser.parse_args()

if __name__ == "__main__":
	main( getCmdLineArgs() )
