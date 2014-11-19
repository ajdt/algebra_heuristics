% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% A simple ASP program to generate algebraic equations.
% Equations are represented in an expression tree, where internal nodes are
% operators (add/mul/div) and leaf nodes are monomials.
% 
%

#include "config_params.lp".
#include "nodes.lp".
#include "polynomial.lp".
#include "eqn_solver.lp".
#include "rules.lp".
#include "math_operations.lp".
#include "heuristics.lp".

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROBLEM GENERATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% every root node (see node.lp) is active initially
_holds(initially, _fact(Node, _nodeField(active,yes)))	
		:-	_rootNode(Node).

% 1. assigning type to a node, if we're at max depth node must be a polynomial
1 { _holds(initially, _fact(Node, _nodeField(type, Type))) : _type(Type), not _disallowedType(Type)} 1		
		:-	_isActive(initially, Node),
			_nodeDepth(Node, Depth), 
			Depth < maxDepth.

 _holds(initially, _fact(Node, _nodeField(type, mono)))
		:-	_isActive(initially, Node),
			_nodeDepth(Node, maxDepth).

% 2. assign number of children, for division node, num children must be 2
1 { _numChildren(initially, Node,  Num) : _childCount(Num), Num <=  MaxNumChildren, Num <= maxInitialChildren} 1	
		:-	_isOper(initially, Node),
			not _isDiv(initially, Node),
			not _isNeg(initially, Node),
			_maxNumChildren(Node, MaxNumChildren).

_numChildren(initially, Node, 1)
		:-	_isNeg(initially, Node).
_numChildren(initially, Node, 2)						
		:-	_isDiv(initially, Node).

% 3. activate children for parent node 
_holds(initially, _fact(Parent, _nodeField(activechild, Child)))
		:-	_numChildren(initially, Parent,  TotalNumChildren), 
			_childNum(Parent, Child, ChildNum),
			ChildNum <= TotalNumChildren.

% 4. indicate child is active also
_holds(initially, _fact(Child, _nodeField(active,yes)))	
		:-	_holds(initially, _fact(Parent, _nodeField(activechild, Child))).

% 5. fractions also have numer/denom fields to alias first and second child
% NOTE: these fields are now derived in nodes.lp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ASSIGN Monomials %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
1 { _holds(initially, _fact(Node, _nodeField(degree, Order))) : _degree(Order) , Order <= maxInitialDeg } 1 	
		:-	_isMono(initially, Node).

1 { _holds(initially, _fact(Node, _nodeField(coeff, Coeff))) : _coeff(Coeff) , |Coeff| <= maxInitialCoeff } 1 	
		:-	_isMono(initially, Node).
					
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREVENTING ZERO DENOMINATORS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Constraint: if a denominator is reducible to zero, then fail
:- _reducibleToZero(Time, Node), _denomOf(Time, Frac, Node).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MISC GENERATION CONSTRAINTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CONSTRAINT: div node has at most 2 children
:- _isDiv(Time, Node), _activeChild(Time, Node, Child), _childNum(Node, Child, Num), Num >= 3.
_hasNoDeg(Time, Mono) :- _isMono(Time, Mono), 0 { _degOf(Time, Mono, Deg) : _degree(Deg) } 0.
%%% CONSTRAINT: each monomial must have a degree term. NOTE: for some unknown reason, monomials without degree terms were being generated too
:-	_validTime(Time), _isMono(Time, Mono), _hasNoDeg(Time, Mono).

% monomial nodes must be leave nodes
_isLeafNode(Time, Mono)
	:-	_isMono(Time, Mono), 
		0 { _activeChild(Time, Mono, Child) : _node(Child) } 0 .
_monoHasChildren(Time, Mono)
	:-	_isMono(Time, Mono), 
	not _isLeafNode(Time, Mono).

:- _monoHasChildren(Time, Mono).

% CONSTRAINT: unary operations (just neg really), must have exactly one child at all times
:-	_unary(Oper),
	_hasType(Time, Node, Oper),
	2 { _activeChild(Time, Node, Child) : _validChildOf(Node, Child) }.
