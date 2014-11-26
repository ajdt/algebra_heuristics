% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% A simple ASP program to generate algebraic equations.
% Equations are represented in an expression tree, where internal nodes are
% operators (add/mul/div) and leaf nodes are monomials.
% 
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PROBLEM GENERATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% every root node (see node.lp) is active initially
_holds(StartTime, _fact(Node, _nodeField(active,yes)))	
		:-	_rootNode(Node),
			_startTime(StartTime).

% 1. assigning type to a node, if we're at max depth node must be a polynomial
1 { _holds(StartTime, _fact(Node, _nodeField(type, Type))) : _type(Type), not _disallowedType(Type)} 1		
		:-	_isActive(StartTime, Node),
			_nodeDepth(Node, Depth), 
			_startTime(StartTime),
			Depth < maxInitialDepth.

 _holds(StartTime, _fact(Node, _nodeField(type, mono)))
		:-	_isActive(StartTime, Node),
			_startTime(StartTime),
			_nodeDepth(Node, Depth),
			Depth >= maxInitialDepth.

% 2. assign number of children, for division node, num children must be 2
1 { _numChildren(StartTime, Node,  Num) : _childCount(Num), Num <=  MaxNumChildren, Num <= maxInitialChildren} 1	
		:-	_isOper(StartTime, Node),
			_startTime(StartTime),
			not _isDiv(StartTime, Node),
			not _isNeg(StartTime, Node),
			_maxNumChildren(Node, MaxNumChildren).

_numChildren(StartTime, Node, 1)
		:-	_isNeg(StartTime, Node),
			_startTime(StartTime).
_numChildren(StartTime, Node, 2)						
		:-	_isDiv(StartTime, Node),
			_startTime(StartTime).

% 3. activate children for parent node 
_holds(StartTime, _fact(Parent, _nodeField(activechild, Child)))
		:-	_numChildren(StartTime, Parent,  TotalNumChildren), 
			_startTime(StartTime),
			_childNum(Parent, Child, ChildNum),
			ChildNum <= TotalNumChildren.

% 4. indicate child is active also
_holds(StartTime, _fact(Child, _nodeField(active,yes)))	
		:-	_holds(StartTime, _fact(Parent, _nodeField(activechild, Child))),
			_startTime(StartTime).

% 5. fractions also have numer/denom fields to alias first and second child
% NOTE: these fields are now derived in nodes.lp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ASSIGN Monomials %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
1 { _holds(StartTime, _fact(Node, _nodeField(degree, Order))) : _degree(Order) , Order <= maxInitialDeg } 1 	
		:-	_isMono(StartTime, Node),
			_startTime(StartTime).

1 { _holds(StartTime, _fact(Node, _nodeField(coeff, Coeff))) : _coeff(Coeff) , |Coeff| <= maxInitialCoeff } 1 	
		:-	_isMono(StartTime, Node),
			_startTime(StartTime).
					
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
