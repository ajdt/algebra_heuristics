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

% expression tree parameters
#const maxChildren	=	4.	% limit on children of operator nodes
#const maxInitialChildren	=	2. 	% limit on number of children a node can start with
#const maxDepth		=	3.	% limits number of layers used during generation

% solver params
#const maxSteps = 2.
#const maxNumStreams	= 1.


% allow/disallow specific operators in initial expression.
% by default all types are allowed. To disallow a type use _disallowedType(Type)
%%_disallowedType(neg).%%
