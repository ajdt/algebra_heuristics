% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file defines predicates specific to monomials and polynomials
%

_coeff(-1*maxCoeff..maxCoeff).
_degree(0..maxDeg).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Polynomial Tree Structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_isPolynomial(Time, Node)
	:-	_isAdd(Time, Node),
		not _hasNestedExpression(Time, Node).
_hasNestedExpression(Time, Node)
	:-	_activeChild(Time, Node, Child),
		not _isMono(Time, Child).

_isXTerm(Time, Node)
	:-	_isMono(Time, Node),
		_coeffOf(Time, Node, 1),
		_degOf(Time, Node, 1).
_hasXTerm(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		_activeChild(Time, Poly, Child),
		_isXTerm(Time, Child).

_isConstant(Time, Node)
	:-	_isMono(Time, Node),
		_degOf(Time, Node, 0).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Polynomial Properties %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_polyHasTermWithDeg(Time, Poly, Deg)
	:-	_isPolynomial(Time, Poly),
		_activeChild(Time, Poly, Child),
		_degOf(Time, Child, Deg).
_hasSingleTermWithDeg(Time, Poly, Deg)
	:-	_polyHasTermWithDeg(Time, Poly, Deg),
		1 { _degOf(Time, Child, Deg) : _activeChild(Time, Poly, Child) } 1.
_hasTermWithDegLargerThan(Time, Poly, FstDeg)
	:-	_degree(FstDeg),
		_polyHasTermWithDeg(Time, Poly, SndDeg),
		FstDeg < SndDeg.
_hasTermWithDegSmallerThan(Time, Poly, FstDeg)
	:-	_degree(FstDeg),
		_polyHasTermWithDeg(Time, Poly, SndDeg),
		FstDeg > SndDeg.

% a standard polynomial doesn't have multiple terms of the same degree
_isStandardPoly(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		not _notStandardPoly(Time, Poly).
_notStandardPoly(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		_polyHasTermWithDeg(Time, Poly, Deg),
		not _hasSingleTermWithDeg(Time, Poly, Deg).

% access coeff/degree pairs of monomials at the polynomial level
_monoTermOfPoly(Time, Poly, Deg, Coeff)
	:-	_isPolynomial(Time, Poly),
		_activeChild(Time, Poly, Child),
		_degOf(Time, Child, Deg),
		_coeffOf(Time, Child, Coeff).

% is factorable
_isFactorable(Time, Poly) % poly has form x^2 + b*x + c
	:-	_isPolynomial(Time, Poly),
		_isStandardPoly(Time, Poly),
		_monoTermOfPoly(Time, Poly, 2, 1),	
		_monoTermOfPoly(Time, Poly, 1, LinearCoeff),
		_monoTermOfPoly(Time, Poly, 0, ConstCoeff),
		_factorable(LinearCoeff, ConstCoeff).
_factors(Fst, Snd, Sum, Prod)
	:-	_coeff(Fst),
		_coeff(Snd),
		Fst <= Snd,	% establishes an ordering of factors to avoid redundancy
		Sum = Fst + Snd,
		Prod = Fst * Snd,
		_coeff(Sum),
		_coeff(Prod).
_factorable(Sum, Prod)
	:- _factors(Fst, Snd, Sum, Prod).

% polynomial forms
_isQuadratic(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		_polyHasTermWithDeg(Time, Poly, 2),
		not _hasTermWithDegLargerThan(Time, Poly, 2).
_isLinear(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		_polyHasTermWithDeg(Time, Poly, 1),
		not _hasTermWithDegLargerThan(Time, Poly, 1).

			%%% extracting a common term from a polynomial
_hasCommonDeg(Time, Poly)
	:-	_hasCommonDeg(Time, Poly, Deg).

_hasCommonDeg(Time, Poly, Deg)
	:-	_isPolynomial(Time, Poly),
		_degree(Deg),
		not _hasTermWithDegSmallerThan(Time, Poly, Deg).
% coefficient factors
_coeffFactorPairOf(Fst, Snd, Prod)
	:-	_factors(Fst, Snd, Sum, Prod).
_coeffFactorPairOf(Snd, Fst, Prod)
	:-	_factors(Fst, Snd, Sum, Prod).
_coeffFactorOf(Fst, Prod)
	:-	_coeffFactorPairOf(Fst, Snd, Prod).

_hasCommonCoeff(Time, Poly)
	:-	_hasCommonCoeff(Time, Poly, Coeff).
_hasCommonCoeff(Time, Poly, Coeff)
	:-	_isPolynomial(Time, Poly),
		_coeff(Coeff),
		not _notCoeffFactorOfPoly(Time, Poly, Coeff).

_notCoeffFactorOfPoly(Time, Poly, Coeff)
	:-	_coeff(Coeff),
		_polyHasTermWithCoeff(Time, Poly, MonoCoeff),
		not _coeffFactorOf(Coeff, MonoCoeff).

_polyHasTermWithCoeff(Time, Poly, Coeff)
	:-	_isPolynomial(Time, Poly),
		_activeChild(Time, Poly, Mono),
		_coeffOf(Time, Mono, Coeff).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Equality %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_equalDegs(Time, FstMono, SndMono)
	:-	_degOf(Time, FstMono, Deg),
		_degOf(Time, SndMono, Deg),
		_node(FstMono),
		_node(SndMono),
		Time != initially,
		FstMono != SndMono.
_equal(Time, FstMono, SndMono)
	:-	_equalDegs(Time, FstMono, SndMono),
		_coeffOf(Time, FstMono, Coeff),
		_coeffOf(Time, SndMono, Coeff),
		_node(FstMono),
		_node(SndMono),
		Time != initially,
		FstMono != SndMono.

% equality of non-leaf nodes
% two internal nodes are equal if each of their corresponding children are equal.
% Basically, if child 1 of Node X equals child 1 of Node Y, and so on...
% IMPORTANT NOTE: The code below checks for structural equality
%		Thus, x + 1		is NOT considered equal to 	1 + x 
_equal(Time, FstNode, SndNode)
	:-	_correspChildrenAreEqual(Time, FstNode, SndNode),
		_hasType(Time, FstNode, Type),
		_hasType(Time, SndNode, Type),
		Time != initially,
		Type != mono.	% mono equality is handled separately
_correspChildrenAreEqual(Time, FstNode, SndNode)
	:-	_isOper(Time, FstNode),
		_isOper(Time, SndNode),
		Time != initially,
		FstNode != SndNode,
		not _haveUnequalChildren(Time, FstNode, SndNode).
_haveUnequalChildren(Time, FstNode, SndNode)	% found a corresponding pair that is unequal
	:-	_isActive(Time, FstNode),
		_isActive(Time, SndNode),
		FstNode != SndNode,
		Time != initially,
		_numActiveChildren(Time, FstNode, TotalChildren),
		_childNum(FstNode, FstChild, Num),
		_childNum(SndNode, SndChild, Num),
		Num <= TotalChildren,
		not _equal(Time, FstChild, SndChild).
_haveUnequalChildren(Time, FstNode, SndNode)	% if two nodes have an unequal number of children
	:-	_isActive(Time, FstNode),				% then they're automatically unequal
		_isActive(Time, SndNode),
		FstNode != SndNode,
		Time != initially,
		_numActiveChildren(Time, FstNode, FstTotalChildren),
		_numActiveChildren(Time, SndNode, SndTotalChildren),
		FstTotalChildren != SndTotalChildren.
%%% Rational Numbers
% NOTE: rational numbers must be represented as fractions, a rational number cannot be 
%	represented in a single node like integer constants can be.
_isRational(Time, Node)
	:-	_isDiv(Time, Node),
		_numerOf(Time, Node, Numer),
		_denomOf(Time, Node, Denom),
		_isConstant(Time, Numer),
		_isConstant(Time, Denom).
