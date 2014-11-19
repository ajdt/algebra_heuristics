%================================================================================
% divIdentity: A / A ----> 1
%================================================================================
ruleFeature(divIdent, complexity, 0)
	:-	_operandDenom(Time, Denom, divIdent, left),
		_isConstant(Time, Denom).
ruleFeature(divIdent, complexity, 1)
	:-	_operandDenom(Time, Denom, divIdent, left),
		not _isConstant(Time, Denom),
		_isMono(Time, Denom).
ruleFeature(divIdent, complexity, 2)
	:-	_operandDenom(Time, Denom, divIdent, left),
		 _isNeg(Time, Denom).
ruleFeature(divIdent, complexity, 3)
	:-	_operandDenom(Time, Denom, divIdent, left),
		 not _isNeg(Time, Denom),
		 _isOper(Time, Denom).

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

%================================================================================
% factorMonom:	ax^k  --> bx^m * cx^n 
%================================================================================
ruleFeature(factorMonom, degComplexity, 0)
	:-	_selectedDegDecomposition(Time, Fst, Snd),
		Fst == 0, Snd == 0.
ruleFeature(factorMonom, degComplexity, 0)
	:-	_selectedDegDecomposition(Time, Fst, Snd),
		Fst == 0, Snd != 0.
ruleFeature(factorMonom, degComplexity, 0)
	:-	_selectedDegDecomposition(Time, Fst, Snd),
		Fst != 0, Snd == 0.
ruleFeature(factorMonom, degComplexity, 1)
	:-	_selectedDegDecomposition(Time, Fst, Snd),
		Fst != 0, Snd != 0.
ruleFeature(factorMonom, coeffComplexity, 0)
	:-	_selectedCoeffFactors(Time, FstFactor, SndFactor),
		|SndFactor| == 1.
ruleFeature(factorMonom, coeffComplexity, 0)
	:-	_selectedCoeffFactors(Time, FstFactor, SndFactor),
		|FstFactor| == 1.
ruleFeature(factorMonom, coeffComplexity, 1)
	:-	_selectedCoeffFactors(Time, FstFactor, SndFactor),
		|FstFactor| != 1, |SndFactor| != 1.
