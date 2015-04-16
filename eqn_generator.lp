% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% The top-level asp file used by clingo to generate algebra problems.
% This file acts kind of like a header file in C++, but doesn't contain
% any declarations itself. Here we just bring together the
% misc gringo files necessary to generate a single algebra problem
% 
%

#include "config_params.lp".
#include "prob_generator.lp".
#include "nodes.lp".
#include "polynomial.lp".
#include "eqn_solver.lp".
#include "rules.lp".
#include "math_operations.lp".
#include "heuristics.lp".

%%% CONSTRAINT: denominator should not be +- 1 in the solution
:-	_denominatorOf(Time, Frac, Denom),
	_absoluteValueIsOne(Time, Denom),
    _stopTime(Time).


% Don't use negation operator when generating problems
_disallowedType(neg).

