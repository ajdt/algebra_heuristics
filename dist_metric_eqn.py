#!/usr/bin/env python
# This file defines a distance metric between algebraic equations.
# Dependencies:
#	compiler module for parsing eqn strings into abstract syntax trees
#

import compiler
# required functions
#distanceBetween
#astOfEqn	# calls compiler module to generate ast and return in a useful way 
#distanceOfASTs # recursive, does actual ast comparison
# sanitize EQnString

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
	print [ side for side in clean_eqn.split('=')]
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
def compareExpressionsRecursive(fst_expr, snd_expr):
	"""compare two parsed expressions and return their differences"""
	diff = 0
	if fst_expr is None:
		return countSubtreeNodes(snd_expr)
	elif snd_expr is None:
		return countSubtreeNodes(fst_expr)
	elif isinstance(fst_expr, compiler.ast.Const) and isinstance(snd_expr, compiler.ast.Const):
		return compareMonomials(fst_expr, snd_expr)
	# include case to handle monomial comparisons 
	elif fst_expr.__class__ != snd_expr.__class__:
		diff += 1
	# only fst has children
	elif isinstance(fst_expr, compiler.ast.Const):
		return countSubtreeNodes(snd_expr)
	# only snd has chilren
	elif isinstance(snd_expr, compiler.ast.Const):
		return countSubtreeNodes(fst_expr)
	# both have children
	else:
		diff += sum(map(compareExpressionsRecursive, fst_expr.getChildren(), snd_expr.getChildren()))
	return diff

def countSubtreeNodes(fst_expr, depth=0):
	if isinstance(fst_expr, compiler.ast.Power):
		return 1
	else:
		return 1 + sum(map(countSubtreeNodes, fst_expr.getChildren()))
def compareMonomials(fst_mono, snd_mono):
	# compare degree values
	return 0
def isMonomial(expr):
	""" monomials have exactly two children and they must be Mul and Power respectively """
	if len(expr.getChildren()) != 2 :
		return False
	coeff, variable = expr.getChildren()[:2]
	return (isinstance(expr, compiler.ast.Mul) and 
			isinstance(coeff, compiler.ast.Const) and 
			isinstance(variable, compiler.ast.Power) )
	

# this code is for testing purposes only
fst = '3*x^5 + 4 = 0'
snd = 'x^2 + 4*x + 6 = 2'

print distanceBetweenEqn(fst, snd)
