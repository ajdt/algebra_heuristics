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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SELECTING HEURISTICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Heuristics can have one of two types of triggers.
% rule heuristics 		-- apply whenever a rule is applicable
% condition heuristics	-- apply when other conditions not captured by rules are applicable

_applicableHeuristic(Time, Name)
	:-	_heuristic(Name, Priority, Trigger),
		_applicable(Time, _condition(Trigger, Operands)).	% triggers can be conditions...
_applicableHeuristic(Time, Name)
	:-	_heuristic(Name, Priority, Trigger),
		_applicable(Time, _rule(Trigger, Operands)).		% ... or they can be rules


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SELECTING OPERANDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Once a heuristic is selected, we must select operands to apply that heuristic
% NOTE: two versions needed because some heuristics have complicated conditions
% while others only require that a particular rule be applicable 

1 { _selectedHeurOperands(Time, Oper) : _applicable(Time, _condition(Trigger, Oper)) } 1
	:-	_selectedHeuristic(Time, Name),
		_heuristic(Name, Priority, Trigger),
		not _heuristicToApplyRule(Name, Priority, Trigger). 	% condition heuristic

1 { _selectedHeurOperands(Time, Oper) : _applicable(Time, _rule(Trigger, Oper)) } 1
	:-	_selectedHeuristic(Time, Name),
		_heuristicToApplyRule(Name, Priority, Trigger). 		% rule heuristic

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PERFORM THE SELECTED HEURISTIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_performRule(Time, _rule(RuleToApply, Oper))
	:-	_selectedHeuristic(Time, Name),
		_selectedHeurOperands(Time, Oper),
		_heuristicAction(Name, RuleToApply).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MULTI-STEP HEURISTICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: this code may be removed later. It's possible all multistep heuristics
% can be written as single step heuristics depending on how priorities are assigned
%%_performHeuristicStep(Time, Name, 1)%%
	%%:-	_selectedHeuristic(Time, Name),%%
		%%_heuristicActionSequence(Name, Action, 1).%%
%%_performHeuristicStep(NextTime, Name, NextStep)%%
	%%:-	_performHeuristicStep(Time, Name, Step),%%
		%%_nextTimeTick(Time, NextTime),%%
		%%NextStep = Step+1.%%

%%% prevent other heuristics from being selected%%
%%_previousHeuristicNotFinished(Time)%%
	%%:-	_performHeuristicStep(Time, Name, StepNum),%%
		%%StepNum > 1.	% at step 1, the current heuristic is selected, so don't generate predicate for step 1%%

%%_performRule(Time, _rule(RuleToApply, Oper))%%
	%%:-	_performHeuristicStep(Time, Name, Step),%%
		%%_heuristicActionSequence(Name, RuleToApply, Step),%%
		%%_selectedHeurOperands(Time, Oper).%%
%%% TODO: way to selectHeurOperands for next time step will depend on particular actions that are used%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HEURISTICS THAT APPLY RULES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To define a rule heuristic, simply define _heuristicToApplyRule/3 as below.
% The following rules extract additional heuristic predicates that are needed
_heuristicAction(Name, Rule)
	:-	_heuristicToApplyRule(Name, Priority, Rule).
_heuristic(Name, Priority, Rule)
	:-	_heuristicToApplyRule(Name, Priority, Rule).

%%%================================================================================
%%%					Heuristic Definitions
%%%================================================================================

% NOTE: I've reserved priority = 0 for testing purposes. O.W. highest priority is 1 
% combine monomials
%%_heuristicToApplyRule(areTermsThatCanBeCancelled, 1, areTermsThatCanBeCancelled). %%
%%_heuristicToApplyRule(addUpToZero, 1, addUpToZero). %%
%%_heuristicToApplyRule(soTheNumeratorOfThisFractionMustBeEqualToZero, 1, soTheNumeratorOfThisFractionMustBeEqualToZero). %%
%%_heuristicToApplyRule(areFactorsThatCancel, 1, areFactorsThatCancel). %%
%%_heuristicToApplyRule(areBothNegativeOperationsThatCancelOut, 1, areBothNegativeOperationsThatCancelOut). %%

%%_heuristicToApplyRule(canBeAddedTogether, 2, canBeAddedTogether). %%
%%_heuristicToApplyRule(canBeCancelled, 2, canBeCancelled). %%
%%_heuristicToApplyRule(canBeAddedAsOneFraction, 2, canBeAddedAsOneFraction). %%
%%_heuristicToApplyRule(canHaveItsDenominatorCancelled, 2, canHaveItsDenominatorCancelled). %%
%%_heuristicToApplyRule(isEqualToZero, 2, isEqualToZero). %%
%%_heuristicToApplyRule(canBeIgnored, 2, canBeIgnored). %%

%%_heuristicToApplyRule(canBeDistributed, 3, canBeDistributed). %%
%%_heuristicToApplyRule(canBeMultipliedTogether, 3, canBeMultipliedTogether). %%
%%_heuristicToApplyRule(decreaseDeg, 3, decreaseDeg). %%
%%_heuristicToApplyRule(fractionCanBeMultipliedWithNonFraction, 3, fractionCanBeMultipliedWithNonFraction). %%

%%%================================================================================
%%%					Condition Heuristics
%%%================================================================================

		%% isolate variables to lhs
%%_heuristic(isolateVars, 3, rhsHasVariable).%%
%%_heuristicAction(isolateVars, canBeSubtractedFromTheEquation).%%

%%_applicable(Time, _condition(rhsHasVariable, _operands(Child)))%%
	%%:-	_isSumOfTerms(Time, rightSide),%%
		%%_isATermOf(Time, rightSide, Child),%%
		%%_hasVariable(Time, Child).%%

%%_hasVariable(Time, Node)%%
	%%:- _isTheDegreeOf(Time, Node, Deg),%%
		%%Deg > 0.%%
%%_hasVariable(Time, Parent)%%
	%%:-	_isATermOf(Time, Parent, Child),%%
		%%_hasVariable(Time, Child).%%

%%_sideOf(leftSide,left;rightSide,right).%%
%%_sideOf(Child, Side)%%
	%%:-	_validChildOf(Parent, Child),%%
		%%_sideOf(Parent, Side).%%

		%%[> move constants to rhs if eqn is linear%%
%%_heuristic(isolateConst, 3, lhsHasConst).%%
%%_heuristicAction(isolateConst, canBeSubtractedFromTheEquation).%%

%%_applicable(Time, _condition(lhsHasConst, _operands(Child)))%%
	%%:-	_hasSuperlinearTerms(Time),%%
		%%_isSumOfTerms(Time, leftSide),%%
		%%_isATermOf(Time, leftSide, Child),%%
		%%_isConstant(Time, Child). % TODO: update to move rationals also%%
	
%%_hasSuperlinearTerms(Time)%%
	%%:- _isTheDegreeOf(Time, Node, Deg),  Deg >= 2.%%

		%%[> set lhs to zero if eqn has super-linear terms%%
		%%% NOTE: this only subtracts rhs from both sides: other heuristics must simplify%%
%%_heuristic(setRHSZero, 3, rhsIsNotZero).%%
%%_heuristicAction(setRHSZero, canBeSubtractedFromTheEquation).%%
%%_applicable(Time, _condition(rhsIsNotZero, _operands(rightSide)))%%
	%%:-	_hasSuperlinearTerms(Time),%%
		%%not _isZero(Time, rightSide).%%

		%%[> factor quadratic to solve eqn%%
%%_heuristic(factorSimpleQuad, 1, stdQuadSetToZero).%%
%%_heuristicAction(factorSimpleQuad, canBeFactored).%%

%%_applicable(Time, _condition(stdQuadSetToZero, _operands(leftSide)))%%
	%%:-	_isZero(Time, rightSide),%%
		%%_applicable(Time, _rule(canBeFactored, _operands(leftSide))).%%



%%%================================================================================
%%%					Misc Rule Heuristics
%%%================================================================================
% any rules not explicitly given higher priority are given the lowest priority possible
% This repesents the idea that when we don't how to proceed, we try any rule that's
% applicable

#const defaultRulePriority = 5.

_ruleAlreadyHasHigherPriority(RuleName) 
	:-	_heuristic(HeurName, Priority, RuleName),
		_rule(RuleName),
		Priority < defaultRulePriority. 

_heuristicToApplyRule(RuleName, defaultRulePriority, RuleName)
	:-	_rule(RuleName),
		not _ruleAlreadyHasHigherPriority(RuleName).


% TODO: fix this bug
%%:- not _numActiveChildren(_time(0,1), leftSide, 3).%%

%%:- not _numActiveChildren(_time(0,1), leftSide, 3).%%
%%:- not _selectedHeuristic(_time(0,1), cancelAcrossEqn).%%
%%:- not _selectedHeuristic(_time(1,1), factorSimpleQuad).%%
%%:-	not _isPolynomial(_time(0,1), leftSide).%%
