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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HEURISTIC SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% a heuristic is applicable if it's trigger is applicable
% (Name = Trigger in my application, but they may be different
_applicableHeuristic(Time, Name)
	:-	_heuristic(Name, Trigger),
		_applicable(Time, _rule(Trigger, Operands)).		

% selecting the highest applicable category!!
_applicableCategory(Time, Category)
    :-  _applicableHeuristic(Time, HeurName),
        _theCategoryOfHeuristicIs(HeurName, Category).

%%% finding the highest applicable category
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
1 { _selectedHeuristicInstance(Time, _rule(HeurName, Oper)) : 
        _sizeOfSubExpressionsForHeuristicApplication(Time, _rule(HeurName, Oper), Size),
        _theCategoryOfHeuristicIs(HeurName, HighestCategory),
        _highestApplicableCategory(Time, HighestCategory),
        _largestSubexpressionForTimeStep(Time, Size)
    } 1
    :-  __validTime(Time), not _stopTime(Time).

% NOTE: necessary for compatibility with old heuristic selection code
_selectedHeuristic(Time, HeurName)
    :-  _selectedHeuristicInstance(Time, _rule(HeurName, Oper)).
_selectedHeurOperands(Time, Oper)
    :-  _selectedHeuristicInstance(Time, _rule(HeurName, Oper)).

