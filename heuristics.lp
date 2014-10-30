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
1 { _performRule(Time, _rule(RuleName, Operands) ) :  _applicable(Time, _rule(RuleName, Operands))} 1
	:-	_selectedHeuristic(Time, HeuristicName),
		_heuristic(HeuristicName, Priority, _applicableRule(RuleName)).

% TODO: change so rule to apply is decoupled from heuristic to use. Create isApplicable() predicate for heuristics,
% use anywhere full heuristic instance isn't needed 

% if a heuristic must run for multiple steps it must generate _multiStepHeuristicNotFinished(Time) for each such time step

% basic heuristics only have conditions that a rule apply
_applicableHeuristic(Time, HeuristicName)
	:-	_heuristic(HeuristicName, Priority, _applicableRule(RuleName)),
		_applicable(Time, _rule(RuleName, Operands)),
		RuleToApply = _rule(RuleName, Operands).


:- not _selectedHeuristic(_time(0,1), isolateVariables).

% heuristics next steps
%% XX change eqn_solver to take precedence into account%%
%% write multi-step heuristics to ensure they work as expected%%
%% find any heuristics with additional requirements, and implement them too%%
%% examine grounding size again. Don't want grounding to get too large.%%

% heuristic: move all variable terms to one side
_sideOf(leftSide, left).
_sideOf(rightSide, right).
_sideOf(Child, Side)
	:-	_sideOf(Parent, Side),
		_validChildOf(Parent, Child).
		
_hasVariable(Time, Node)
	:-	_isMono(Time, Node),
		not _isConstant(Time, Node).

_hasVariable(Time, Node)
	:-	_isOper(Time, Node),
		_activeChild(Time, Node, Child),
		_hasVariable(Time, Child).
	
_condition(Time, variableTermsOnBothSides)
	:-	_hasVariable(Time, rightSide),
		_hasVariable(Time, leftSide).

_heuristic(isolateVariables, 2, _condition(variableTermsOnBothSides)).

_applicableHeuristic(Time, HeuristicName)
	:-	_heuristic(HeuristicName, Priority, _condition(ConditionName)),
		_condition(Time, ConditionName).

1 { _moveToLHS(Time, Node) : _hasVariable(Time, Node), _isMono(Time, Node), _sideOf(Node, right) } 1
	:-	_selectedHeuristic(Time, isolateVariables).
% _moveToLHS should be subtract polynomial from equations
_selectedDeg(Time, Deg)
	:-	_moveToLHS(Time, Node),
		_degOf(Time, Node, Deg).
_selectedCoeff(Time, Coeff)
	:-	_moveToLHS(Time, Node),
		_coeffOf(Time, Node, Coeff).
_performRule(Time, _rule(addMonoToEqn, _operands(leftSide, rightSide)))
	:-	_moveToLHS(Time, Node).

% define some idea of phases or heuristic time steps??
% NEED TO FIGURE OUT HOW TO SEQUENCE A LIST OF STEPS FOR A HEURISTIC
_addTheCommonTermsOnRHS(Time, Node)
	:-	_selectedHeuristic(Time, isolateVariables),
	_moveToLHS(Time, Node).

%%_selectedHeuristic(Time, Heuristic),%%

% TODO: heuristic not done, next step is to add the common terms
% also need rule to flatten terms?



% TODO: change rule to subtract existing subtree!!

% side of node really makes a difference now

% NOTE: these conditions are temporary so I can get the simplest versions of these rules working and debugged
:- not _isPolynomial(_time(0,1), leftSide).
:- not _isPolynomial(_time(0,1), rightSide).
