% heuristics have priorities, conditions, and associated actions
% associated actions are the application of rules to trees

% heuristic will look like:
% 	if _some_condition is true for node N1:
%		apply_rule(R1 to Node N1) at time step T
%		apply another rule at next time step
%		...
%		indicate heuristic is done executing
%		
%		

% we will be classifying problems based on heuristics traces
% 

% heuristic name, condition:
% condition for heuristic is same as condition for rules, so where should condition go?
% (name, precedence, condition
_heuristic(combineLikeTerms, 1, _applicableRule(addMonom)).

% action if rule applies
_performRule(Time, RuleToApply)
	:-	_selectedHeuristic(Time, _heuristicInstance(combineLikeTerms, RuleToApply)).

% TODO: change so rule to apply is decoupled from heuristic to use. Create isApplicable() predicate for heuristics,
% use anywhere full heuristic instance isn't needed 

% if a heuristic must run for multiple steps it must generate _multiStepHeuristicNotFinished(Time) for each such time step

% basic heuristics only have conditions that a rule apply
_applicableHeuristic(Time, _heuristicInstance(HeuristicName, RuleToApply))
	:-	_heuristic(HeuristicName, Priority, _applicableRule(RuleName)),
		_applicable(Time, _rule(RuleName, Operands)),
		RuleToApply = _rule(RuleName, Operands).


% with this scheme, only change to solver is to select heuristics instead of rules. A heuristic must
% also be selected only when another one isn't still active

% Also: keep  integrity constraints

:- not _ruleForTimeStep(_time(0,1), addMonom).

% heuristics next steps
%%change eqn_solver to take precedence into account%%
%%write multi-step heuristics to ensure they work as expected%%
%%find any heuristics with additional requirements, and implement them too%%
%%examine grounding size again. Don't want grounding to get too large.%%
