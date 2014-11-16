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
_performHeuristicStep(Time, Name, 1)
	:-	_selectedHeuristic(Time, Name),
		_heuristicActionSequence(Name, Action, 1).
_performHeuristicStep(NextTime, Name, NextStep)
	:-	_performHeuristicStep(Time, Name, Step),
		_nextTimeTick(Time, NextTime),
		NextStep = Step+1.

% prevent other heuristics from being selected
_previousHeuristicNotFinished(Time)
	:-	_performHeuristicStep(Time, Name, StepNum),
		StepNum > 1.	% at step 1, the current heuristic is selected, so don't generate predicate for step 1

_performRule(Time, _rule(RuleToApply, Oper))
	:-	_performHeuristicStep(Time, Name, Step),
		_heuristicActionSequence(Name, RuleToApply, Step),
		_selectedHeurOperands(Time, Oper).
% TODO: way to selectHeurOperands for next time step will depend on particular actions that are used

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
%%_heuristicToApplyRule(cancelAcrossEqn, 1, cancelSumTerm). %%
_heuristicToApplyRule(addInverses, 1, addInverses). 
_heuristicToApplyRule(ignoreDenom, 1, numerSimp). 
_heuristicToApplyRule(cancelCommTerms, 1, fracCancel). 
_heuristicToApplyRule(cancelNeg, 1, cancelNegatives). 

_heuristicToApplyRule(combineLikeTerms, 2, addMonom). 
_heuristicToApplyRule(additiveIdentity, 2, addZero). 
_heuristicToApplyRule(addFractions, 2, addSameFrac). 
_heuristicToApplyRule(divIdent, 2, divByOne). 
_heuristicToApplyRule(multiplyByZero, 2, multByZero). 
_heuristicToApplyRule(multiplyByOne, 2, multIdentity). 

_heuristicToApplyRule(applyDistribute, 3, distribute). 
_heuristicToApplyRule(multiplyMonoms, 3, monoMult). 

% 
_heuristic(factorSimpleQuad, 1, stdQuadSetToZero).
_heuristicAction(factorSimpleQuad, factor).

_applicable(Time, _condition(stdQuadSetToZero, _operands(leftSide)))
	:-	_isZero(Time, rightSide),
	_applicable(Time, _rule(factor, _operands(leftSide))).

%%:- not _selectedHeuristic(_time(0,1), factorSimpleQuad).%%
%%:- not _isZero(_time(0,1), rightSide).%%
%%:- not _applicable(_time(0,1), _rule(factor, _operands(leftSide))).%%
	%%:-	_isPolynomial(Time, Node),%%
		%%_isQuadratic(Time, Node),%%
		%%_isFactorable(Time, Node).%%

