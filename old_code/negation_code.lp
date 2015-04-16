% This file contains all the negation rules, which 
% are only useful if we include an explicit negation operator
%================================================================================
% cancelNegatives: -(-A) --> A
%================================================================================
_applicable(Time, _rule(areBothNegativeOperationsThatCancelOut, _operands(Parent, Child)))
	:-	_isATermOf(Time, Parent, Child),
		_isNeg(Time, Parent),
		_isNeg(Time, Child).

_deepCopy(Time, GrandParent, GrandChild)
	:-	_operand(Time, GrandParent, areBothNegativeOperationsThatCancelOut, left),
		_operand(Time, Parent, areBothNegativeOperationsThatCancelOut, right),
		_isATermOf(Time, Parent, GrandChild).

%================================================================================
% distributeNegative: -(a + b) --> -a - b
%================================================================================
_applicable(Time, _rule(negationCanBeDistributed, _operands(Node, Node)))
	:-	_isASingleTermOrSumOfTerms(Time, Node),
		_isBeingNegated(Time, Node).

			%%% negating nodes
% mono case
_setTempNodeToMono(Time, tempResultRoot, Deg, NegatedCoeff)
	:-	_operand(Time, RootNode, negationCanBeDistributed, left),
		__isMono(Time, RootNode),
		_isTheCoefficientOf(Time, RootNode, Coeff),
        NegatedCoeff = Coeff*-1,
		_isTheDegreeOf(Time, RootNode, Deg).
% add operator case
_treeOp(Time, tempResultRoot, RootNode, RootNode, negateChildren)
	:-	_operand(Time, RootNode, negationCanBeDistributed, left),
		_isSumOfTerms(Time, RootNode).
    
% save the result
_setResultTo(Time, Parent)
	:-	_operand(Time, RootNode, negationCanBeDistributed, left),
		_isATermOf(Time, Parent, RootNode).
%================================================================================
% negativeSignCanBePassedToChildOf:          -(a*b*c) --> -a*b*c
%================================================================================
_applicable(Time, _rule(negativeSignCanBePassedToTermOf, _operands(Node, Child)))
	:-	_mulOrDiv(Time, Node),
		_isBeingNegated(Time, Node),
		_isATermOf(Time, Node, Child).
% div or mul case
_treeOp(Time, tempResultRoot, RootNode, Child, negateSingleChild)
	:-	_operand(Time, RootNode, negativeSignCanBePassedToTermOf, left),
		_operand(Time, Child, negativeSignCanBePassedToTermOf, right),
		_mulOrDiv(Time, RootNode).

% save the result
_setResultTo(Time, Parent)
	:-	_operand(Time, RootNode, negativeSignCanBePassedToTermOf, left),
		_isATermOf(Time, Parent, RootNode).

%================================================================================
% addInverses: A + -A --> 0 
%================================================================================
_applicable(Time, _rule(addUpToZero, _operands(SndSibling, FstSibling)))
	:-	_areBeingAdded(Time, FstSibling, SndSibling),
		_isNeg(Time, SndSibling),
		_isATermOf(Time, SndSibling, Child),
		_areEqual(Time, FstSibling, Child).

% we know the result is zero, writeBinaryOp handles the rewrite 
_setTempNodeToMono(Time, tempResultRoot, 0, 0)	
	:-	_ruleForTimeStep(Time, addUpToZero).
_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, addUpToZero).

_rule(areBothNegativeOperationsThatCancelOut).
_rule(negationCanBeDistributed).
_rule(negativeSignCanBePassedToTermOf).
_rule(addUpToZero).
