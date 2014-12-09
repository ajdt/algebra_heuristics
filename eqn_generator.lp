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
%%#include "rule_features.lp".%%
%%activeNode(Node)%%
	%%:-	_isActive(_time(0,1), Node).%%
:- not _selectedHeuristic(_time(0,1), cancelAcrossEqn).

typeOfOperand(Type)
	:-	_operand(Time, Oper, Rule, Side),
		_hasType(Time, Oper, Type).

selectedOperand(Oper)
	:-	_operand(Time, Oper, Rule, Side).

%%% CONSTRAINT: denominator should not be +- 1
:-	_denomOf(Time, Frac, Denom),
	_absoluteValueIsOne(Time, Denom).
