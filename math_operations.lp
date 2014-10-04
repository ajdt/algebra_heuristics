%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SETTING NODE TO 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_clearNodeDeleteDescendants(Time, Node)
	:-	_setToOne(Time, Node).
_setNodeType(Time, Node, mono)
	:-	_setToOne(Time, Node).
_introduce(Time, Node, coeff, 1)
	:-	_setToOne(Time, Node).
_introduce(Time, Node, degree, 0)
	:-	_setToOne(Time, Node).
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
_cancelTerm(Time, RightOper)
	:-	_writeBinaryRight(Time, RightOper).
_cancelTerm(Time, LeftOper)
	:-	_writeBinaryLeft(Time, LeftOper),
		not _setResultTo(Time, LeftOper).
_deepCopy(Time, Root, tempRoot)
	:-	_setResultTo(Time, Root).

