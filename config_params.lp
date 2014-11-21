#const maxDeg = 2*maxInitialDeg.
#const maxInitialChildren = 3.
#const maxChildren = 4.
#const maxSteps = 1.
#const maxCoeff = 2*maxInitialCoeff.
#const maxNumStreams = 1.
#const maxDepth = 3.
#const maxInitialDeg = 2.
#const maxInitialDepth = 2.
#const maxInitialCoeff = 5.
:- _coeffOverflow.
:- _degOverflow.
:- not selectedHeuristic(_time(0,1), factorSimpleQuad).
