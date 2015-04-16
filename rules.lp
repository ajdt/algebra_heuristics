% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file defines rules and their rewrite actions on an equation.
% A rule is applicable at a particular time step for a particular solution.
% These rules are used by eqn_solver.lp to solve a generated problem
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EXTRACTING RULE OPERANDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract operands from a rule application. Unary operations only have a 'left' operand 
_operand(Time, OnlyOper, RuleName, left)
	:-	_performRule(Time, _rule(RuleName, _operands(OnlyOper))).
_operand(Time, Fst, RuleName, left)
	:-	_performRule(Time, _rule(RuleName, _operands(Fst, Snd))).
_operand(Time, Snd, RuleName, right)
	:-	_performRule(Time, _rule(RuleName, _operands(Fst, Snd))).
_operandDenom(Time, Denom, RuleName, Side)
	:-	_operand(Time, Frac, RuleName, Side),
		_denominatorOf(Time, Frac, Denom).
_operandNumer(Time, Numer, RuleName, Side)
	:-	_operand(Time, Frac, RuleName, Side),
		_numeratorOf(Time, Frac, Numer).

% writing result of a binary operation
% _writeBinaryOp/1. must be generated explicitly to write result as a binary operation
_writeBinaryOp(Time, Fst, Snd)
	:-	_operand(Time, Fst, Operation, left),
		_operand(Time, Snd, Operation, right),
		_node(Fst), _node(Snd),
		_writeBinaryOp(Time).
% saving the results of an Equation-wide operation
_deepCopy(Time, RootNode, TempRoot)
    :-	_saveEqnResult(Time),	% output saveEqnResult/1 to save equation-wide operation
        __rootNode(RootNode),
        TempRoot = _temp(RootNode) .


%================================================================================
% divIdentity: A / A ----> 1
%================================================================================
_theCategoryOfHeuristicIs(thisFractionCanBeSimplifiedToOne, cancel).
% NOTE: applicable only to subtrees over which equality is defined
_applicable(Time, _rule(thisFractionCanBeSimplifiedToOne, _operands(Fraction)))
	:-	_theNumeratorAndDenominatorOfThisFractionAreEqual(Time, Fraction).
_theNumeratorAndDenominatorOfThisFractionAreEqual(Time, Fraction)
	:-	_isFraction(Time, Fraction),
		_numeratorOf(Time, Fraction, Numer),
		_denominatorOf(Time, Fraction, Denom),
		_areEqual(Time, Numer, Denom).

_setToOne(Time, Fraction)
	:-	_operand(Time, Fraction, thisFractionCanBeSimplifiedToOne, left).

%================================================================================
% canBeMultipliedAsFractions: a/b * c/d --> (a*c)/(b*d)
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms, combine).
_applicable(Time, _rule(weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms, _operands(LeftFrac, RightFrac)))
    :-  _theseTwoFractionsAreBeingMultiplied(Time, LeftFrac, RightFrac).

_theseTwoFractionsAreBeingMultiplied(Time, LeftFrac, RightFrac)
	:-	_isFraction(Time, LeftFrac),
		_isFraction(Time, RightFrac),
        __areOnTheSameSideOfTheEquation(LeftFrac, RightFrac),
        __isLessThan(LeftFrac, RightFrac),
		_areBeingMultiplied(Time, LeftFrac, RightFrac).

% set result as a fraction with numer and denom as fractions
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms).
_treeOp(Time, TempNumer, FstNumer, SndNumer, mul)
	:-	_tempChildOnSide(tempResultRoot, TempNumer, left),
		_operandNumer(Time, FstNumer, weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms, left),
		_operandNumer(Time, SndNumer, weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms, right).
_treeOp(Time, TempDenom, FstDenom, SndDenom, mul)
	:-	_tempChildOnSide(tempResultRoot, TempDenom, right),
		_operandDenom(Time, FstDenom, weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms, left),
		_operandDenom(Time, SndDenom, weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms).

%================================================================================
% canBeMultipliedByInverseOf: a/c / b/d --> a/c * d/b
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead, rearrange).
_applicable(Time, _rule(weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead, _operands(DenomFrac)))
			:-	_weAreDividingByAFraction(Time, NumerTerm, DenomFrac).

_weAreDividingByAFraction(Time, NumerTerm, DenomFrac) 
    :-	_formAFraction(Time, NumerTerm, DenomFrac),
        _isFraction(Time, DenomFrac),
        __areOnTheSameSideOfTheEquation(NumerTerm, DenomFrac),
        __isLessThan(NumerTerm, DenomFrac).  % to ensure NumerTerm actually corresponds to numerator

% set root node to multiplication node
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead).
% numerator term remains unchanged
_deepCopy(Time, LeftTemp, NumerTerm)
	:-	_tempChildOnSide(tempResultRoot, LeftTemp, left),
		_ruleForTimeStep(Time, weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead),
        _weAreDividingByAFraction(Time, NumerTerm, DenomFrac),
		_operand(Time, DenomFrac, weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead, left).
% flip numer/denom fields
_treeOp(Time, RightTemp, Numer, Denom, reciprocal)
	:-	_operand(Time, DenomFrac, weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead, left),
		_numeratorOf(Time, DenomFrac, Numer),
		_denominatorOf(Time, DenomFrac, Denom),
		_tempChildOnSide(tempResultRoot, RightTemp, right).

_setResultTo(Time, Root)
	:-	_operand(Time, DenomFrac, weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead, left),
		_isATermOf(Time, Root, DenomFrac).

%================================================================================
% ignore denominator: a / b = 0 --> a = 0
%================================================================================
_theCategoryOfHeuristicIs(soTheNumeratorOfThisFractionMustBeEqualToZero, cancel).
_applicable(Time, _rule(soTheNumeratorOfThisFractionMustBeEqualToZero, _operands(leftSide)))
	:-	_thisSideOfTheEquationIsZero(Time, rightSide),
		_thisSideOfTheEquationIsAFraction(Time, leftSide).
_deepCopy(Time, tempResultRoot, Numer)
	:-	_operand(Time, Frac, soTheNumeratorOfThisFractionMustBeEqualToZero, left),
		_numeratorOf(Time, Frac, Numer).
_setResultTo(Time, leftSide)
	:-	_ruleForTimeStep(Time, soTheNumeratorOfThisFractionMustBeEqualToZero).

_thisSideOfTheEquationIsZero(Time, Side)
    :-  __rootNode(Side),
        _isZero(Time, Side).
_thisSideOfTheEquationIsAFraction(Time, Side)
    :-  __rootNode(Side),
        _isFraction(Time, Side).


%================================================================================
% canBeAddedTogether: a*x^b + c*x^b ----> (a+c)*x^b
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByAddingTheseTwoTermsTogether, combine).
_applicable(Time, _rule(weCanSimplifyByAddingTheseTwoTermsTogether, _operands(LeftMono, RightMono)))
    :-  _weAreAddingTwoTermsWithVariablesThatHaveTheSameDegree(Time, LeftMono, RightMono).

_weAreAddingTwoTermsWithVariablesThatHaveTheSameDegree(Time, LeftMono, RightMono)
	:-	_areBeingAdded(Time, LeftMono, RightMono),
		_haveEqualDegrees(Time, LeftMono, RightMono),
		__isMono(Time, LeftMono),
		__isMono(Time, RightMono),
        __areOnTheSameSideOfTheEquation(LeftMono, RightMono),
        _isNotZero(Time, LeftMono), % if either mono is zero, then addZero rule is used instead
		_isNotZero(Time, RightMono),
        __isLessThan(LeftMono, RightMono).

_monoOp(Time, tempResultRoot, LeftMono, RightMono, add)
	:-	_operand(Time, LeftMono, weCanSimplifyByAddingTheseTwoTermsTogether, left),
		_operand(Time, RightMono, weCanSimplifyByAddingTheseTwoTermsTogether, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, weCanSimplifyByAddingTheseTwoTermsTogether).

%================================================================================
% monomult ax^b  * cx^d --> (a*c)x^(b+d)
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByCombiningTheseIntoASingleTerm, combine).
_applicable(Time, _rule(weCanSimplifyByCombiningTheseIntoASingleTerm, _operands(LeftMono, RightMono)))
	:-	_weAreMultiplyingTwoTerms(Time, LeftMono, RightMono).

_weAreMultiplyingTwoTerms(Time, LeftMono, RightMono)
	:-	_areBeingMultiplied(Time, LeftMono, RightMono),
		__isMono(Time, LeftMono),
		__isMono(Time, RightMono),
        __areOnTheSameSideOfTheEquation(LeftMono, RightMono),
        _isNotOne(Time, LeftMono),
        _isNotOne(Time, RightMono),
        __isLessThan(LeftMono, RightMono).
 
_monoOp(Time, tempResultRoot, LeftMono, RightMono, mul)
	:-	_operand(Time, LeftMono, weCanSimplifyByCombiningTheseIntoASingleTerm, left),
		_operand(Time, RightMono, weCanSimplifyByCombiningTheseIntoASingleTerm, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, weCanSimplifyByCombiningTheseIntoASingleTerm).

%================================================================================
% fracCancel A*B/C*B --> A/C
%================================================================================
% NOTE: relies on equal/3 predicate to work
_theCategoryOfHeuristicIs(weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator, cancel).
_applicable(Time, _rule(weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator, _operands(NumerFactor, DenomFactor)))
    :-  _thisTermIsInBothTheNumeratorAndDenominatorOfAFraction(Time, NumerFactor, DenomFactor).

_thisTermIsInBothTheNumeratorAndDenominatorOfAFraction(Time, NumerFactor, DenomFactor)
	:-	_isFraction(Time, Fraction),
		_isFactorInNumeratorOf(Time, Fraction, NumerFactor),
        _isFactorInDenominatorOf(Time, Fraction, DenomFactor),
        _areEqual(Time, NumerFactor, DenomFactor).

_cancelTerm(Time, Factor)
	:-	_operand(Time, Factor, weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator, Side),
        not _canCancelWholeFraction(Time).
_setToOne(Time, Fraction)
	:-	_operand(Time, Factor, weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator, left),
        _canCancelWholeFraction(Time),
        _numeratorOf(Time, Fraction, Factor).

_canCancelWholeNumerator(Time)
	:-	_operand(Time, Factor, weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator, left),
        _numeratorOf(Time, Fraction, Factor).
_canCancelWholeDenominator(Time)
	:-	_operand(Time, Factor, weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator, right),
        _denominatorOf(Time, Fraction, Factor).
_canCancelWholeFraction(Time)
    :-  _canCancelWholeNumerator(Time),
        _canCancelWholeDenominator(Time).

%================================================================================
% factor (x^2 + bx + c) --> (x + e) * (x + d)
%================================================================================
% NOTE: squared term must have coeff 1, divide by constant my be required to reach 
% this form
_theCategoryOfHeuristicIs(weCanSimplifyByFactoringThisExpression, expand).
_applicable(Time, _rule(weCanSimplifyByFactoringThisExpression, _operands(Node)))
	:-	_thisExpressionIsPolynomialAndQuadratic(Time, Node),
        _theNumbersFACTORAAndFACTORBHaveASumOfFACTORXAndProductOfFACTORYSoWeCanUseThemToFactor(Time).
_thisExpressionIsPolynomialAndQuadratic(Time, Node)
	:-	_isPolynomial(Time, Node),
		_isQuadratic(Time, Node),
		_isFactorable(Time, Node).

_theNumbersFACTORAAndFACTORBHaveASumOfFACTORXAndProductOfFACTORYSoWeCanUseThemToFactor(Time)
    :-  _isFactorable(Time, Node).

% select the factors to use
_factor1(Time, 0, FstFactor)
    :-  _factorsForBinomials(Time, FstFactor, SndFactor).
_factor2(Time, 0, SndFactor)
    :-  _factorsForBinomials(Time, FstFactor, SndFactor).
_factor3(Time, 0, LinearTerm)
	:-	_operand(Time, Poly,  weCanSimplifyByFactoringThisExpression, left),
		_monoTermOfPoly(Time, Poly, 1, LinearTerm).
_factor4(Time, 0, ConstTerm)
	:-	_operand(Time, Poly,  weCanSimplifyByFactoringThisExpression, left),
		_monoTermOfPoly(Time, Poly, 0, ConstTerm).

_factorsForBinomials(Time, FstFactor, SndFactor)
	:-	_operand(Time, Poly,  weCanSimplifyByFactoringThisExpression, left),
		_monoTermOfPoly(Time, Poly, 1, LinearTerm),
		_monoTermOfPoly(Time, Poly, 0, ConstTerm),
		_factors(FstFactor, SndFactor, LinearTerm, ConstTerm),
		FstFactor <= SndFactor. % NOTE: sanity check, ensure this rule is used @ most once per time step
% result is product of two binomials
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringThisExpression).

% initialize binomials
_setToBinomial(Time, LeftChild, FstFactor)
	:-	_tempChildNum(tempResultRoot, LeftChild, 1),
		_factorsForBinomials(Time, FstFactor, SndFactor).
_setToBinomial(Time, RightChild, SndFactor)
	:-	_tempChildNum(tempResultRoot, RightChild, 2),
		_factorsForBinomials(Time, FstFactor, SndFactor).

% save the result of factoring
_setResultTo(Time, Poly)
	:-	_operand(Time, Poly,  weCanSimplifyByFactoringThisExpression, left).


%================================================================================
% addSameFrac A/B + C/B --> (A+C)/B
%================================================================================
% NOTE: _sameDenom depends on equals/3 predicate (which applies only to monomials)
_theCategoryOfHeuristicIs(weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction, combine).
_applicable(Time, _rule(weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction, _operands(Fst, Snd)))
	:-	_theseTwoFractionsAreBeingAddedAndTheyHaveTheSameDenominator(Time, Fst, Snd).

_theseTwoFractionsAreBeingAddedAndTheyHaveTheSameDenominator(Time, Fst, Snd)
	:-	_areBeingAdded(Time, Fst, Snd),
		_haveTheSameDenominator(Time, Fst, Snd),
        __areOnTheSameSideOfTheEquation(Fst, Snd),
        __isLessThan(Fst, Snd).

% set root to a fraction
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction).

% set numerator to a sum
_treeOp(Time, TempNumer, FstNumer, SndNumer, add)
	:-	_tempChildNum(tempResultRoot, TempNumer, 1),
		_operandNumer(Time, FstNumer, weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction, left),
		_operandNumer(Time, SndNumer, weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction, right).
% set denom 
_deepCopy(Time, TempDenom, FstDenom)
	:-	_tempChildNum(tempResultRoot, TempDenom, 2),
		_operandDenom(Time, FstDenom, weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction, left).
% save result
_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction).
	
%================================================================================
% distribute (a + b) * C --> (a*C + b*C)
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByDistributingTheSingleFactor, expand).
_applicable(Time, _rule(weCanSimplifyByDistributingTheSingleFactor, _operands(PlusTerm, DistribTerm)))
	:-	_weAreMultiplyingASumOfTermsByASingleFactor(Time, PlusTerm, DistribTerm).

_weAreMultiplyingASumOfTermsByASingleFactor(Time, PlusTerm, DistribTerm)
	:-	_areBeingMultiplied(Time, PlusTerm, DistribTerm),
        __areOnTheSameSideOfTheEquation(PlusTerm, DistribTerm),
        __isLessThan(PlusTerm, DistribTerm), % TODO: this is necessary, but prevents distribute if C occurs before (a+b) term
		_isSumOfTerms(Time, PlusTerm).

% every term in original plus node, is multiplied by distributed term
_activateTempNode(Time, tempResultRoot, add)
	:-	_ruleForTimeStep(Time, weCanSimplifyByDistributingTheSingleFactor).

_treeOp(Time, TempNode, Term, DistribTerm, mul)
	:-	_operand(Time, DistribTerm, weCanSimplifyByDistributingTheSingleFactor, right),
		_operand(Time, PlusTerm, weCanSimplifyByDistributingTheSingleFactor, left),
		_isATermOf(Time, PlusTerm, Term),
		_childNum(PlusTerm, Term, ChildNum),
		_tempChildNum(tempResultRoot, TempNode, ChildNum).

% setup parent child links 
% NOTE: must be done explicitly b/c there may be gaps between active children
_tempHolds(Time, _fact(tempResultRoot, _nodeField(activechild, Temp)))
	:-	_tempHolds(Time, _fact(Temp, _nodeField(active, yes))),
		_validTempChildOf(tempResultRoot, Temp).
% save result
_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, weCanSimplifyByDistributingTheSingleFactor).


%================================================================================
% divByOne A/1 --> A
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByCancellingTheDenominatorOfThisFraction, cancel).
_applicable(Time, _rule(weCanSimplifyByCancellingTheDenominatorOfThisFraction, _operands(Fraction)))
	:-	_theDenominatorOfThisFractionIs1(Time, Fraction).
_theDenominatorOfThisFractionIs1(Time, Fraction) 
	:-	_denominatorOf(Time, Fraction, Denom),
		_isOne(Time, Denom).

_deepCopy(Time, Fraction, Numer)
	:-	_operand(Time, Fraction, weCanSimplifyByCancellingTheDenominatorOfThisFraction, left),
		_numeratorOf(Time, Fraction, Numer).
%================================================================================
% addZero A + 0 --> A
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByCancellingTheZero, cancel).
_applicable(Time, _rule(weCanSimplifyByCancellingTheZero, _operands(Mono)))
    :-  _weAreAdding0ToASumOfTerms(Time, Mono).

_weAreAdding0ToASumOfTerms(Time, Mono)
	:-	_isZero(Time, Mono),
		_isBeingAdded(Time, Mono).

_cancelTerm(Time, ZeroTerm)
	:-	_operand(Time, ZeroTerm, weCanSimplifyByCancellingTheZero, left).

%================================================================================
% TODO: rewrite to generate better explanation
% factorMonom:	ax^k  --> bx^m * cx^n 
%================================================================================
% NOTE: this is the same rule as weCanSimplifyByFactoringOutAFACTORA, except written specifically for monomials
_theCategoryOfHeuristicIs(weCanSimplifyBySubstitutingTheFactorsOfTheTerm, expand).
_applicable(Time, _rule(weCanSimplifyBySubstitutingTheFactorsOfTheTerm, _operands(Mono)))
	:-	_thisTermHasFactorsFACTORAAndFACTORB(Time, Mono).

_thisTermHasFactorsFACTORAAndFACTORB(Time, Mono)
	:-	__isMono(Time, Mono),
        _isNotOne(Time, Mono),
        _isNotZero(Time, Mono).

% NOTE: don't want either factor to be 1
_factor1(Time, Fst, FstFactor)
    :-  _selectedDegDecomposition(Time, Fst, Snd), 
        _selectedCoeffFactors(Time, FstFactor, SndFactor). 
_factor2(Time, Snd, SndFactor)
    :-  _selectedDegDecomposition(Time, Fst, Snd), 
        _selectedCoeffFactors(Time, FstFactor, SndFactor). 
:-  _selectedCoeffFactors(Time, FstFactor, SndFactor), 
    _selectedDegDecomposition(Time, Fst, Snd),
    FstFactor == 1,
    Fst == 0.
:-  _selectedCoeffFactors(Time, FstFactor, SndFactor), 
    _selectedDegDecomposition(Time, Fst, Snd),
    SndFactor == 1,
    Snd == 0.
% select coefficient factors,
1 { _selectedCoeffFactors(Time, FstFactor, SndFactor) 
		: _factors(FstFactor, SndFactor, FactorSum, Coeff) } 1
	:-	_operand(Time, Mono, weCanSimplifyBySubstitutingTheFactorsOfTheTerm, left),
		_isTheCoefficientOf(Time, Mono, Coeff).
% select degree factors
1 { _selectedDegDecomposition(Time, Fst, Snd) 
		: _degree(Fst), _degree(Snd),
			MonoDeg = Fst + Snd } 1
	:-	_operand(Time, Mono, weCanSimplifyBySubstitutingTheFactorsOfTheTerm, left),
		_isTheDegreeOf(Time, Mono, MonoDeg).
% form product of monomials (careful with code reuse here!!)
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, weCanSimplifyBySubstitutingTheFactorsOfTheTerm).
_setTempNodeToMono(Time, LeftChild, FstDeg, FstCoeff)
	:-	_ruleForTimeStep(Time, weCanSimplifyBySubstitutingTheFactorsOfTheTerm),
		_tempChildOnSide(tempResultRoot, LeftChild, left),
		_selectedCoeffFactors(Time, FstCoeff, SndCoeff),
		_selectedDegDecomposition(Time, FstDeg, SndDeg).
_setTempNodeToMono(Time, RightChild, SndDeg, SndCoeff)
	:-	_ruleForTimeStep(Time, weCanSimplifyBySubstitutingTheFactorsOfTheTerm),
		_tempChildOnSide(tempResultRoot, RightChild, right),
		_selectedCoeffFactors(Time, FstCoeff, SndCoeff),
		_selectedDegDecomposition(Time, FstDeg, SndDeg).
% save result 
_setResultTo(Time, Mono)
	:-	_operand(Time, Mono, weCanSimplifyBySubstitutingTheFactorsOfTheTerm, left).

%================================================================================
% TODO: rewrite to generate better explanation
%       check if layer 2 explanation is pretty good or not
% factorCommTerm:	(a*x^k + b*x^l ) --> (a*x^m + b*x^n ) * x^j
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByFactoringOutAFACTORA, expand).
_applicable(Time, _rule(weCanSimplifyByFactoringOutAFACTORA, _operands(Poly)))
	:-	_thisExpressionIsAPolynomialAndEachOfItsTermsHasFACTORAAsAFactor(Time, Poly),
        __selectedPoly(Time, Poly).

_thisExpressionIsAPolynomialAndEachOfItsTermsHasFACTORAAsAFactor(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		_hasCommonCoeff(Time, Poly),
		_hasCommonDeg(Time, Poly).
    
0 { __selectedPoly(Time, Poly) : _thisExpressionIsAPolynomialAndEachOfItsTermsHasFACTORAAsAFactor(Time, Poly) } 1
    :-  __validTime(Time).
% select common term to factor our
% NOTE: we're now forcing selection to happen even if rule isn't applied
1 { _selectedCommonDeg(Time, Poly, Deg) : _hasCommonDeg(Time, Poly, Deg) } 1
	:-	__selectedPoly(Time, Poly).
1 { _selectedCommonCoeff(Time, Poly, Coeff) : _hasCommonCoeff(Time, Poly, Coeff) } 1
	:-	__selectedPoly(Time, Poly).

_selectedCommonDeg(Time, Deg) 
    :-  _selectedCommonDeg(Time, Poly, Deg).
_selectedCommonCoeff(Time, Coeff) 
    :-  _selectedCommonCoeff(Time, Poly, Coeff).
_factor1(Time, Deg, Coeff)
    :-  _selectedCommonDeg(Time, Deg),
        _selectedCommonCoeff(Time, Coeff).

%%% CONSTRAINT: don't allow factoring out a 1
:-  _selectedCommonDeg(Time, 0), _selectedCommonCoeff(Time, 1).

% setup correct tree structure
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTORA).

% save monomial that we factored out
_setTempNodeToMono(Time, TempRight, Deg, Coeff)
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTORA),
		_tempChildOnSide(tempResultRoot, TempRight, right),
		_selectedCommonDeg(Time, Deg),
		_selectedCommonCoeff(Time, Coeff).
% perform the division
_activateTempNode(Time, TempLeft, add)
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTORA),
		_tempChildOnSide(tempResultRoot, TempLeft, left).
_originalMonoTerm(Time, Mono, Num)	% isolate monomial terms
	:-	_operand(Time, Poly, weCanSimplifyByFactoringOutAFACTORA, left),
		_isATermOf(Time, Poly, Mono),
		_childNum(Poly, Mono, Num).
_newMonoTerm(Time, TempChild, Num)
	:-	_tempChildOnSide(tempResultRoot, TempLeft, left),
		_originalMonoTerm(Time, Mono, Num),
		_tempChildNum(TempLeft, TempChild, Num).

_tempHolds(Time, _fact(TempLeft, _nodeField(activechild, TempTerm)))
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTORA),
		_tempChildOnSide(tempResultRoot, TempLeft, left),
		_newMonoTerm(Time, TempTerm, Num).
_activateTempNode(Time, TempTerm, mono)
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTORA),
		_newMonoTerm(Time, TempTerm, Num).
% set the new coeff and deg values
_tempHolds(Time, _fact(TempTerm, _nodeField(coeff, NewCoeff)))
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTORA),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_isTheCoefficientOf(Time, Mono, MonoCoeff),
		_selectedCommonCoeff(Time, CommonCoeff),
		_coeffFactorPairOf(CommonCoeff, NewCoeff, MonoCoeff).

_tempHolds(Time, _fact(TempTerm, _nodeField(degree, NewDeg)))
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTORA),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_isTheDegreeOf(Time, Mono, MonoDeg),
		_selectedCommonDeg(Time, CommonDeg),
		NewDeg = MonoDeg - CommonDeg.

% save result
_setResultTo(Time, Poly)
	:-	_operand(Time, Poly, weCanSimplifyByFactoringOutAFACTORA, left).

%================================================================================
% multByZero:	A*0 --> 0
%================================================================================
_theCategoryOfHeuristicIs(theProductOfTheseTermsIsZero, combine).
_applicable(Time, _rule(theProductOfTheseTermsIsZero, _operands(ZeroTerm)))
    :-  _weAreMultiplyingSomeTermsBy0(Time, ZeroTerm). 

_weAreMultiplyingSomeTermsBy0(Time, ZeroTerm) 
	:-	_isZero(Time, ZeroTerm),
		_isBeingMultiplied(Time, ZeroTerm).

_setToZero(Time, Parent)
	:-	_operand(Time, ZeroTerm, theProductOfTheseTermsIsZero, left),
		_isATermOf(Time, Parent, ZeroTerm).

%================================================================================
% multIdentity:	A*1 --> A
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByCancellingTheOne, combine).
_applicable(Time, _rule(weCanSimplifyByCancellingTheOne, _operands(UnitTerm)))
    :-  _weAreMultiplyingSomeTermsBy1(Time, UnitTerm). 

_weAreMultiplyingSomeTermsBy1(Time, UnitTerm) 
	:-	_isOne(Time, UnitTerm),
        _areBeingMultiplied(Time, OtherTerm, UnitTerm),
        __isNotMono(Time, OtherTerm).  % for monomials we use the mono multiply rule

_cancelTerm(Time, UnitTerm)
	:-	_operand(Time, UnitTerm, weCanSimplifyByCancellingTheOne, left).

%================================================================================
% TODO: rewrite to generate better explanation
%           should isPolynomial be used to choose what we multiply by??
% multNumerAndDenom:	A/B --> (A*C)/(B*C)
%================================================================================
% NOTE: This rule requres max tree depth to be at least 4, otherwise the generated
% expression is too large and we get a node overflow.
% Additionally, we can only multiply expression by a polynomial expression already existing
% somewhere in the equation
_theCategoryOfHeuristicIs(weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM, expand).
_applicable(Time, _rule(weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM, _operands(Fraction, TERM)))
	:-	_thisIsAFraction(Time, Fraction),
		__isActive(Time, TERM).

_thisIsAFraction(Time, Fraction)
	:-	_isFraction(Time, Fraction).
% set root to div
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM).

% multiply numer
_treeOp(Time, TempNode, Numer, Poly, mul)
	:-	_operandNumer(Time, Numer, weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM, left),
		_operand(Time, Poly, weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM, right),
		_tempChildOnSide(tempResultRoot, TempNode, left).

% multiply denom
_treeOp(Time, TempNode, Denom, Poly, mul)
	:-	_operandDenom(Time, Denom, weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM, left),
		_operand(Time, Poly, weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM, right),
		_tempChildOnSide(tempResultRoot, TempNode, right).

% save the result
_setResultTo(Time, Fraction)
	:-	_operand(Time, Fraction, weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM, left).

%================================================================================
% cancelSumTerm: A + B = A + C --> B = C
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByCancellingTheseTerms, cancel).
_applicable(Time, _rule(weCanSimplifyByCancellingTheseTerms, _operands(LeftChild, RightChild)))
	:-	_thisTermIsAddedToBothSidesOfTheEquation(Time, LeftChild, RightChild).

_thisTermIsAddedToBothSidesOfTheEquation(Time, LeftChild, RightChild)
	:-	_isSumOfTerms(Time, leftSide),
		_isSumOfTerms(Time, rightSide),
		_isATermOf(Time, leftSide, LeftChild),
		_isATermOf(Time, rightSide, RightChild),
		_areEqual(Time, LeftChild, RightChild).

_cancelTerm(Time, Node)
	:-	_operand(Time, Node, weCanSimplifyByCancellingTheseTerms, Side).

%================================================================================
% TODO: rewrite to generate better explanation
% subtractFromEqn: A = B  --> A - D = B - D
%================================================================================
_isOnTheLeftSideOfTheEquation(leftSide).
_isOnTheRightSideOfTheEquation(rightSide).
_isOnTheLeftSideOfTheEquation(Child)
    :-  _validChildOf(Parent, Child),
        _isOnTheLeftSideOfTheEquation(Parent).
_isOnTheRightSideOfTheEquation(Child)
    :-  _validChildOf(Parent, Child),
        _isOnTheRightSideOfTheEquation(Parent).
%%_equationIsNotLinear(Time)  [> TODO: not sure if we need these%%
    %%:- _isTheDegreeOf(Time, Node, Deg),%%
        %%Deg >= 2 .%%
%%_equationIsLinear(Time)%%
    %%:-  __validTime(Time),%%
        %%not _equationIsNotLinear(Time).%%
_theCategoryOfHeuristicIs(weCanSimplifyBySubtractingTheTermFromBothSides, move).
_applicable(Time, _rule(weCanSimplifyBySubtractingTheTermFromBothSides, _operands(Node)))
    :-  _theEquationHasOnlyLinearTerms(Time),
        _thereIsAConstantOnTheLefthandSideOfTheEquation(Time, Node).
_theCategoryOfHeuristicIs(weCanSimplifyBySubtractingTheVariableTermFromBothSides, move).
_applicable(Time, _rule(weCanSimplifyBySubtractingTheVariableTermFromBothSides, _operands(Node)))
    :-  _thereIsAVariableOnTheRighthandSideOfTheEquation(Time, Node).
_theCategoryOfHeuristicIs(weCanSimplifyBySubtractingTheNonZeroTermFromBothSides, move).
_applicable(Time, _rule(weCanSimplifyBySubtractingTheNonZeroTermFromBothSides, _operands(Node)))
    :-  _theEquationHasAHighDegreeTerm(Time),
        _thereIsANonZeroTermOnTheRighthandSideOfTheEquation(Time, Node).

_thereIsANonZeroTermOnTheRighthandSideOfTheEquation(Time, Node)
    :-  _isNonZero(Time, Node),
        _isOnTheRightSideOfTheEquation(Node).

% create predicates for additional tags!!
__referTo(Time, 1, Node)
        :-  _thereIsAVariableOnTheRighthandSideOfTheEquation(Time, Node),
            _ruleForTimeStep(Time, weCanSimplifyBySubtractingTheVariableTermFromBothSides).

__referTo(Time, 1, Node)
    :-  _theEquationHasAHighDegreeTerm(Time, Node),
        _ruleForTimeStep(Time, weCanSimplifyBySubtractingTheNonZeroTermFromBothSides).

_thereIsAVariableOnTheRighthandSideOfTheEquation(Time, Node)
    :-  _isATermWithAVariable(Time, Node),
        _isSumOfTerms(Time, rightSide),
        _isATermOf(Time, rightSide, Node),
        not _isZero(Time, Node).
_isATermWithAVariable(Time, Node)
    :-  __isMono(Time, Node),
        _isTheDegreeOf(Time, Node, Deg),
        Deg >= 1.
_isNonZero(Time, Node)
    :-  __isMono(Time, Node),
        not _isZero(Time, Node).
_thereIsAConstantOnTheLefthandSideOfTheEquation(Time, Node)
	:-	_isConstant(Time, Node),
        _isSumOfTerms(Time, leftSide),
        _isATermOf(Time, leftSide, Node),
        not _isZero(Time, Node).

_theEquationHasAHighDegreeTerm(Time) 
    :-  _theEquationHasAHighDegreeTerm(Time, Node).
_theEquationHasAHighDegreeTerm(Time, Node) % TODO: Improve these explanations
    :-  _isTheDegreeOf(Time, Node, Deg),
        Deg >= 2.
_theEquationHasOnlyLinearTerms(Time)
    :-  __validTime(Time),
        not _theEquationHasAHighDegreeTerm(Time).


% all of these subtraction operations have the same eqnOp
_subtractOp(weCanSimplifyBySubtractingTheVariableTermFromBothSides).
_subtractOp(weCanSimplifyBySubtractingTheTermFromBothSides).
_subtractOp(weCanSimplifyBySubtractingTheNonZeroTermFromBothSides).

_eqnOp(Time, Operand, sub)
	:-	_operand(Time, Operand, Operation, left),
        _subtractOp(Operation).
% save the results
_saveEqnResult(Time)
	:-	_ruleForTimeStep(Time, Operation),
        _subtractOp(Operation).

%================================================================================
% MulEqn: A = B  --> A * D = B * D
%================================================================================
% canBeUsedToMultiplyBothSidesOfEquation
_theCategoryOfHeuristicIs(weCanSimplifyByMultiplyingBothSidesOfTheEquationByThisDenominator, expand).
_applicable(Time, _rule(weCanSimplifyByMultiplyingBothSidesOfTheEquationByThisDenominator, _operands(Denom)))
	:-	_oneSideOfTheEquationIsAFractionAndThisIsItsDenominator(Time, Denom).

_oneSideOfTheEquationIsAFractionAndThisIsItsDenominator(Time, Denom) 
	:-	__rootNode(EqnSide),
        _isFraction(Time, EqnSide),
        _denominatorOf(Time, EqnSide, Denom),
        _isNotOne(Time, Denom).
_eqnOp(Time, Operand, mul)
	:-	_operand(Time, Operand, weCanSimplifyByMultiplyingBothSidesOfTheEquationByThisDenominator, left).
% save the results
_saveEqnResult(Time)
	:-	_ruleForTimeStep(Time, weCanSimplifyByMultiplyingBothSidesOfTheEquationByThisDenominator).

%================================================================================
% TODO: rewrite to generate better explanation
%       is currently unsatisfiable
% divEqnByConst: A = B  --> A / d = B / d
%================================================================================
_theCategoryOfHeuristicIs(weCanDivideBothSidesByTheCoefficientOfTheLeftSide, rearrange).
_applicable(Time, _rule(weCanDivideBothSidesByTheCoefficientOfTheLeftSide, _operands(leftSide)))
	:-	%_coeff(Coeff),
        _leftSideIsASingleTermWithAVariable(Time, leftSide),
        _rightSideIsAConstant(Time, rightSide).
        %%_isMultiplicationOperation(Time, leftSide).%%
        %%_factorOf(Time, leftSide, LeftFactor).%%
        %%_factorOf(Time, rightSide, RightFactor),%%
        %%_areEqual(Time, LeftFactor, RightFactor).%%

% NOTE: for almost fires explanation, use depth=1 in this case?
_leftSideIsASingleTermWithAVariable(Time, leftSide)
    :-  __isMono(Time, leftSide),
        _isTheDegreeOf(Time, leftSide, Deg),
        Deg >= 1,
        _isTheCoefficientOf(Time, leftSide, Coeff),
        Coeff != 1, 
        Coeff != 0.
_rightSideIsAConstant(Time, rightSide)
    :-  __isMono(Time, rightSide),
        _isTheDegreeOf(Time, rightSide, Deg),
        Deg == 0.

_eqnOp(Time, Coeff, divConst)
	:-	_operand(Time, Coeff, weCanDivideBothSidesByTheCoefficientOfTheLeftSide, left).
% save the results
_saveEqnResult(Time)
	:-	_ruleForTimeStep(Time, weCanDivideBothSidesByTheCoefficientOfTheLeftSide).

%================================================================================
% TODO: rewrite to generate better explanation
% decreaseDeg: x^4 + x^2= 0  --> x^2 + 1 = 0 (example)
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyBySubstitutingYForFACTORA, expand).
_applicable(Time, _rule(weCanSimplifyBySubstitutingYForFACTORA, _operands(leftSide)))
	:-	%_equationHasNonConstantTerms(Time),
        _theDegreeOfEveryVariableInTheEquationIsDivisibleBy(Time, DEG).

_update(Time, Node, degree, ResultDeg)
	:-	_ruleForTimeStep(Time, weCanSimplifyBySubstitutingYForFACTORA),
		_smallestNonZeroDeg(Time, DividingDeg),
		_isTheDegreeOf(Time, Node, OrigDeg),
		_degreeIsNotZero(OrigDeg),
		_degProduct(OrigDeg, DividingDeg, ResultDeg).
_factor1(Time, Degree, 1)
    :-  _theDegreeOfEveryVariableInTheEquationIsDivisibleBy(Time, Degree).

_theDegreeOfEveryVariableInTheEquationIsDivisibleBy(Time, Deg)
    :-  __validTime(Time),
        not _xVarCannotBeSubstituted(Time),
        _smallestNonZeroDeg(Time, Deg).
_xVarCannotBeSubstituted(Time)
	:-	_smallestNonZeroDeg(Time, Deg),
		Deg <= 1.
_xVarCannotBeSubstituted(Time)
	:-	_smallestNonZeroDeg(Time, Deg),
		_eqnHasNonZeroDeg(Time, OtherDeg),
		not _degDivisbleBy(OtherDeg, Deg).

_equationHasNonConstantTerms(Time)
	:-	_isTheDegreeOf(Time, Node, Deg),
		_isTheCoefficientOf(Time, Node, Coeff),
		Coeff != 0,
		Deg > 0.

_substitutedDegree(Time, Deg)
    :-  _ruleForTimeStep(Time, weCanSimplifyBySubstitutingYForFACTORA),
        _theDegreeOfEveryVariableInTheEquationIsDivisibleBy(Time, Deg).
%================================================================================
% TODO: rewrite to generate better explanation replace not isFraction with isNotFraction
% mulWithFrac: (A/B) * D --> (A*D)/B
%================================================================================
_theCategoryOfHeuristicIs(weCanSimplifyByMultiplyingTheNumeratorByTheTerm, combine).
_applicable(Time, _rule(weCanSimplifyByMultiplyingTheNumeratorByTheTerm, _operands(Fraction, NotFraction)))
	:-	_weAreMultiplyingAFractionByATerm(Time, Fraction, NotFraction).

_weAreMultiplyingAFractionByATerm(Time, Fraction, NotFraction)
	:-	_areBeingMultiplied(Time, Fraction, NotFraction),
		_isFraction(Time, Fraction),
		_isNotFraction(Time, NotFraction).

_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, weCanSimplifyByMultiplyingTheNumeratorByTheTerm).
_treeOp(Time, FstChild, Numer, NotFraction, append(mul))
	:-	_operand(Time, Fraction, weCanSimplifyByMultiplyingTheNumeratorByTheTerm, left),
		_numeratorOf(Time, Fraction, Numer),
		_operand(Time, NotFraction, weCanSimplifyByMultiplyingTheNumeratorByTheTerm, right),
		_tempChildNum(tempResultRoot, FstChild, 1).
_deepCopy(Time, SndChild, Denom)
	:-	_operand(Time, Fraction, weCanSimplifyByMultiplyingTheNumeratorByTheTerm, left),
		_denominatorOf(Time, Fraction, Denom),
		_tempChildNum(tempResultRoot, SndChild, 2).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, weCanSimplifyByMultiplyingTheNumeratorByTheTerm).

%% Rules Listed: Used to generate default rule heuristics
_rule(thisFractionCanBeSimplifiedToOne).
_rule(weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms).
_rule(weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead).
_rule(soTheNumeratorOfThisFractionMustBeEqualToZero).
_rule(weCanSimplifyByAddingTheseTwoTermsTogether).
_rule(weCanSimplifyByCombiningTheseIntoASingleTerm).
_rule(weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator).
_rule(weCanSimplifyByFactoringThisExpression).
_rule(weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction).
_rule(weCanSimplifyByDistributingTheSingleFactor).
_rule(weCanSimplifyByCancellingTheDenominatorOfThisFraction).
_rule(weCanSimplifyByCancellingTheZero).
_rule(weCanSimplifyBySubstitutingTheFactorsOfTheTerm).
_rule(weCanSimplifyByFactoringOutAFACTORA).
_rule(theProductOfTheseTermsIsZero).
_rule(weCanSimplifyByCancellingTheOne).
_rule(weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM).
_rule(weCanSimplifyByCancellingTheseTerms).
_rule(weCanSimplifyBySubtractingTheTermFromBothSides).
_rule(weCanSimplifyByMultiplyingBothSidesOfTheEquationByThisDenominator).
_rule(weCanDivideBothSidesByTheCoefficientOfTheLeftSide).
_rule(weCanSimplifyBySubstitutingYForFACTORA).
_rule(weCanSimplifyByMultiplyingTheNumeratorByTheTerm).
_rule(weCanSimplifyBySubtractingTheVariableTermFromBothSides).
_rule(weCanSimplifyBySubtractingTheNonZeroTermFromBothSides).

