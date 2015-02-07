%================================================================================
% divIdentity: A / A ----> 1
%================================================================================
ruleFeature(hasNumeratorAndDenominatorThatCancel, complexity, 0)
	:-	_operandDenom(Time, Denom, hasNumeratorAndDenominatorThatCancel, left),
		_isConstant(Time, Denom).
ruleFeature(hasNumeratorAndDenominatorThatCancel, complexity, 1)
	:-	_operandDenom(Time, Denom, hasNumeratorAndDenominatorThatCancel, left),
		not _isConstant(Time, Denom),
		_isMono(Time, Denom).
ruleFeature(hasNumeratorAndDenominatorThatCancel, complexity, 2)
	:-	_operandDenom(Time, Denom, hasNumeratorAndDenominatorThatCancel, left),
		 _isNeg(Time, Denom).
ruleFeature(hasNumeratorAndDenominatorThatCancel, complexity, 3)
	:-	_operandDenom(Time, Denom, hasNumeratorAndDenominatorThatCancel, left),
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
ruleFeature(isATermThatCanBeFactored, degComplexity, 0)
	:-	_selectedDegDecomposition(Time, Fst, Snd),
		Fst == 0, Snd == 0.
ruleFeature(isATermThatCanBeFactored, degComplexity, 0)
	:-	_selectedDegDecomposition(Time, Fst, Snd),
		Fst == 0, Snd != 0.
ruleFeature(isATermThatCanBeFactored, degComplexity, 0)
	:-	_selectedDegDecomposition(Time, Fst, Snd),
		Fst != 0, Snd == 0.
ruleFeature(isATermThatCanBeFactored, degComplexity, 1)
	:-	_selectedDegDecomposition(Time, Fst, Snd),
		Fst != 0, Snd != 0.
ruleFeature(isATermThatCanBeFactored, coeffComplexity, 0)
	:-	_selectedCoeffFactors(Time, FstFactor, SndFactor),
		|SndFactor| == 1.
ruleFeature(isATermThatCanBeFactored, coeffComplexity, 0)
	:-	_selectedCoeffFactors(Time, FstFactor, SndFactor),
		|FstFactor| == 1.
ruleFeature(isATermThatCanBeFactored, coeffComplexity, 1)
	:-	_selectedCoeffFactors(Time, FstFactor, SndFactor),
		|FstFactor| != 1, |SndFactor| != 1.
%================================================================================
% factorCommTerm:	(a*x^k + b*x^l ) --> (a*x^m + b*x^n ) * x^j
%================================================================================
ruleFeature(hasATermThatCanBeFactoredOut, degComplexity, 0)
	:-	_selectedCommonDeg(Time, Deg), Deg == 0.
ruleFeature(hasATermThatCanBeFactoredOut, degComplexity, 1)
	:-	_selectedCommonDeg(Time, Deg), Deg == 1.
ruleFeature(hasATermThatCanBeFactoredOut, degComplexity, 2)
	:-	_selectedCommonDeg(Time, Deg), Deg > 1.

ruleFeature(hasATermThatCanBeFactoredOut, coeffComplexity, 0)
	:-	_selectedCommonCoeff(Time, Coeff), Coeff == 0.
ruleFeature(hasATermThatCanBeFactoredOut, coeffComplexity, 1)
	:-	_selectedCommonCoeff(Time, Coeff), |Coeff| == 1.
ruleFeature(hasATermThatCanBeFactoredOut, coeffComplexity, 1)
	:-	_selectedCommonCoeff(Time, Coeff), |Coeff| != 1, Coeff != 0.

% size of expression we're factoring from
ruleFeature(hasATermThatCanBeFactoredOut, exprComplexity, 1)
	:-	_operand(Time, Poly, hasATermThatCanBeFactoredOut, left),
		_numActiveChildren(Time, Poly, 2).
ruleFeature(hasATermThatCanBeFactoredOut, exprComplexity, 2)
	:-	_operand(Time, Poly, hasATermThatCanBeFactoredOut, left),
		_numActiveChildren(Time, Poly, Num), Num > 2.
