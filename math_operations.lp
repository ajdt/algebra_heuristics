%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SETTING NODE TO 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_clearNodeDeleteDescendants(Time, Node)
	:-	_setToOne(Time, Node).
_setNodeType(Time, Node, mono)
	:-	_setToOne(Time, Node).
_introduce(Time, Node, coeff, 1)
	:-	_setToOne(Time, Node).
_introduce(Time, Node, degree, 0)
	:-	_setToOne(Time, Node).

% set to zero
_clearNodeDeleteDescendants(Time, Node)
	:-	_setToZero(Time, Node).
_setNodeType(Time, Node, mono)
	:-	_setToZero(Time, Node).
_introduce(Time, Node, coeff, 0)
	:-	_setToZero(Time, Node).
_introduce(Time, Node, degree, 0)
	:-	_setToZero(Time, Node).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SETTING RESULT OF BINARY OPERATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% XXX: assumes each time step we're setting only using setResultTo(...) at most once
% NOTE: 2-ary version ignore RightPoly to limit grounding size; still works correctly

% isolate the "left/right" operands
_writeBinaryLeft(Time, LeftOper)
	:-	_writeBinaryOp(Time, LeftOper, RightOper).
_writeBinaryRight(Time, RightOper)
	:-	_writeBinaryOp(Time, LeftOper, RightOper).

% determine whether to set result to root node or left node
_setResultTo(Time, Root)	
	:-	_writeBinaryLeft(Time, LeftOper),
		_hasTwoTerms(Time, Root),	
		_activeChild(Time, Root, LeftOper).
_setResultTo(Time, LeftOper)
	:-	_writeBinaryLeft(Time, LeftOper),
		not _hasTwoTerms(Time, Root),
		_activeChild(Time, Root, LeftOper).

% cancel unneeded terms
_deleteTerm(Time, RightOper)
	:-	_writeBinaryRight(Time, RightOper).
_deleteTerm(Time, LeftOper)
	:-	_writeBinaryLeft(Time, LeftOper),
		not _setResultTo(Time, LeftOper).
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

% set to fraction, deep copy
_activateTempAndSetChildren(Time, Temp, div, 2)
	:-	_treeOp(Time, Temp, reciprocal).
_deepCopy(Time, TempChild, Node)
	:-	_treeOp(Time, Temp, reciprocal),
		_treeOp(Time, Temp, Node, Side),
		_tempChildOnSide(Temp, TempChild, OtherSide),
		Side != OtherSide. % ensure 'left' child gets copied to 'right' and vice versa

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
		_coeffOf(Time, Operand, Coeff).
_monoOpDeg(Time, Dest, Deg, Side)
	:-	_monoOp(Time, Dest, Op),
		_monoOp(Time, Dest, Operand, Side),
		_degOf(Time, Operand, Deg).

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
		_rootNode(Root),
		MatchingTempRoot = _temp(Root), 
		_tempChildOnSide(MatchingTempRoot, LeftChild, left).
	
% set the other child to a monomial
_activateTempNode(Time, RightChild, mono)
	:-	_eqnMonoOp(Time, Op),
		_rootNode(Root),
		MatchingTempRoot = _temp(Root), 
		_tempChildOnSide(MatchingTempRoot, RightChild, right).

% NOTE: if necessary we can add coeff/deg separately to decrease grounding
_setTempNodeToMono(Time, RightChild, Deg, Coeff)
	:-	_eqnMonoOp(Time, Coeff, Deg, Op),
		_rootNode(Root),
		MatchingTempRoot = _temp(Root), 
		_tempChildOnSide(MatchingTempRoot, RightChild, right).
		
