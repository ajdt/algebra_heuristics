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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Equality %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_equalCoeffs(Time, FstMono, SndMono)
	:-	_coeffOf(Time, FstMono, Coeff),
		_coeffOf(Time, SndMono, Coeff).
_equalDegs(Time, FstMono, SndMono)
	:-	_degOf(Time, FstMono, Deg),
		_degOf(Time, SndMono, Deg).
_equal(Time, FstMono, SndMono)
	:-	_equalCoeffs(Time, FstMono, SndMono),
		_equalDegs(Time, FstMono, SndMono).
