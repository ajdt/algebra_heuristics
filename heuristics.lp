% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file defines heuristics used to solve algebra problems.
% The heuristics apply either a single rule or a sequence of
% the rules described in rules.lp
%
% Heuristics are defined by 3 properties: 
%	1. a trigger	-- a condition that when true indicates the heuristic should be applied 
%	2. A priority	-- A positive integer acting as a rank (lower number means higher rank)
%						to establish a partial ordering on heuristics. If multiple heuristics
%						apply, then we chose the heuristic with highest precedence breaking ties arbitrarily.
%	3. Action(s)	--	A rule or rules to be applied when the heuristic is to be performed
%
% Naturally, a heuristic must also have operands on which the actions are applied. These are obtained from
% the Trigger, which not only indicates that a condition holds, but also over which objects.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEFINING HEURISTICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: I've collapsed heuristics so they're the same thing as rules for 
% the sake of simplicity. Previously a rule just described applicable actions on an
% equation and heuristics encoded reasonable strategies.
%
% The reasonable strategies are now encoded at the level of rules. 

_heuristic(RuleName, RuleName) :- _rule(RuleName).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PERFORM THE SELECTED HEURISTIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_performRule(Time, _rule(HeurName, Oper))
	:-	_selectedHeuristic(Time, HeurName),
		_selectedHeurOperands(Time, Oper).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HEURISTIC STRATEGIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Each heuristic should be declared with a _rule() instance, 
% with applicable instances of the heuristic being declared as: 
%   _applicable(Time, _rule(HeuristicName, Operands))
% 
% the following declarations define the heuristics into strategies, and establish
% a partial ordering on the strategies too. 

%% heuristic categories
_heuristicCategory(cancel).
_heuristicCategory(combine).
_heuristicCategory(rearrange).
_heuristicCategory(move).
_heuristicCategory(expand).

_topPriority(cancel).

% (heuristicToTry, heuristicThatIsntApplicable)
_tryIfNotApplicable(combine, cancel).
_tryIfNotApplicable(rearrange, combine).
_tryIfNotApplicable(move, rearrange).
_tryIfNotApplicable(expand, move).

