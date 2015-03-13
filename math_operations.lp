%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SETTING NODE TO 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_setToMono(Time, Node, 0, 1)
	:-	_setToOne(Time, Node).
_setToMono(Time, Node, 0, 0)
	:-	_setToZero(Time, Node).
_setToMono(Time, Node, 0, -1)
	:-	_setToNegOne(Time, Node).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SETTING RESULT OF BINARY OPERATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% XXX: assumes each time step we're setting only using setResultTo(...) at most once
% NOTE: 2-ary version ignore RightPoly to limit grounding size; still works correctly
% XXX: assumes LeftOper < RightOper. Ensure this is the case.

% isolate the "left/right" operands
_writeBinaryLeft(Time, LeftOper)
	:-	_writeBinaryOp(Time, LeftOper, RightOper).
_writeBinaryRight(Time, RightOper)
	:-	_writeBinaryOp(Time, LeftOper, RightOper).

% determine whether to set result to root node or left node
_setResultTo(Time, Root)	
	:-	_writeBinaryLeft(Time, LeftOper),
		_hasTwoTerms(Time, Root),	
		_isATermOf(Time, Root, LeftOper).
_setResultTo(Time, LeftOper)
	:-	_writeBinaryLeft(Time, LeftOper),
		not _hasTwoTerms(Time, Root),
		_isATermOf(Time, Root, LeftOper).

% cancel unneeded terms
_shiftDownTerms(Time, RightOper)
	:-	_writeBinaryRight(Time, RightOper).
% NOTE: don't need to explicitly delete leftOper b/c deepCopy will remove all children of Root
_deepCopy(Time, Root, tempResultRoot)
	:-	_setResultTo(Time, Root).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% tree operations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: assumes only one tree operation is to be stored in each Dest
% TODO: can we avoid generating treeOp/5 all together?
_treeOp(Time, Dest, Left, left)
	:-	_treeOp(Time, Dest, Left, Right, Op).
_treeOp(Time, Dest, Right, right)
	:-	_treeOp(Time, Dest, Left, Right, Op).
_treeOp(Time, Dest, Op)
	:-	_treeOp(Time, Dest, Left, Right, Op).

_binaryMathOperation(add;mul;div).

% treemult, treeadd, treediv: these are all binary operations
_activateTempAndSetChildren(Time, Temp, Oper, 2)
	:-	_treeOp(Time, Temp, Oper),
		_binaryMathOperation(Oper).
_deepCopy(Time, TempChild, Node)
	:-	_treeOp(Time, Temp, Oper),
		_binaryMathOperation(Oper),
		_treeOp(Time, Temp, Node, Side),
		_tempChildOnSide(Temp, TempChild, Side).

	%%% append treeOps
% NOTE: An append tree Op tries to create a result that appends 'right' node to 'left' node
% 	if possible. Otherwise, it reverts to a typical treeOp.
_appendable(Time, Dest)
	:-	_treeOp(Time, Dest, append(Oper)),
		_treeOp(Time, Dest, Left, left),
		_hasType(Time, Left, Oper),
		_numActiveChildren(Time, Left, NumActive),
		_maxNumChildren(Left, MaxChildren),
		NumActive < MaxChildren.

% if not appendable, then just do the regular treeOp
_treeOp(Time, Dest, Oper)	% we've already unpacked the operands so it's enough to declare this
	:-	_treeOp(Time, Dest, append(Oper)),
		not _appendable(Time, Dest).
% handle the append
_deepCopy(Time, Dest, Left)
	:-	_appendable(Time, Dest),
		_treeOp(Time, Dest, append(Oper)),
		_treeOp(Time, Dest, Left, left).
_appendedChild(Time, Dest, NewChild)
	:-	_appendable(Time, Dest),
		_treeOp(Time, Dest, append(Oper)),
		_treeOp(Time, Dest, Left, left),
		_numActiveChildren(Time, Left, Num),
		_tempChildNum(Dest, NewChild, Num+1).
_activateChild(Time, Dest, NewChild)
	:-	_appendedChild(Time, Dest, NewChild).
_deepCopy(Time, NewChild, Right)
	:-	_appendedChild(Time, Dest, NewChild),
		_treeOp(Time, Dest, append(Oper)),
		_treeOp(Time, Dest, Right, right).

% set to fraction, deep copy
_activateTempAndSetChildren(Time, Temp, div, 2)
	:-	_treeOp(Time, Temp, reciprocal).
_deepCopy(Time, TempChild, Node)
	:-	_treeOp(Time, Temp, reciprocal),
		_treeOp(Time, Temp, Node, Side),
		_tempChildOnSide(Temp, TempChild, OtherSide),
		Side != OtherSide. % ensure 'left' child gets copied to 'right' and vice versa

% negate children. Copy root node, and set child ptrs, but don't copy child subtrees
_copyAttribAndChildPtrStructure(Time, Dest, RootNode)
	:-	_treeOp(Time, Dest, RootNode, RootNode, negateChildren).
_treeOp(Time, TempChild, Child, Child, negate)
	:-	_treeOp(Time, Dest, RootNode, RootNode, negateChildren),
		_isATermOf(Time, RootNode, Child),
		_childNum(RootNode, Child, ChildNum),
		_tempChildNum(Dest, TempChild, ChildNum).
% negate single child
_copyAttribAndChildPtrStructure(Time, Dest, RootNode)
	:-	_treeOp(Time, Dest, RootNode, left),
		_treeOp(Time, Dest, negateSingleChild).
_deepCopy(Time, TempChild, Child)	% deepCopy all children that aren't negated
	:-	_treeOp(Time, Dest, RootNode, left),
		_treeOp(Time, Dest, negateSingleChild),
		_treeOp(Time, Dest, NegatedNode, right),
		_isATermOf(Time, RootNode, Child), Child != NegatedNode,
		_childNum(RootNode, Child, ChildNum),
		_tempChildNum(Dest, TempChild, ChildNum).
_treeOp(Time, TempChild, NegatedNode, NegatedNode, negate)	% negate the child indicated by operation
	:-	_treeOp(Time, Dest, RootNode, left),
		_treeOp(Time, Dest, negateSingleChild),
		_treeOp(Time, Dest, NegatedNode, right),
		_childNum(RootNode, NegatedNode, ChildNum),
		_tempChildNum(Dest, TempChild, ChildNum).
% negate a single node
_activateTempNode(Time, Dest, neg)
	:-	_treeOp(Time, Dest, negate).
_activateChild(Time, Dest, TempChild)
	:-	_treeOp(Time, Dest, Node, Node, negate),
		_tempChildNum(Dest, TempChild, 1).
_deepCopy(Time, TempChild, Node)
	:-	_treeOp(Time, Dest, Node, Node, negate),
		_tempChildNum(Dest, TempChild, 1).

% TODO: integrate this with existing temp operations code
% TODO: create code for copying child structure (i.e. replicate child pointers, but don't do deepCopy just yet)
% this would simplify the above too
_tempHolds(Time, _fact(Temp, _nodeField(active, yes)))
	:-	_activateTempNodeOnly(Time, Temp).
_activateTempNodeOnly(Time, TempChild)
	:-	_activateChild(Time, TempParent, TempChild),
		_validTempChildOf(TempParent, TempChild).
_tempHolds(Time, _fact(TempParent, _nodeField(activechild, TempChild)))
	:-	_activateChild(Time, TempParent, TempChild),
		_validTempChildOf(TempParent, TempChild).
_activateChild(Time, TempParent, TempChild)
	:-	_activateChild(Time, TempParent, ChildNum),
		_tempChildNum(TempParent, TempChild, ChildNum).

	%%% ungroup nested mul or add trees
% copy over parent, and allocate new nodes for original children plus new children
_copyAttributes(Time, Dest, RootNode)
	:-	_treeOp(Time, Dest, canBeUngrouped),
		_treeOp(Time, Dest, RootNode, left).
_newTotalChildren(Time, NumChildren+NumGrandChildren - 1)
	:-	_treeOp(Time, Dest, canBeUngrouped),
		_treeOp(Time, Dest, RootNode, left),
		_treeOp(Time, Dest, NestedNode, right),
		_numActiveChildren(Time, RootNode, NumChildren),
		_numActiveChildren(Time, NestedNode, NumGrandChildren).
_childNumOfNestedNode(Time, Num)
	:-	_treeOp(Time, Dest, canBeUngrouped),
		_treeOp(Time, Dest, RootNode, left),
		_treeOp(Time, Dest, NestedNode, right),
		_childNum(RootNode, NestedNode, Num).
_activateChild(Time, Dest, Num)
	:-	_treeOp(Time, Dest, canBeUngrouped),
		_treeOp(Time, Dest, RootNode, left),
		_newTotalChildren(Time, NewNumKids),
		_childNum(RootNode, Child, Num),
		Num <= NewNumKids.
% copy children that are unaffected
_deepCopy(Time, TempChild, Child)
	:-	_treeOp(Time, Dest, canBeUngrouped),
		_treeOp(Time, Dest, RootNode, left),
		_childNumOfNestedNode(Time, NestedNum),
		_isATermOf(Time, RootNode, Child),
		_childNum(RootNode, Child, Num),
		_tempChildNum(Dest, TempChild, Num),
		Num < NestedNum.
% copy new children from nested node
_deepCopy(Time, TempChild, Child)
	:-	_treeOp(Time, Dest, canBeUngrouped),
		_treeOp(Time, Dest, NestedNode, right),
		_isATermOf(Time, NestedNode, Child),
		_childNum(NestedNode, Child, Num),
		_childNumOfNestedNode(Time, NestedNum),
		NewNum = Num + NestedNum - 1,
		_tempChildNum(Dest, TempChild, NewNum).
% copy remaining children
_deepCopy(Time, TempChild, Child)
	:-	_treeOp(Time, Dest, canBeUngrouped),
		_treeOp(Time, Dest, RootNode, left),
		_treeOp(Time, Dest, NestedNode, right),
		_childNumOfNestedNode(Time, NestedNodeNum),
		_isATermOf(Time, RootNode, Child),
		_childNum(RootNode, Child, Num),
		Num > NestedNodeNum,
		_numActiveChildren(Time, NestedNode, NumNewChildren),
		NewNum = Num + NumNewChildren - 1,
		_tempChildNum(Dest, TempChild, NewNum).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% mono  operations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_monoOp(Time, Dest, Left, left)
	:-	_monoOp(Time, Dest, Left, Right, Op).
_monoOp(Time, Dest, Right, right)
	:-	_monoOp(Time, Dest, Left, Right, Op).
_monoOp(Time, Dest, Op)
	:-	_monoOp(Time, Dest, Left, Right, Op).

% isolate the coeff and degree values of monomial operands
_monoOpCoeff(Time, Dest, Coeff, Side)
	:-	_monoOp(Time, Dest, Op),
		_monoOp(Time, Dest, Operand, Side),
		_isTheCoefficientOf(Time, Operand, Coeff).
_monoOpDeg(Time, Dest, Deg, Side)
	:-	_monoOp(Time, Dest, Op),
		_monoOp(Time, Dest, Operand, Side),
		_isTheDegreeOf(Time, Operand, Deg).

% add two monomials
_activateTempNode(Time, Dest, mono)
	:-	_monoOp(Time, Dest, add).
_tempHolds(Time, _fact(Dest, _nodeField(degree, Deg)))
	:-	_monoOp(Time, Dest, add),
		_monoOpDeg(Time, Dest, Deg, left).
_tempHolds(Time, _fact(Dest, _nodeField(coeff, Sum)))
	:-	_monoOp(Time, Dest, add),
		_monoOpCoeff(Time, Dest, FstCoeff, left),
		_monoOpCoeff(Time, Dest, SndCoeff, right),
		Sum = FstCoeff + SndCoeff,
		_coeff(Sum).

% negating a monomial
_setTempNodeToMono(Time, Dest, Deg, Coeff*-1)
    :-  _monoOp(Time, Dest, negate),
        _monoOpCoeff(Time, Dest, Coeff, left),
        _monoOpDeg(Time, Dest, Deg, left).
	% handle coefficient overflow in sum nodes
_coeffOverflow
	:-	_monoOp(Time, Dest, add),
		_monoOpCoeff(Time, Dest, FstCoeff, left),
		_monoOpCoeff(Time, Dest, SndCoeff, right),
		Sum = FstCoeff + SndCoeff,
		not _coeff(Sum).

% multiply two monomials
_activateTempNode(Time, Dest, mono)
	:-	_monoOp(Time, Dest, mul).
_tempHolds(Time, _fact(Dest, _nodeField(degree, DegSum)))
	:-	_monoOp(Time, Dest, mul),
		_monoOpDeg(Time, Dest, FstDeg, left),
		_monoOpDeg(Time, Dest, SndDeg, right),
		DegSum = FstDeg + SndDeg,
		_degree(DegSum).

_tempHolds(Time, _fact(Dest, _nodeField(coeff, Prod)))
	:-	_monoOp(Time, Dest, mul),
		_monoOpCoeff(Time, Dest, FstCoeff, left),
		_monoOpCoeff(Time, Dest, SndCoeff, right),
		Prod = FstCoeff * SndCoeff,
		_coeff(Prod).

	% handle coefficient and degree overflow when multiplying polynomials
_coeffOverflow
	:-	_monoOp(Time, Dest, mul),
		_monoOpCoeff(Time, Dest, FstCoeff, left),
		_monoOpCoeff(Time, Dest, SndCoeff, right),
		Prod = FstCoeff * SndCoeff,
		not _coeff(Prod).
_degOverflow
	:-	_monoOp(Time, Dest, mul),
		_monoOpDeg(Time, Dest, FstDeg, left),
		_monoOpDeg(Time, Dest, SndDeg, right),
		DegSum = FstDeg + SndDeg,
		not _degree(DegSum).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% eqn operations %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TODO: not sure if this will need to be generalized 

% define the left and right temp roots
_tempEqnRoot(tempLeftRoot;tempRightRoot).	

% NOTE: eqnMonoOps are operations where a new mono is introduced across an equation
% NOTE: Op should be one of: add, mul, div
_eqnMonoOp(Time, Op)
	:-	_eqnMonoOp(Time, Coeff, Deg, Op).

% set each side's temp root node to appropriate operator
_activateTempAndSetChildren(Time, TempRoot, Op, 2)
	:-	_eqnMonoOp(Time, Op),
		_tempEqnRoot(TempRoot).

% copy root node to be the left child of temproot
_deepCopy(Time, LeftChild, Root)
	:-	_eqnMonoOp(Time, Op),
		__rootNode(Root),
		MatchingTempRoot = _temp(Root), 
		_tempChildOnSide(MatchingTempRoot, LeftChild, left).
	
% NOTE: if necessary we can add coeff/deg separately to decrease grounding
_setTempNodeToMono(Time, RightChild, Deg, Coeff)
	:-	_eqnMonoOp(Time, Coeff, Deg, Op),
		__rootNode(Root),
		MatchingTempRoot = _temp(Root), 
		_tempChildOnSide(MatchingTempRoot, RightChild, right).

% eqnOps
% NOTE: eqnOp(Time, Operand, Operation)
%	Operation -- a binary operation applied to each side of equation
%	Operand	-- left/right side is one operand, this is the other

		%%% subtract a node from both sides of eqn
        %%% CASE 1: rootNode is appendable
_deepCopy(Time, Temp, RootNode)
	:-	_eqnOp(Time, Operand, sub),
        _appendableEqnOp(Time, Operand, RootNode),
		Temp = _temp(RootNode).
_setTempNodeToMono(Time, NewChild, Degree, Coeff*-1)
	:-	_eqnOp(Time, Operand, sub),
        _appendableEqnOp(Time, Operand, RootNode),
        _isTheCoefficientOf(Time, Operand, Coeff),
        _isTheDegreeOf(Time, Operand, Degree),
		Temp = _temp(RootNode),
        _numActiveChildren(Time, RootNode, Num),
        _tempChildNum(Temp, NewChild, Num+1).
_tempHolds(Time, _fact(Temp, _nodeField(activechild, NewChild)))
	:-	_eqnOp(Time, Operand, sub),
        _appendableEqnOp(Time, Operand, RootNode),
		Temp = _temp(RootNode),
        _numActiveChildren(Time, RootNode, Num),
        _tempChildNum(Temp, NewChild, Num+1).

        %%% CASE 2: can't append to existing root operation
% set new root to sum
_activateTempAndSetChildren(Time, Temp, add, 2)
	:-	_eqnOp(Time, Operand, sub),
		__rootNode(RootNode),
        not _appendableEqnOp(Time, Operand, RootNode),
		Temp = _temp(RootNode).
% copy original left/right sides of eqn
_deepCopy(Time, TempChild, RootNode)
	:-	_eqnOp(Time, Operand, sub),
		__rootNode(RootNode),
        not _appendableEqnOp(Time, Operand, RootNode),
		Temp = _temp(RootNode),
		_tempChildNum(Temp, TempChild, 1).

% other child of new root node is the negation of subtracted operand
_setTempNodeToMono(Time, TempSecondChild, Degree, Coeff*-1)
	:-	_eqnOp(Time, Operand, sub),
		__rootNode(RootNode),
		Temp = _temp(RootNode),
        not _appendableEqnOp(Time, Operand, RootNode),
        _isTheCoefficientOf(Time, Operand, Coeff),
        _isTheDegreeOf(Time, Operand, Degree),
		_tempChildNum(Temp, TempSecondChild, 2).
		
		%%% multiply eqn by operand
_treeOp(Time, Temp, RootNode, Operand, append(mul))
	:-	_eqnOp(Time, Operand, mul),
		__rootNode(RootNode),
		Temp = _temp(RootNode).
		%%% add operand to eqn 
_treeOp(Time, Temp, RootNode, Operand, append(add))
	:-	_eqnOp(Time, Operand, add),
		__rootNode(RootNode),
		Temp = _temp(RootNode).
		%%% divide eqn by const
_activateTempAndSetChildren(Time, Temp, div, 2) % new left(right) side is fraction
	:-	_eqnOp(Time, Const, divConst),
		__rootNode(RootNode),
        RootNode == rightSide,
		Temp = _temp(RootNode).
_deepCopy(Time, TempChild, RootNode)	% numerator is left(right) side
	:-	_eqnOp(Time, Const, divConst),
		__rootNode(RootNode),
        RootNode == rightSide,
		Temp = _temp(RootNode),
		_tempChildNum(Temp, TempChild, 1).
_setTempNodeToMono(Time, TempChild, 0, Coeff)
	:-	_eqnOp(Time, Term, divConst),   % NOTE: changed to only divide by a constant: not any variable terms
        _isTheCoefficientOf(Time, Term, Coeff),
		__rootNode(RootNode),
        RootNode == rightSide,
		Temp = _temp(RootNode),
		_tempChildNum(Temp, TempChild, 2).
_setTempNodeToMono(Time, Temp, Deg, 1)
	:-	_eqnOp(Time, Term, divConst), 
        Temp = _temp(leftSide),
        _isTheDegreeOf(Time, leftSide, Deg).

	%%% append eqnOps
% NOTE: An append tree Op tries to create a result that appends 'right' node to 'left' node
% 	if possible. Otherwise, it reverts to a typical treeOp.
_appendableEqnOp(Time, Operand, RootNode)
	:-	_eqnOp(Time, Operand, sub),
        __rootNode(RootNode),
		_hasType(Time, RootNode, add),
		_numActiveChildren(Time, RootNode, NumActive),
		_maxNumChildren(RootNode, MaxChildren),
		NumActive < MaxChildren.
%%_appendableEqnOp(Time, Operand, RootNode)%%
	%%:-	_eqnOp(Time, Operand, divConst),%%
        %%__rootNode(RootNode),%%
		%%_hasType(Time, RootNode, div),%%
        %%_numeratorOf(Time, RootNode, RootDenom),%%
		%%_numActiveChildren(Time, RootDenom, NumActive),%%
		%%_maxNumChildren(RootDenom, MaxChildren),%%
		%%NumActive < MaxChildren.%%

%%% if not appendable, then just do the regular treeOp%%
%%_treeOp(Time, Dest, Oper)	% we've already unpacked the operands so it's enough to declare this%%
	%%:-	_treeOp(Time, Dest, append(Oper)),%%
		%%not _appendable(Time, Dest).%%
%%% handle the append%%
%%_deepCopy(Time, Dest, Left)%%
	%%:-	_appendable(Time, Dest),%%
		%%_treeOp(Time, Dest, append(Oper)),%%
		%%_treeOp(Time, Dest, Left, left).%%
%%_appendedChild(Time, Dest, NewChild)%%
	%%:-	_appendable(Time, Dest),%%
		%%_treeOp(Time, Dest, append(Oper)),%%
		%%_treeOp(Time, Dest, Left, left),%%
		%%_numActiveChildren(Time, Left, Num),%%
		%%_tempChildNum(Dest, NewChild, Num+1).%%
%%_activateChild(Time, Dest, NewChild)%%
	%%:-	_appendedChild(Time, Dest, NewChild).%%
%%_deepCopy(Time, NewChild, Right)%%
	%%:-	_appendedChild(Time, Dest, NewChild),%%
		%%_treeOp(Time, Dest, append(Oper)),%%
		%%_treeOp(Time, Dest, Right, right).%%
