%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EXTRACTING RULE OPERANDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_clearNodeDeleteDescendants(Time, Node)
	:-	_setToOne(Time, Node).
_setNodeType(Time, Node, mono)
	:-	_setToOne(Time, Node).
_introduce(Time, Node, coeff, 1)
	:-	_setToOne(Time, Node).
_introduce(Time, Node, degree, 0)
	:-	_setToOne(Time, Node).
