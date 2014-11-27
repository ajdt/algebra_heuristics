% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file is used to generate contrasting cases problems.
% We mostly use the same files as eqn_generator, except we
% provide our own config parameters and don't use rule features.
% 
%

#include "prob_generator.lp".
#include "nodes.lp".
#include "polynomial.lp".
#include "eqn_solver.lp".
#include "rules.lp".
#include "math_operations.lp".
#include "heuristics.lp".
%%#include "rule_features.lp".%%

% monomial coefficient parameters
#const	maxInitialCoeff	=	5.
#const	maxCoeff		=	2*maxInitialCoeff.
#const	maxInitialDeg	=	2.
#const	maxDeg			=	2*maxInitialDeg.

% expression tree parameters
#const maxChildren	=	4.	% limit on children of operator nodes
#const maxInitialChildren	=	3. 	% limit on number of children a node can start with
#const maxDepth		=	3.	% limits number of layers used during generation
#const maxInitialDepth		=	2.	

% solver params
#const maxSteps = 1.
#const maxNumStreams	= 2.

% problem feature constraints 
:- _coeffOverflow.
:- _degOverflow.



% allow/disallow specific operators in initial expression.
% by default all types are allowed. To disallow a type use _disallowedType(Type)
%%_disallowedType(neg).%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EQN DIFFERENCES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% defines the difference between two problems at timestep = 0 
_initialTimeStep(0).

% defines a weighted penalty for two nodes at given depth having different values
_differencePenalty(Depth, Penalty)
	:-	_depthValue(Depth),
		Penalty = (maxDepth +1) - Depth.

% diferent type
_nodeDiff(Node, 2)% distinguish between what pair of times is being compared??
	:-	_node(Node),
		_startTime(FstTime),
		_startTime(SndTime),
		FstTime < SndTime,
		_hasType(FstTime, Node, FstType), 
		_hasType(SndTime, Node, SndType), 
		FstType != SndType.
% same type and both operators
_nodeDiff(Node, 0)
	:-	_node(Node),
		_startTime(FstTime),
		_startTime(SndTime),
		FstTime < SndTime,
		_hasType(FstTime, Node, Type), 
		_hasType(SndTime, Node, Type), 
		Type != mono.

% both monos, diff deg, 
_sameDegAcrossStreams(Node)
	:-	_node(Node),
		_startTime(FstTime),
		_startTime(SndTime),
		FstTime < SndTime,
		_degOf(FstTime, Node, Deg),
		_degOf(SndTime, Node, Deg).
_sameCoeffAcrossStreams(Node)
	:-	_node(Node),
		_startTime(FstTime),
		_startTime(SndTime),
		FstTime < SndTime,
		_coeffOf(FstTime, Node, Coeff),
		_coeffOf(SndTime, Node, Coeff).

% TODO: do something else if both deg and coeff are different??
_nodeDiff(Node, 1)
	:-	_node(Node),
		_startTime(FstTime),
		_startTime(SndTime),
		FstTime < SndTime,
		_isMono(FstTime, Node),
		_isMono(SndTime, Node),
		not _sameDegAcrossStreams(Node).
% both monos diff coeff, 
_nodeDiff(Node, 1)
	:-	_node(Node),
		_startTime(FstTime),
		_startTime(SndTime),
		FstTime < SndTime,
		_isMono(FstTime, Node),
		_isMono(SndTime, Node),
		not _sameCoeffAcrossStreams(Node).
% both monos identical
_nodeDiff(Node, 0)
	:-	_node(Node),
		_startTime(FstTime),
		_startTime(SndTime),
		FstTime < SndTime,
		_sameDegAcrossStreams(Node),
		_sameCoeffAcrossStreams(Node).
% one mono is active the other is not
_nodeDiff(Node, 3)
	:-	_node(Node),	
		_startTime(FstTime),
		_startTime(SndTime),	% NOTE: don't specify FstTime < SndTime, capture both cases in one rule
		_isActive(FstTime, Node),
		not _isActive(SndTime, Node).

_weightedNodeDiff(Node, Diff*Penalty)
	:-	_nodeDiff(Node, Diff),
		_nodeDepth(Node, Depth),
		_differencePenalty(Depth, Penalty).
	
_totalDifference(Sum)	:- Sum = #sum { Diff, _weightedNodeDiff: _weightedNodeDiff(Node, Diff), _node(Node)} .
#minimize { DiffSum@1, _total: _totalDifference(DiffSum) } .
%%:-	_totalDifference(X), X > 1.%%
