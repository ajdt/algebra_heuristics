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
%	3. Action(s)	--	A rule or rules to be applied when the rule is to be performed
%
% Naturally, a heuristic must also have operands on which the actions are applied. These are obtained from
% the Trigger, which not only indicates that a condition holds, but also over which objects.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SELECTING HEURISTICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
		not _heuristicToApplyRule(Name, Priority, Trigger). 

1 { _selectedHeurOperands(Time, Oper) : _applicable(Time, _rule(Trigger, Oper)) } 1
	:-	_selectedHeuristic(Time, Name),
		_heuristicToApplyRule(Name, Priority, Trigger). 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PERFORM THE SELECTED HEURISTIC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_performRule(Time, _rule(RuleToApply, Oper))
	:-	_selectedHeuristic(Time, Name),
		_selectedHeurOperands(Time, Oper),
		_heuristicAction(Name, RuleToApply).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MULTI-STEP HEURISTICS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
		StepNum > 1.

_performRule(Time, _rule(RuleToApply, Oper))
	:-	_performHeuristicStep(Time, Name, Step),
		_heuristicActionSequence(Name, RuleToApply, Step),
		_selectedHeurOperands(Time, Oper).
% TODO: way to selectHeurOperands for next time step??

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% heuristics that apply rules %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_heuristicAction(Name, Rule)
	:-	_heuristicToApplyRule(Name, Priority, Rule).
_heuristic(Name, Priority, Rule)
	:-	_heuristicToApplyRule(Name, Priority, Rule).
%%%================================================================================
%%%					Heuristic Definitions
%%%================================================================================

_heuristicToApplyRule(combineLikeTerms, 1, addMonom). 

_heuristic(factorSimpleQuad, 1, stdQuadSetToZero).
_heuristicAction(factorSimpleQuad, factor).

_applicable(Time, _condition(stdQuadSetToZero, _operands(leftSide)))
	:-	_isZero(Time, rightSide),
	_applicable(Time, _rule(factor, _operands(leftSide))).

:- not _selectedHeuristic(_time(0,1), factorSimpleQuad).


