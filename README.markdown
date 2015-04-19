Introduction
============
This project is an attempt to model expert-level human reasoning in solving
algebraic equations. Using this encoding we can then generate problems with
specific characteristics such as using a specific set of solving techniques (hereafter called
heuristics), having a certain solution length, etc. 

The code provided serves the following functions
1. encode a description of what algebra problems look like
2. encode basic manipulation rules for algebra problems (NOTE: basic rules are no longer encoded!)
3. encode human solving techniques (heuristics)
4. generate algebra problems having certain characteristics
5. generate a step-by-step nominal solution to a given algebra problem


Bash and Python Files
=====================
Note: this project supports doxygen documentation 
(load up doc/html/index.html in a browser).

ASP Files
=========
* config\_params.lp		--	contains declared constants that limit size of expression trees, and affect solver run time
* eqn\_generator.lp		-- a 'header' file that includes all other relevant .lp files
* prob\_generator.lp    -- generates an arbitrary algebra problem.
* eqn\_solver.lp		--	selects applicable rules or heuristics to produce a solution for generated algebra problem
* math\_operations.lp	--	code used by algebra rewrite rules to modify expression tree when a rule is applied to it
* nodes.lp				--	defines nodes, which make up expression trees, and operations on them
* polynomial.lp			--	defines operations, and properties specifically having to do with polynomials
* rules.lp				-- encodes algegbra heuristics. NOTE: this file no longer contains rule implementations, just heuristics.
* heuristics.lp         -- contains logic to organize heuristics into classes of strategies, logic to select an operation, and to generate 'strategy explanations' for selected operation


Algebraic Equation Encoding
===========================
Algebra equations are encoded as an expression tree. "nodes.lp" defines a set of node/1 predicates which serve as nodes
for this expression tree. A fixed tree structure is declared in "nodes.lp" independent of the type of equation to be
generated. Constraints exist in nodes.lp and other files to ensure that we don't exceed the number of nodes allotted by
the fixed structure. A node is either an operator node (div, mul, add) or a monomial node having a degree and coefficient.
Monomial nodes are leaves of the tree.

Each node has an associated temp node. Temp nodes are mainly used to store the result of some rewrite rule, or intermediate results.
This makes managing nodes simpler b/c we don't have to manipulate the existing expression tree on a rewrite. Instead
we save a resulting subtree with temp nodes, and then perform a copy to place the new subtree in the correct part of the 
expression tree. 

Installation Dependencies
=========================
* Python modules
    1. tempfile
    2. antlr4
    3. argparse
    4. json
    5. sympy
    6. pyparsing 
    7. clingo
    8. pygraphviz
* antlr4 
    * version 4.4
        * see the instructions at (https://theantlrguy.atlassian.net/wiki/display/ANTLR4/Python+Target)
* clingo 
    * version 4.3
        * (can be downloaded from: http://potassco.sourceforge.net/)

