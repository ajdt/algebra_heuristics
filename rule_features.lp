%================================================================================
% divIdentity: A / A ----> 1
%================================================================================
ruleFeature(thisFractionCanBeSimplifiedTo1, complexity, 0)
	:-	_operandDenom(Time, Denom, thisFractionCanBeSimplifiedTo1, left),
		_isConstant(Time, Denom).
ruleFeature(thisFractionCanBeSimplifiedTo1, complexity, 1)
	:-	_operandDenom(Time, Denom, thisFractionCanBeSimplifiedTo1, left),
		not _isConstant(Time, Denom),
		__isMono(Time, Denom).
ruleFeature(thisFractionCanBeSimplifiedTo1, complexity, 2)
	:-	_operandDenom(Time, Denom, thisFractionCanBeSimplifiedTo1, left),
		 _isNeg(Time, Denom).
ruleFeature(thisFractionCanBeSimplifiedTo1, complexity, 3)
	:-	_operandDenom(Time, Denom, thisFractionCanBeSimplifiedTo1, left),
		 not _isNeg(Time, Denom),
		 _isOper(Time, Denom).

%================================================================================
% addInverses: A + -A --> 0 
%================================================================================
ruleFeature(addUpToZero, complexity, 0)
	:-	_operand(Time, Node, addUpToZero, right),
		_isConstant(Time, Node).
ruleFeature(addUpToZero, complexity, 1)
	:-	_operand(Time, Node, addUpToZero, right),
		not _isConstant(Time, Node),
		__isMono(Time, Node).
ruleFeature(addUpToZero, complexity, 2)
	:-	_operand(Time, Node, addUpToZero, right),
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
ruleFeature(weCanSimplifyByFactoringOutAFACTOR, degComplexity, 0)
	:-	_selectedCommonDeg(Time, Deg), Deg == 0.
ruleFeature(weCanSimplifyByFactoringOutAFACTOR, degComplexity, 1)
	:-	_selectedCommonDeg(Time, Deg), Deg == 1.
ruleFeature(weCanSimplifyByFactoringOutAFACTOR, degComplexity, 2)
	:-	_selectedCommonDeg(Time, Deg), Deg > 1.

ruleFeature(weCanSimplifyByFactoringOutAFACTOR, coeffComplexity, 0)
	:-	_selectedCommonCoeff(Time, Coeff), Coeff == 0.
ruleFeature(weCanSimplifyByFactoringOutAFACTOR, coeffComplexity, 1)
	:-	_selectedCommonCoeff(Time, Coeff), |Coeff| == 1.
ruleFeature(weCanSimplifyByFactoringOutAFACTOR, coeffComplexity, 1)
	:-	_selectedCommonCoeff(Time, Coeff), |Coeff| != 1, Coeff != 0.

% size of expression we're factoring from
ruleFeature(weCanSimplifyByFactoringOutAFACTOR, exprComplexity, 1)
	:-	_operand(Time, Poly, weCanSimplifyByFactoringOutAFACTOR, left),
		_numActiveChildren(Time, Poly, 2).
ruleFeature(weCanSimplifyByFactoringOutAFACTOR, exprComplexity, 2)
	:-	_operand(Time, Poly, weCanSimplifyByFactoringOutAFACTOR, left),
		_numActiveChildren(Time, Poly, Num), Num > 2.
