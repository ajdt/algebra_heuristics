% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file defines predicates specific to monomials and polynomials
%

_coeff(-1*maxCoeff..maxCoeff).
_degree(0..maxDeg).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Polynomial Tree Structure %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_isPolynomial(Time, Node)
	:-	_isAdditionOperation(Time, Node),
		not _hasNestedExpression(Time, Node).
_hasNestedExpression(Time, Node)
	:-	_isATermOf(Time, Node, Child),
		not __isMono(Time, Child).

_isXTerm(Time, Node)
	:-	__isMono(Time, Node),
		_isTheCoefficientOf(Time, Node, 1),
		_isTheDegreeOf(Time, Node, 1).
_hasXTerm(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		_isATermOf(Time, Poly, Child),
		_isXTerm(Time, Child).

_isConstant(Time, Node)
	:-	__isMono(Time, Node),
		_isTheDegreeOf(Time, Node, 0).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Zero Coeff Constraint %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% NOTE: to avoid redundancies, if a node has coeff==0, it must have deg = 0
_hasZeroDeg(Time, Node)
	:-	_isTheDegreeOf(Time, Node, 0).

%%% CONSTRAINT: a zero monomial should have deg == 0 as well
:-	_isTheCoefficientOf(Time, Node, 0),
	not _hasZeroDeg(Time, Node).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Polynomial Properties %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% CONSTRAINT: ensure polynomials are in descending order
:-	__validTime(Time), _monosOutOfOrder(Time).
_monoSiblings(Time, Fst, Snd)
	:-	_areSiblings(Time, Fst, Snd),
		Fst < Snd,
		__isMono(Time, Fst),
		__isMono(Time, Snd).
_monosOutOfOrder(Time)
	:-	_monoSiblings(Time, Fst, Snd),
		_isTheDegreeOf(Time, Fst, FstDeg),
		_isTheDegreeOf(Time, Snd, SndDeg),
		FstDeg < SndDeg.
_monoSiblingsHaveCoeffValuesInOrder(Time, Fst, Snd)
	:-	_monoSiblings(Time, Fst, Snd),
		Fst < Snd,
		_isTheCoefficientOf(Time, Fst, FstCoeff),
		_isTheCoefficientOf(Time, Snd, SndCoeff),
		SndCoeff > FstCoeff.
_monosOutOfOrder(Time)
	:-	_monoSiblings(Time, Fst, Snd),
		_isTheDegreeOf(Time, Fst, SameDeg),
		_isTheDegreeOf(Time, Snd, SameDeg),
		not _monoSiblingsHaveCoeffValuesInOrder(Time, Fst, Snd).

_polyHasTermWithDeg(Time, Poly, Deg)
	:-	_isPolynomial(Time, Poly),
		_isATermOf(Time, Poly, Child),
		_isTheDegreeOf(Time, Child, Deg).
_hasSingleTermWithDeg(Time, Poly, Deg)
	:-	_polyHasTermWithDeg(Time, Poly, Deg),
		1 { _isTheDegreeOf(Time, Child, Deg) : _isATermOf(Time, Poly, Child) } 1.
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
		_isATermOf(Time, Poly, Child),
		_isTheDegreeOf(Time, Child, Deg),
		_isTheCoefficientOf(Time, Child, Coeff).

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
		_isATermOf(Time, Poly, Mono),
		_isTheCoefficientOf(Time, Mono, Coeff).


% equation-wide deg info
% NOTE: we're interested in smallest non-zero degree to perform degree substitution
_eqnHasNonZeroDeg(Time, Deg)
	:-	_isTheDegreeOf(Time, Node, Deg), Deg >  0.
_smallestNonZeroDeg(Time, FstDeg)
	:-	_eqnHasNonZeroDeg(Time, FstDeg),
		0 { _eqnHasNonZeroDeg(Time, SndDeg) : _degree(SndDeg), SndDeg < FstDeg} 0.
_smallestNonZeroDeg(Time, 1)	
	:-	_eqnHasNonZeroDeg(Time, 1).

_degProduct(Prod, Fst, Snd) 
	:-	_degree(Fst),
		_degree(Snd),
		Prod = Fst*Snd,
		_degree(Prod).
_degDivisbleBy(Prod, Fst)
	:-	_degProduct(Prod, Fst, Snd).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Equality %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_haveEqualDegrees(Time, FstMono, SndMono)
	:-	_isTheDegreeOf(Time, FstMono, Deg),
		_isTheDegreeOf(Time, SndMono, Deg),
		_node(FstMono),
		_node(SndMono),
		Time != initially,
		FstMono != SndMono.
_areEqual(Time, FstMono, SndMono)
	:-	_haveEqualDegrees(Time, FstMono, SndMono),
		_isTheCoefficientOf(Time, FstMono, Coeff),
		_isTheCoefficientOf(Time, SndMono, Coeff),
		_node(FstMono),
		_node(SndMono),
		Time != initially,
		FstMono != SndMono.

% equality of non-leaf nodes
% two internal nodes are equal if each of their corresponding children are equal.
% Basically, if child 1 of Node X equals child 1 of Node Y, and so on...
% IMPORTANT NOTE: The code below checks for structural equality
%		Thus, x + 1		is NOT considered equal to 	1 + x 
_areEqual(Time, FstNode, SndNode)
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
	:-	__isActive(Time, FstNode),
		__isActive(Time, SndNode),
		FstNode != SndNode,
		Time != initially,
		_numActiveChildren(Time, FstNode, TotalChildren),
		_childNum(FstNode, FstChild, Num),
		_childNum(SndNode, SndChild, Num),
		Num <= TotalChildren,
		not _areEqual(Time, FstChild, SndChild).
_haveUnequalChildren(Time, FstNode, SndNode)	% if two nodes have an unequal number of children
	:-	__isActive(Time, FstNode),				% then they're automatically unequal
		__isActive(Time, SndNode),
		FstNode != SndNode,
		Time != initially,
		_numActiveChildren(Time, FstNode, FstTotalChildren),
		_numActiveChildren(Time, SndNode, SndTotalChildren),
		FstTotalChildren != SndTotalChildren.
%%% Rational Numbers
% NOTE: rational numbers must be represented as fractions, a rational number cannot be 
%	represented in a single node like integer constants can be.
_isRational(Time, Node)
	:-	_isFraction(Time, Node),
		_numeratorOf(Time, Node, Numer),
		_denominatorOf(Time, Node, Denom),
		_isConstant(Time, Numer),
		_isConstant(Time, Denom).
_isProperRational(Time, Node)
	:-	_isRational(Time, Node),
		not _isImproperRational(Time, Node).

_isImproperRational(Time, Node)
	:-	_isRational(Time, Node),
		_numeratorOf(Time, Node, Numer),
		_isZero(Time, Numer).
_isImproperRational(Time, Node)
	:-	_isRational(Time, Node),
		_numeratorOf(Time, Node, Numer),
		_absoluteValueIsOne(Time, Numer),
		_denominatorOf(Time, Node, Denom),
		_absoluteValueIsOne(Time, Denom).

