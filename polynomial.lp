% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file defines monomials and contains useful
% predicates relating to polynomials
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

_notStandardPoly(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		_polyHasTermWithDeg(Time, Poly, Deg),
		not _hasSingleTermWithDeg(Time, Poly, Deg).
_isStandardPoly(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		not _notStandardPoly(Time, Poly).

_monoTermOfPoly(Time, Poly, Deg, Coeff)
	:-	_isPolynomial(Time, Poly),
		_activeChild(Time, Poly, Child),
		_degOf(Time, Child, Deg),
		_coeffOf(Time, Child, Coeff).
% is factorable
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
_isFactorable(Time, Poly) % poly has form x^2 + b*x + c
	:-	_isPolynomial(Time, Poly),
		_isStandardPoly(Time, Poly),
		_monoTermOfPoly(Time, Poly, 2, 1),	
		_monoTermOfPoly(Time, Poly, 1, LinearCoeff),
		_monoTermOfPoly(Time, Poly, 0, ConstCoeff),
		_factorable(LinearCoeff, ConstCoeff).

% polynomial forms
_isQuadratic(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		_polyHasTermWithDeg(Time, Poly, 2),
		not _hasTermWithDegLargerThan(Time, Poly, 2).

% extracting a common term
_hasCommonDeg(Time, Poly)
	:-	_hasCommonDeg(Time, Poly, Deg).

_hasCommonDeg(Time, Poly, Deg)
	:-	_isPolynomial(Time, Poly),
		_degree(Deg),
		not _hasTermWithDegSmallerThan(Time, Poly, Deg).
% coefficient factors
_coeffFactorOf(Fst, Prod)
	:-	_factors(Fst, Snd, Sum, Prod).
_coeffFactorOf(Snd, Prod)
	:-	_factors(Fst, Snd, Sum, Prod).

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
_equalCoeffs(Time, FstMono, SndMono)
	:-	_coeffOf(Time, FstMono, Coeff),
		_coeffOf(Time, SndMono, Coeff),
		_node(FstMono),	% we don't care about equality among temp nodes
		_node(SndMono),
		Time != initially,	% don't care about equality initially either
		FstMono != SndMono.

_equalDegs(Time, FstMono, SndMono)
	:-	_degOf(Time, FstMono, Deg),
		_degOf(Time, SndMono, Deg),
		_node(FstMono),
		_node(SndMono),
		Time != initially,
		FstMono != SndMono.
_equal(Time, FstMono, SndMono)
	:-	_equalCoeffs(Time, FstMono, SndMono),
		_equalDegs(Time, FstMono, SndMono),
		_node(FstMono),
		_node(SndMono),
		Time != initially,
		FstMono != SndMono.
