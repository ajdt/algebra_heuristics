%================================================================================
% addInverses: A + -A --> 0 
%================================================================================
ruleFeature(addInverses, complexity, 0)
	:-	_operand(Time, Node, addInverses, right),
		_isConstant(Time, Node).
ruleFeature(addInverses, complexity, 1)
	:-	_operand(Time, Node, addInverses, right),
		not _isConstant(Time, Node),
		_isMono(Time, Node).
ruleFeature(addInverses, complexity, 2)
	:-	_operand(Time, Node, addInverses, right),
		_isOper(Time, Node).
