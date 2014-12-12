#!/usr/bin/env python
# This file defines a distance metric between algebraic equations.
# Dependencies:
#	compiler module for parsing eqn strings into abstract syntax trees
#

import compiler
import pdb
# required functions
#distanceBetween
#astOfEqn	# calls compiler module to generate ast and return in a useful way 
#distanceOfASTs # recursive, does actual ast comparison
# sanitize EQnString
DIFF_MONOS_PENALTY = 1
DIFF_NODE_TYPE_PENALTY = 2
def distanceBetweenEqn(fst_eqn, snd_eqn):
	"""compute the 'distance' between two equations"""
	# obtain AST for each eqn
	fst_ast	=	astOfEqn(fst_eqn)
	snd_ast =	astOfEqn(snd_eqn)
	# compare ASTs and return result of comparison
	return distanceOfASTs(fst_ast, snd_ast)

def astOfEqn(eqn_string):
	"""use compiler to return tuple containing AST of given string equation"""
	clean_eqn = sanitizeEqnString(eqn_string)
	# compiler can't parse '=' :(, so we split equation ourselves
	eqn_tree = [ compiler.parse(side) for side in clean_eqn.split('=')]

	# extract root node for each side and place in tuple
	# asList() actually returns a 1-tuple containing root node only
	return tuple([child.node.nodes[0].asList()[0]for child in eqn_tree])

def sanitizeEqnString(equation):
	"""convert Eqn String into a format that's more friendly to astParser"""
	# eqn_viz format uses '^' for exponent operator. compiler module complains about whitespace
	return ''.join(equation.replace('^', '**').split())
def distanceOfASTs(fst_tree, snd_tree):
	"""compare two trees and return the 'difference' between them"""
	return (compareExpressionsRecursive(fst_tree[0], snd_tree[0]) +	
			compareExpressionsRecursive(fst_tree[1], snd_tree[1]))	# compare right sides
current_depth = [1]
def compareExpressionsRecursive(fst_expr, snd_expr, depth=1):
	"""compare two parsed expressions and return their differences"""
	global current_depth
	diff = 0
	if fst_expr is None:
		return computeSubtreeWeight(snd_expr, depth)
	elif snd_expr is None:
		return computeSubtreeWeight(fst_expr, depth)
	elif isMonomial(fst_expr) and isMonomial(snd_expr):
		return compareMonomials(fst_expr, snd_expr)
	elif isMonomial(fst_expr):
		return computeSubtreeWeight(snd_expr, depth)
	elif isMonomial(snd_expr):
		return computeSubtreeWeight(fst_expr, depth)
	# neither node is a monomial
	else:
		if fst_expr.__class__ != snd_expr.__class__:
			diff += DIFF_NODE_TYPE_PENALTY*depth
		compareChildren = lambda f, s : compareExpressionsRecursive(f, s, depth+1)
		diff += sum(map(compareChildren, fst_expr.getChildren(), snd_expr.getChildren()))
	return diff

def computeSubtreeWeight(expr, depth=1):
	root_weight = DIFF_MONOS_PENALTY*depth
	if isMonomial(expr):
		return root_weight
	else:
		return root_weight + sum([ computeSubtreeWeight(child, depth+1) for child in expr.getChildren()])

# TODO: decide if we need to compare degree and coefficient terms too
def compareMonomials(fst_mono, snd_mono):
	# compare degree values
	if str(fst_mono) != str(snd_mono):	# use string comparison b/c __eq__ isn't implemented for AST classes
		return 1
	else:
		return 0
def isConstTerm(expr):
	return isinstance(expr, compiler.ast.Const)

def isExponentiatedVariable(expr):
	"""indicates expr has form x^n"""
	if len(expr.getChildren()) != 2 :
		return False
	
	has_variable		=	isVariableTerm(expr.getChildren()[0])
	has_const_exponent	=	isConstTerm(expr.getChildren()[1])
	return isinstance(expr, compiler.ast.Power) and has_variable and has_const_exponent


def isVariableTerm(expr):
	return isinstance(expr, compiler.ast.Name)

def isMonoInStandardForm(expr):
	if len(expr.getChildren()) != 2 :
		return False
	
	has_coeff		=	isConstTerm(expr.getChildren()[0])
	has_variable	=	isVariableTerm(expr.getChildren()[1]) or isExponentiatedVariable(expr.getChildren()[1])
	return isinstance(expr, compiler.ast.Mul) and has_variable and has_coeff

def isMonomial(expr):
	return isConstTerm(expr) or isVariableTerm(expr) or isExponentiatedVariable(expr) or isMonoInStandardForm(expr)
	

# this code is for testing purposes only
fst = '3*x^5 + 4 = 0'
snd = 'x^2 + 4*x + 6 = 2'
print distanceBetweenEqn(fst, snd)
fst = '3*x^5 + 4 = 0'
snd = '3*x^5 + 3 = 0'
#pdb.set_trace()
print distanceBetweenEqn(fst, snd)
