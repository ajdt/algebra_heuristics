Introduction
============
This project is an attempt to model expert-level human reasoning in solving
algebraic equations. Using this encoding we can then generate problems with
specific characteristics such as using a specific set of solving techniques (hereafter called
heuristics), having a certain solution length, etc. 

The code provided serves the following functions
1. encode a description of what algebra problems look like
2. encode basic manipulation rules for algebra problems
3. encode human solving techniques (heuristics)
4. generate algebra problems having certain characteristics
5. generate a step-by-step nominal solution to a given algebra problem


Files
=====
* config\_params.lp		--	contains declared constants that limit size of expression trees, and affect solver run time
* eqn\_generator.lp		--	generates algebra problems. Note: to generate problems with specific properties, must run eqn\_solver too
* eqn\_solver.lp		--	selects applicable rules or heuristics to produce a solution for generated algebra problem
* math\_operations.lp	--	code used by algebra rewrite rules to modify expression tree when a rule is applied to it
* nodes.lp				--	defines nodes, which make up expression trees, and operations on them
* polynomial.lp			--	defines operations, and properties specifically having to do with polynomials
* rules.lp				--	Basic algebra rules. Each rule defines conditions under which it applies and actions performed
							if the rule is selected.


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
