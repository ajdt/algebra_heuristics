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
		Sum = Fst + Snd,
		Prod = Fst * Snd,
		_coeff(Sum),
		_coeff(Prod).
_factorable(Sum, Prod)
	:- _factors(Fst, Snd, Sum, Prod).
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
