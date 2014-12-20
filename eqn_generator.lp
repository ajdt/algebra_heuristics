% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% The top-level asp file used by clingo to generate algebra problems.
% This file acts kind of like a header file in C++, but doesn't contain
% any declarations itself. Here we just bring together the
% misc gringo files necessary to generate a single algebra problem
% 
%

%%#script (python)%%
%%import gringo%%
%%import random%%
%%def calcHash(X):%%
	%%return (X*(X+3))%100%%
%%#end.%%
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
%%:- not _selectedHeuristic(_time(0,1), cancelAcrossEqn).%%

typeOfOperand(Type)
	:-	_operand(Time, Oper, Rule, Side),
		_hasType(Time, Oper, Type).

selectedOperand(Oper)
	:-	_operand(Time, Oper, Rule, Side).

usesNode(Node)
	:-	_isActive(StartTime, Node),
		_startTime(StartTime).
eqnHasMonoWithDeg(Deg)
	:-	_startTime(StartTime),
		_degOf(StartTime, Mono, Deg).
%%_someNumber(1..10).%%
%%1 { selectedNum(X) : _someNumber(X) } 1 %%
	%%:-	_startTime(ST) .%%
%%% CONSTRAINT: denominator should not be +- 1 in the solution
:-	_denomOf(Time, Frac, Denom),
	_absoluteValueIsOne(Time, Denom),
    _stopTime(Time).

%%_nodeValue(Node, 1)%%
	%%:-	_isMono(StartTime, Node),%%
		%%_startTime(StartTime).%%
%%_nodeValue(Node, 2)%%
	%%:-	_isAdd(StartTime, Node),%%
		%%_startTime(StartTime).%%
%%_nodeValue(Node, 3)%%
	%%:-	_isMul(StartTime, Node),%%
		%%_startTime(StartTime).%%
%%_nodeValue(Node, 4)%%
	%%:-	_isDiv(StartTime, Node),%%
		%%_startTime(StartTime).%%

%%_eqnTotal(Sum)	:- Sum = #count { Node : _isActive(_time(0,1), Node)} .%%
%%hash(@calcHash(Total))%%
	%%:-	_eqnTotal(Total).%%

% trying to generate problems with fewer zeroes
%%:-  2 { _isZero(StartTime, Node) : _node(Node) } , _startTime(StartTime).%%
%%_disallowedType(neg).%%
