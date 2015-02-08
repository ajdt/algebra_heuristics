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
		:-	__isMono(StartTime, Node),
			_startTime(StartTime).

1 { _holds(StartTime, _fact(Node, _nodeField(coeff, Coeff))) : _coeff(Coeff) , |Coeff| <= maxInitialCoeff } 1 	
		:-	__isMono(StartTime, Node),
			_startTime(StartTime).
					
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PREVENTING ZERO DENOMINATORS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Constraint: if a denominator is reducible to zero, then fail
:- _reducibleToZero(Time, Node), _denomOf(Time, Frac, Node).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ORDER CONSTRAINTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: this constraint reduces redundancy by partially defining
% a canonical form for a given problem to have
_subtreeHeight(Time, Node, 0)
	:-	__isMono(Time, Node).
_hasSubtreeWithHeight(Time, Parent, Height)
	:-	_isATermOf(Time, Parent, Child),
		_subtreeHeight(Time, Child, Height).
_subtreeHeight(Time, Node, Height+1)
	:-	_hasSubtreeWithHeight(Time, Node, Height),
	0 { _hasSubtreeWithHeight(Time, Node, OtherHeight) : OtherHeight > Height } 0.

_initiallyOutOfOrderByHeight(Fst, Snd)
	:-	_areSiblings(StartTime, Fst, Snd),
		_subtreeHeight(StartTime, Fst, FstHeight),
		_subtreeHeight(StartTime, Snd, SndHeight),
		_startTime(StartTime),
		FstHeight < SndHeight.

_initiallyOutOfOrderByNumKids(Fst, Snd)
	:-	_startTime(StartTime),
		_areSiblings(StartTime, Fst, Snd),
		not _initiallyOutOfOrderByHeight(Fst, Snd),
		_numActiveChildren(StartTime, Fst, FstTotal),
		_numActiveChildren(StartTime, Snd, SndTotal),
		FstTotal < SndTotal.

%%% CONSTRAINT: no subtree should be out of order
%%:- _initiallyOutOfOrderByHeight(Fst, Snd).%%
%%:- _initiallyOutOfOrderByNumKids(Fst, Snd).%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MISC GENERATION CONSTRAINTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CONSTRAINT: div node has at most 2 children
:- _isDiv(Time, Node), _isATermOf(Time, Node, Child), _childNum(Node, Child, Num), Num >= 3.
_hasNoDeg(Time, Mono) :- __isMono(Time, Mono), 0 { _isTheDegreeOf(Time, Mono, Deg) : _degree(Deg) } 0.
%%% CONSTRAINT: each monomial must have a degree term. NOTE: for some unknown reason, monomials without degree terms were being generated too
:-	__validTime(Time), __isMono(Time, Mono), _hasNoDeg(Time, Mono).

% monomial nodes must be leave nodes
_isLeafNode(Time, Mono)
	:-	__isMono(Time, Mono), 
		0 { _isATermOf(Time, Mono, Child) : _node(Child) } 0 .
_monoHasChildren(Time, Mono)
	:-	__isMono(Time, Mono), 
	not _isLeafNode(Time, Mono).

:- _monoHasChildren(Time, Mono).

% CONSTRAINT: unary operations (just neg really), must have exactly one child at all times
:-	_unary(Oper),
	_hasType(Time, Node, Oper),
	2 { _isATermOf(Time, Node, Child) : _validChildOf(Node, Child) }.

% TODO: figure out why _coeffOverflow and _degOverflow cause UNSAT even when not triggered
_hasCoeff(Time, Node)
	:-	_isTheCoefficientOf(Time, Node, Coeff).
_hasDeg(Time, Node)
	:-	_isTheDegreeOf(Time, Node, Deg).
% CONSTRAINT: every monomial has a degree value
:- __isMono(Time, Node), not _hasDeg(Time, Node).
% CONSTRAINT: every monomial has a coeff value
:- __isMono(Time, Node), not _hasCoeff(Time, Node).
