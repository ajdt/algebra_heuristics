% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
#include "nodes.lp".
#include "polynomial.lp".
#include "eqn_solver.lp".
#include "rules.lp".
#include "math_operations.lp".
#include "heuristics.lp".
%%#include "rule_features.lp".%%

% external predicate dependencies
%%isActive%%
%%isOper%%
%%isDiv%%
%%isNeg%%
%%isMono%%

_initiallyIsActive(Time, Node)
	:-	_initially(Time, _fact(Node, _nodeField(active, yes))).
_initiallyHasType(Time, Node, Type)
	:-	_initially(Time, _fact(Node, _nodeField(type, Type))).

_initiallyIsOper(Time, Node)
	:-	_initiallyHasType(Time, Node, Type),
		Type != mono.
_initiallyIsDiv(Time, Node)
		:-	_initiallyHasType(Time, Node, div).
_initiallyIsMul(Time, Node)
		:-	_initiallyHasType(Time, Node, mul).
_initiallyIsAdd(Time, Node)
		:-	_initiallyHasType(Time, Node, add).
_initiallyIsNeg(Time, Node)
		:-	_initiallyHasType(Time, Node, neg).
_initiallyIsMono(Time, Node)
		:-	_initiallyHasType(Time, Node, mono).

_holds(StartTime, Fluent)
	:-	_initially(Initially, Fluent),
		_streamOfInitTime(Initially, Stream),
		_startTime(StartTime),
		_streamOf(StartTime, Stream).
%%other changes%%
%%* numChildren() if used elsewhere%%
%%* requirements to eqn structure changed to apply mainly to holds predicates%%

%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
% NOTE: don't include config_params instead specify params here
%++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#const	maxInitialCoeff	=	5.
#const	maxCoeff		=	2*maxInitialCoeff.
#const	maxInitialDeg	=	2.
#const	maxDeg			=	2*maxInitialDeg.

% expression tree parameters
#const maxChildren	=	4.	% limit on children of operator nodes
#const maxInitialChildren	=	3. 	% limit on number of children a node can start with
#const maxDepth		=	3.	% limits number of layers used during generation
#const maxInitialDepth		=	2.	

% solver params
#const maxSteps = 1.
#const maxNumStreams	= 2.	% two separate problems, so two streams are required

% problem feature constraints 
:- _coeffOverflow.
:- _degOverflow.


_initialTime(_eqn(1..maxNumStreams)).	% captures idea of initial state of a particular eqn 
_streamOfInitTime(Time, Stream)
	:-	_initialTime(_eqn(Stream)),
		Time = _eqn(Stream).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROBLEM GENERATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% every root node (see node.lp) is active initially
_initially(Initially, _fact(Node, _nodeField(active,yes)))	
		:-	_rootNode(Node),
			_initialTime(Initially).

% 1. assigning type to a node, if we're at max depth node must be a polynomial
1 { _initially(Initially, _fact(Node, _nodeField(type, Type))) : _type(Type), not _disallowedType(Type)} 1		
		:-	_initiallyIsActive(Initially, Node),
			_initialTime(Initially),
			_nodeDepth(Node, Depth), 
			Depth < maxInitialDepth.

 _initially(Initially, _fact(Node, _nodeField(type, mono)))
		:-	_initiallyIsActive(Initially, Node),
			_initialTime(Initially),
			_nodeDepth(Node, Depth),
			Depth >= maxInitialDepth.

% 2. assign number of children, for division node, num children must be 2
1 { _numChildren(Initially, Node,  Num) : _childCount(Num), Num <=  MaxNumChildren, Num <= maxInitialChildren} 1	
		:-	_initiallyIsOper(Initially, Node),
			_initialTime(Initially),
			not _initiallyIsDiv(Initially, Node),
			not _initiallyIsNeg(Initially, Node),
			_maxNumChildren(Node, MaxNumChildren).

_numChildren(Initially, Node, 1)
		:-	_initiallyIsNeg(Initially, Node),
			_initialTime(Initially).
_numChildren(Initially, Node, 2)						
		:-	_initiallyIsDiv(Initially, Node),
			_initialTime(Initially).

% 3. activate children for parent node 
_initially(Initially, _fact(Parent, _nodeField(activechild, Child)))
		:-	_numChildren(Initially, Parent,  TotalNumChildren), 
			_childNum(Parent, Child, ChildNum),
			_initialTime(Initially),
			ChildNum <= TotalNumChildren.

% 4. indicate child is active also
_initially(Initially, _fact(Child, _nodeField(active,yes)))	
		:-	_initially(Initially, _fact(Parent, _nodeField(activechild, Child))),
			_initialTime(Initially).

% 5. fractions also have numer/denom fields to alias first and second child
% NOTE: these fields are now derived in nodes.lp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ASSIGN Monomials %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
1 { _initially(Initially, _fact(Node, _nodeField(degree, Order))) : _degree(Order) , Order <= maxInitialDeg } 1 	
		:-	_initiallyIsMono(Initially, Node),
			_initialTime(Initially).

1 { _initially(Initially, _fact(Node, _nodeField(coeff, Coeff))) : _coeff(Coeff) , |Coeff| <= maxInitialCoeff } 1 	
		:-	_initiallyIsMono(Initially, Node),
			_initialTime(Initially).
					
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
