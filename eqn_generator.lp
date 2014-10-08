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

% sides of an equation
_side(right;left).
_otherSide(left, right; right, left). 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROBLEM GENERATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% every root node (see node.lp) is active initially
_holds(initially, _fact(Node, _nodeField(active,yes)))	
		:-	_rootNode(Node).

% 1. assigning type to a node, if we're at max depth node must be a polynomial
1 { _holds(initially, _fact(Node, _nodeField(type, Type))) : _type(Type)} 1		
		:-	_isActive(initially, Node),
			_depthOfNode(Node, Depth), 
			Depth < maxDepth.

 _holds(initially, _fact(Node, _nodeField(type, mono)))
		:-	_isActive(initially, Node),
			_depthOfNode(Node, maxDepth).

% 2. assign number of children, for division node, num children must be 2
1 { _numChildren(initially, Node,  Num) : _validNumChildren(Node, Num) } 1	
		:-	_isOper(initially, Node),
			not _isDiv(initially, Node).

_numChildren(initially, Node, 2)						
		:-	_isDiv(initially, Node).

% 3. activate children for parent node 
_holds(initially, _fact(Parent, _nodeField(activechild, Child)))
		:-	_numChildren(initially, Node,  TotalNumChildren), 
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
%%:-	_denomOf(Time, Frac, Denom),%%
	%%_isZero(Time, Denom).%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MISC GENERATION CONSTRAINTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% constraint: div node has at most 2 children
:- _isDiv(Time, Node), _activeChild(Time, Node, Child), _childNum(Node, Child, Num), Num >= 3.
:- _isMono(Time, Mono), 0 { _degOf(Time, Mono, Deg) : _degree(Deg) } 0.
