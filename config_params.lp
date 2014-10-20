% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file contains most of the constants required to generate 
% equations. I've treated it kind of like a header file in C++.
% Any parameters I intent to be configurable will be placed here.
% Constants in other files should not be changed!
%

% monomial coefficient parameters
#const	maxInitialCoeff	=	5.
#const	maxCoeff		=	2*maxInitialCoeff.
#const	maxInitialDeg	=	2.
#const	maxDeg			=	2*maxInitialDeg.

#const	maxInitialSquareCoeff	=	3.
#const	maxInitialLinearCoeff	=	maxInitialCoeff.
#const	maxInitialConstCoeff	=	maxInitialCoeff.


% expression tree parameters
#const maxChildren	=	2.	% limit on children of operator nodes
#const maxDepth		=	3.	% limits number of layers used during generation

% node definition constants
#const numNodeLayers 	=	maxDepth.

% solver params
#const maxSteps = 2.
#const maxNumStreams	= 2.
#const minNumStreams	= 2.	% min number of distinct solutions problem must have


% problem feature constraints 
:- _coeffOverflow.
:- _degOverflow.
