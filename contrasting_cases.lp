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


