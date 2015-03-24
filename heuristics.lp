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
_heuristicToApplyRule(weCanSimplifyByCancellingTheseTerms, 1, weCanSimplifyByCancellingTheseTerms). 
_heuristicToApplyRule(addUpToZero, 1, addUpToZero). 
_heuristicToApplyRule(soTheNumeratorOfThisFractionMustBeEqualToZero, 1, soTheNumeratorOfThisFractionMustBeEqualToZero). 
_heuristicToApplyRule(weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator, 1, weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator). 
_heuristicToApplyRule(areBothNegativeOperationsThatCancelOut, 1, areBothNegativeOperationsThatCancelOut). 

_heuristicToApplyRule(weCanSimplifyByAddingTheseTwoTermsTogether, 2, weCanSimplifyByAddingTheseTwoTermsTogether). 
_heuristicToApplyRule(weCanSimplifyByCancellingTheZero, 2, weCanSimplifyByCancellingTheZero). 
_heuristicToApplyRule(weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction, 2, weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction). 
_heuristicToApplyRule(weCanSimplifyByCancellingTheDenominatorOfThisFraction, 2, weCanSimplifyByCancellingTheDenominatorOfThisFraction). 
_heuristicToApplyRule(theProductOfTheseTermsIsZero, 2, theProductOfTheseTermsIsZero). 
_heuristicToApplyRule(weCanSimplifyByCancellingTheOne, 2, weCanSimplifyByCancellingTheOne). 

_heuristicToApplyRule(weCanSimplifyByDistributingTheSingleFactor, 3, weCanSimplifyByDistributingTheSingleFactor). 
_heuristicToApplyRule(weCanSimplifyByCombiningTheseIntoASingleTerm, 3, weCanSimplifyByCombiningTheseIntoASingleTerm). 
_heuristicToApplyRule(weCanSimplifyBySubstitutingYForFACTORA, 3, weCanSimplifyBySubstitutingYForFACTORA). 
_heuristicToApplyRule(weCanSimplifyByMultiplyingTheNumeratorByTheTerm, 3, weCanSimplifyByMultiplyingTheNumeratorByTheTerm). 

%%%================================================================================
%%%					Condition Heuristics
%%%================================================================================

		%% isolate variables to lhs
%%_heuristic(isolateVars, 3, rhsHasVariable).%%
%%_heuristicAction(isolateVars, weCanSimplifyBySubtractingTheTermFromBothSides).%%

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
%%_heuristicAction(isolateConst, weCanSimplifyBySubtractingTheTermFromBothSides).%%

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
%%_heuristicAction(setRHSZero, weCanSimplifyBySubtractingTheTermFromBothSides).%%
%%_applicable(Time, _condition(rhsIsNotZero, _operands(rightSide)))%%
	%%:-	_hasSuperlinearTerms(Time),%%
		%%not _isZero(Time, rightSide).%%

		%%[> factor quadratic to solve eqn%%
%%_heuristic(factorSimpleQuad, 1, stdQuadSetToZero).%%
%%_heuristicAction(factorSimpleQuad, weCanSimplifyByFactoringThisExpression).%%

%%_applicable(Time, _condition(stdQuadSetToZero, _operands(leftSide)))%%
	%%:-	_isZero(Time, rightSide),%%
		%%_applicable(Time, _rule(weCanSimplifyByFactoringThisExpression, _operands(leftSide))).%%



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

%% heuristic categories
_heuristicCategory(cancelHeuristic).
_heuristicCategory(combineHeuristic).
_heuristicCategory(recombineHeuristic).
_heuristicCategory(rearrangeHeuristic).
_heuristicCategory(miscHeuristic).

_topPriority(cancelHeuristic).

% (heuristicToTry, heuristicThatIsntApplicable)
_tryIfNotApplicable(combineHeuristic, cancelHeuristic).
_tryIfNotApplicable(recombineHeuristic, combineHeuristic).
_tryIfNotApplicable(rearrangeHeuristic, recombineHeuristic).
_tryIfNotApplicable(miscHeuristic, rearrangeHeuristic).

% selecting the highest applicable category!!
_applicableCategory(Time, Category)
    :-  _applicableHeuristic(Time, HeurName),
        _theCategoryOfHeuristicIs(HeurName, Category).

_highestApplicableCategory(Time, Category)
    :-  _topPriority(Category),
        _applicableCategory(Time, Category).
_noCategoryAppliesUpTo(Time, Category)
    :-  _topPriority(Category),
        __validTime(Time),
        not _applicableCategory(Time, Category).

_noCategoryAppliesUpTo(Time, CategoryToTry)
    :-  _noCategoryAppliesUpTo(Time, Category),
        _tryIfNotApplicable(CategoryToTry, Category),
        not _applicableCategory(Time, CategoryToTry).

_highestApplicableCategory(Time, CategoryToTry)
    :-  _noCategoryAppliesUpTo(Time, Category),
        _tryIfNotApplicable(CategoryToTry, Category),
        _applicableCategory(Time, CategoryToTry).

%%% subtree sizes
_subtreeSize(Time, Mono, 1)
    :-  __isMono(Time, Mono).

_sizeOfChildSubtree(Time, Node, Child, Size)
    :-  _subtreeSize(Time, Child, Size),
        _isATermOf(Time, Node, Child).
_subtreeSize(Time, Node, SubtreeSize)
    :-  _isOper(Time, Node),
        SubtreeSize = #sum { Size,Child: _sizeOfChildSubtree(Time, Node, Child, Size)}.

%%% selecting based on subtree size

% associate size with each operation of highest category
_sizeOfSubExpressionsForHeuristicApplication(Time, _rule(Heuristic, _operands(LeftOper, RightOper)), LeftSize)
    :-  _applicable(Time, _rule(Heuristic, _operands(LeftOper, RightOper))),
        _subtreeSize(Time, LeftOper, LeftSize),
        _subtreeSize(Time, RightOper, RightSize),
        _highestApplicableCategory(Time, HighestCategory),
        _theCategoryOfHeuristicIs(Heuristic, HighestCategory).

_sizeOfSubExpressionsForHeuristicApplication(Time, _rule(Heuristic, _operands(LeftOper)), LeftSize)
    :-  _applicable(Time, _rule(Heuristic, _operands(LeftOper))),
        _subtreeSize(Time, LeftOper, LeftSize),
        _highestApplicableCategory(Time, HighestCategory),
        _theCategoryOfHeuristicIs(Heuristic, HighestCategory).

% find largest operand size for current time step
_sizeOfPossibleOperandForTimeStep(Time, Size)
    :-  _sizeOfSubExpressionsForHeuristicApplication(Time, HeurApp, Size).

_largestSubexpressionForTimeStep(Time, Max)
    :-  __validTime(Time), not _stopTime(Time),
        Max = #max { Size : _sizeOfPossibleOperandForTimeStep(Time, Size) }.

% select a heuristic application of the selected strategy
% and that has the largest size operands possible
1 { _alternateSelectedHeuristic(Time, _rule(HeurName, Oper)) : 
        _sizeOfSubExpressionsForHeuristicApplication(Time, _rule(HeurName, Oper), Size),
        _theCategoryOfHeuristicIs(HeurName, HighestCategory),
        _highestApplicableCategory(Time, HighestCategory),
        _largestSubexpressionForTimeStep(Time, Size)
    } 1
    :-  __validTime(Time), not _stopTime(Time).

