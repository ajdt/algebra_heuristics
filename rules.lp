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
% NOTE: applicable only to subtrees over which equality is defined
_applicable(Time, _rule(thisFractionCanBeSimplifiedTo1, _operands(Fraction)))
	:-	_theNumeratorAndDenominatorOfThisFractionAreEqual(Time, Fraction).
_theNumeratorAndDenominatorOfThisFractionAreEqual(Time, Fraction)
	:-	_isFraction(Time, Fraction),
		_numeratorOf(Time, Fraction, Numer),
		_denominatorOf(Time, Fraction, Denom),
		_areEqual(Time, Numer, Denom).

_setToOne(Time, Fraction)
	:-	_operand(Time, Fraction, thisFractionCanBeSimplifiedTo1, left).

%================================================================================
% canBeMultipliedAsFractions: a/b * c/d --> (a*c)/(b*d)
%================================================================================
_applicable(Time, _rule(weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms, _operands(LeftFrac, RightFrac)))
    :-  _theseTwoFractionsAreBeingMultiplied(Time, LeftFrac, RightFrac).

_theseTwoFractionsAreBeingMultiplied(Time, LeftFrac, RightFrac)
	:-	_isFraction(Time, LeftFrac),
		_isFraction(Time, RightFrac),
		LeftFrac < RightFrac,
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
_applicable(Time, _rule(weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead, _operands(DenomFrac)))
			:-	_weAreDividingByAFraction(Time, DenomFrac).


_weAreDividingByAFraction(Time, DenomFrac) 
    :-  _weAreDividingByAFraction(Time, NumerTerm, DenomFrac).
_weAreDividingByAFraction(Time, NumerTerm, DenomFrac) 
    :-	_formAFraction(Time, NumerTerm, DenomFrac),
        _isFraction(Time, DenomFrac),
        NumerTerm < DenomFrac. % to ensure NumerTerm actually corresponds to numerator

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
_applicable(Time, _rule(soTheNumeratorOfThisFractionMustBeEqualToZero, _operands(leftSide)))
	:-	_thisSideOfTheEquationIsZero(Time, rightSide),
		_thisSideOfTheEquationIsAFraction(Time, leftSide).
_deepCopy(Time, tempResultRoot, Numer)
	:-	_operand(Time, Frac, soTheNumeratorOfThisFractionMustBeEqualToZero, left),
		_numeratorOf(Time, Frac, Numer).
_setResultTo(Time, leftSide)
	:-	_ruleForTimeStep(Time, soTheNumeratorOfThisFractionMustBeEqualToZero).


%================================================================================
% canBeAddedTogether: a*x^b + c*x^b ----> (a+c)*x^b
%================================================================================

_applicable(Time, _rule(weCanSimplifyByAddingTheseTwoTermsTogether, _operands(LeftMono, RightMono)))
    :-  _weAreAddingTwoTermsWithVariablesThatHaveTheSameDegree(Time, LeftMono, RightMono).

_weAreAddingTwoTermsWithVariablesThatHaveTheSameDegree(Time, LeftMono, RightMono)
	:-	_areBeingAdded(Time, LeftMono, RightMono),
		_haveEqualDegrees(Time, LeftMono, RightMono),
		__isMono(Time, LeftMono),
		__isMono(Time, RightMono),
		not _isZero(Time, LeftMono),	% if either mono is zero, then addZero rule is used instead
		not _isZero(Time, RightMono),
		LeftMono < RightMono.

_monoOp(Time, tempResultRoot, LeftMono, RightMono, add)
	:-	_operand(Time, LeftMono, weCanSimplifyByAddingTheseTwoTermsTogether, left),
		_operand(Time, RightMono, weCanSimplifyByAddingTheseTwoTermsTogether, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, weCanSimplifyByAddingTheseTwoTermsTogether).

%================================================================================
% monomult ax^b  * cx^d --> (a*c)x^(b+d)
%================================================================================
_applicable(Time, _rule(weCanSimplifyByCombiningTheseIntoASingleTerm, _operands(LeftMono, RightMono)))
	:-	_weAreMultiplyingTwoTerms(Time, LeftMono, RightMono).

_weAreMultiplyingTwoTerms(Time, LeftMono, RightMono)
	:-	_areBeingMultiplied(Time, LeftMono, RightMono),
		__isMono(Time, LeftMono),
		__isMono(Time, RightMono),
        not _isOne(Time, LeftMono),
        not _isOne(Time, RightMono),
		LeftMono < RightMono.
 
_monoOp(Time, tempResultRoot, LeftMono, RightMono, mul)
	:-	_operand(Time, LeftMono, weCanSimplifyByCombiningTheseIntoASingleTerm, left),
		_operand(Time, RightMono, weCanSimplifyByCombiningTheseIntoASingleTerm, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, weCanSimplifyByCombiningTheseIntoASingleTerm).

%================================================================================
% fracCancel A*B/C*B --> A/C
%================================================================================
% NOTE: relies on equal/3 predicate to work
_applicable(Time, _rule(weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator, _operands(NumerFactor, DenomFactor)))
    :-  _thisTermIsInBothTheNumeratorAndDenominatorOfAFraction(Time, NumerFactor, DenomFactor).

_thisTermIsInBothTheNumeratorAndDenominatorOfAFraction(Time, NumerFactor, DenomFactor)
	:-	_isFraction(Time, Fraction),
		_isFactorInNumeratorOf(Time, Fraction, NumerFactor),
        _isFactorInDenominatorOf(Time, Fraction, DenomFactor),
        _areEqual(Time, NumerFactor, DenomFactor).

_cancelTerm(Time, Factor)
	:-	_operand(Time, Factor, weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator, Side).

%================================================================================
% factor (x^2 + bx + c) --> (x + e) * (x + d)
%================================================================================
% NOTE: squared term must have coeff 1, divide by constant my be required to reach 
% this form
_applicable(Time, _rule(canBeFactored, _operands(Node)))
	:-	_isPolynomial(Time, Node),
		_isQuadratic(Time, Node),
		_isFactorable(Time, Node).

% select the factors to use
_factorsForBinomials(Time, FstFactor, SndFactor)
	:-	_operand(Time, Poly,  canBeFactored, left),
		_monoTermOfPoly(Time, Poly, 1, LinearTerm),
		_monoTermOfPoly(Time, Poly, 0, ConstTerm),
		_factors(FstFactor, SndFactor, LinearTerm, ConstTerm),
		FstFactor <= SndFactor. % NOTE: sanity check, ensure this rule is used @ most once per time step
% result is product of two binomials
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, canBeFactored).

% initialize binomials
_setToBinomial(Time, LeftChild, FstFactor)
	:-	_tempChildNum(tempResultRoot, LeftChild, 1),
		_factorsForBinomials(Time, FstFactor, SndFactor).
_setToBinomial(Time, RightChild, SndFactor)
	:-	_tempChildNum(tempResultRoot, RightChild, 2),
		_factorsForBinomials(Time, FstFactor, SndFactor).

% save the result of factoring
_setResultTo(Time, Poly)
	:-	_operand(Time, Poly,  canBeFactored, left).


%================================================================================
% addSameFrac A/B + C/B --> (A+C)/B
%================================================================================
% NOTE: _sameDenom depends on equals/3 predicate (which applies only to monomials)
_applicable(Time, _rule(weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction, _operands(Fst, Snd)))
	:-	_theseTwoFractionsAreBeingAddedAndTheyHaveTheSameDenominator(Time, Fst, Snd).

_theseTwoFractionsAreBeingAddedAndTheyHaveTheSameDenominator(Time, Fst, Snd)
	:-	_areBeingAdded(Time, Fst, Snd),
		_haveTheSameDenominator(Time, Fst, Snd),
		Fst < Snd.

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
_applicable(Time, _rule(weCanSimplifyByDistributingThisConstant, _operands(PlusTerm, __DistribTerm)))
	:-	_weAreMultiplyingASumOfTermsByAConstant(Time, PlusTerm, __DistribTerm).

_weAreMultiplyingASumOfTermsByAConstant(Time, PlusTerm, DistribTerm)
	:-	_areBeingMultiplied(Time, PlusTerm, DistribTerm),
		PlusTerm < DistribTerm, % TODO: this is necessary, but prevents distribute if C occurs before (a+b) term
		_isSumOfTerms(Time, PlusTerm).

% every term in original plus node, is multiplied by distributed term
_activateTempNode(Time, tempResultRoot, add)
	:-	_ruleForTimeStep(Time, weCanSimplifyByDistributingThisConstant).

_treeOp(Time, TempNode, Term, DistribTerm, mul)
	:-	_operand(Time, DistribTerm, weCanSimplifyByDistributingThisConstant, right),
		_operand(Time, PlusTerm, weCanSimplifyByDistributingThisConstant, left),
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
	:-	_ruleForTimeStep(Time, weCanSimplifyByDistributingThisConstant).


%================================================================================
% divByOne A/1 --> A
%================================================================================
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
_applicable(Time, _rule(weCanSimplifyByCancellingThe0, _operands(Mono)))
    :-  _weAreAdding0ToASumOfTerms(Time, Mono).

_weAreAdding0ToASumOfTerms(Time, Mono)
	:-	_isZero(Time, Mono),
		_isBeingAdded(Time, Mono).

_cancelTerm(Time, ZeroTerm)
	:-	_operand(Time, ZeroTerm, weCanSimplifyByCancellingThe0, left).

%================================================================================
% TODO: rewrite to generate better explanation
% factorMonom:	ax^k  --> bx^m * cx^n 
%================================================================================
% NOTE: this is the same rule as weCanSimplifyByFactoringOutAFACTOR, except written specifically for monomials
_applicable(Time, _rule(isATermThatCanBeFactored, _operands(Mono)))
	:-	__isMono(Time, Mono),
		not _isOne(Time, Mono),
		not _isZero(Time, Mono).

% NOTE: don't want either factor to be 1
:-  _selectedCoeffFactors(Time, FstFactor, SndFactor), 
    _selectedDegDecomposition(Time, Fst, Snd),
    FstFactor == 1,
    Fst == 1.
:-  _selectedCoeffFactors(Time, FstFactor, SndFactor), 
    _selectedDegDecomposition(Time, Fst, Snd),
    SndFactor == 1,
    Snd == 1.
% select coefficient factors,
1 { _selectedCoeffFactors(Time, FstFactor, SndFactor) 
		: _factors(FstFactor, SndFactor, FactorSum, Coeff) } 1
	:-	_operand(Time, Mono, isATermThatCanBeFactored, left),
		_isTheCoefficientOf(Time, Mono, Coeff).
% select degree factors
1 { _selectedDegDecomposition(Time, Fst, Snd) 
		: _degree(Fst), _degree(Snd),
			MonoDeg = Fst + Snd } 1
	:-	_operand(Time, Mono, isATermThatCanBeFactored, left),
		_isTheDegreeOf(Time, Mono, MonoDeg).
% form product of monomials (careful with code reuse here!!)
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, isATermThatCanBeFactored).
_setTempNodeToMono(Time, LeftChild, FstDeg, FstCoeff)
	:-	_ruleForTimeStep(Time, isATermThatCanBeFactored),
		_tempChildOnSide(tempResultRoot, LeftChild, left),
		_selectedCoeffFactors(Time, FstCoeff, SndCoeff),
		_selectedDegDecomposition(Time, FstDeg, SndDeg).
_setTempNodeToMono(Time, RightChild, SndDeg, SndCoeff)
	:-	_ruleForTimeStep(Time, isATermThatCanBeFactored),
		_tempChildOnSide(tempResultRoot, RightChild, right),
		_selectedCoeffFactors(Time, FstCoeff, SndCoeff),
		_selectedDegDecomposition(Time, FstDeg, SndDeg).
% save result 
_setResultTo(Time, Mono)
	:-	_operand(Time, Mono, isATermThatCanBeFactored, left).

%================================================================================
% TODO: rewrite to generate better explanation
%       check if layer 2 explanation is pretty good or not
% factorCommTerm:	(a*x^k + b*x^l ) --> (a*x^m + b*x^n ) * x^j
%================================================================================
_applicable(Time, _rule(weCanSimplifyByFactoringOutAFACTOR, _operands(Poly)))
	:-	_thisExpressionIsAPolynomialAndEachOfItsTermsHasFACTORAsAFactor(Time, Poly).

_thisExpressionIsAPolynomialAndEachOfItsTermsHasFACTORAsAFactor(Time, Poly)
	:-	_isPolynomial(Time, Poly),
		_hasCommonCoeff(Time, Poly),
		_hasCommonDeg(Time, Poly).
% select common term to factor our
% NOTE: we're now forcing selection to happen even if rule isn't applied
1 { _selectedCommonDeg(Time, Poly, Deg) : _hasCommonDeg(Time, Poly, Deg) } 1
	:-	_hasCommonDeg(Time, Poly).
_selectedCommonDeg(Time, Deg) 
    :-  _selectedCommonDeg(Time, Poly, Deg).
1 { _selectedCommonCoeff(Time, Poly, Coeff) : _hasCommonCoeff(Time, Poly, Coeff) } 1
	:-	_hasCommonCoeff(Time, Poly).
_selectedCommonCoeff(Time, Deg) 
    :-  _selectedCommonCoeff(Time, Poly, Deg).

%%% CONSTRAINT: don't allow factoring out a 1
:-  _selectedCommonDeg(Time, 0), _selectedCommonCoeff(Time, 1).

% setup correct tree structure
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTOR).

% save monomial that we factored out
_setTempNodeToMono(Time, TempRight, Deg, Coeff)
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTOR),
		_tempChildOnSide(tempResultRoot, TempRight, right),
		_selectedCommonDeg(Time, Deg),
		_selectedCommonCoeff(Time, Coeff).
% perform the division
_activateTempNode(Time, TempLeft, add)
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTOR),
		_tempChildOnSide(tempResultRoot, TempLeft, left).
_originalMonoTerm(Time, Mono, Num)	% isolate monomial terms
	:-	_operand(Time, Poly, weCanSimplifyByFactoringOutAFACTOR, left),
		_isATermOf(Time, Poly, Mono),
		_childNum(Poly, Mono, Num).
_newMonoTerm(Time, TempChild, Num)
	:-	_tempChildOnSide(tempResultRoot, TempLeft, left),
		_originalMonoTerm(Time, Mono, Num),
		_tempChildNum(TempLeft, TempChild, Num).

_tempHolds(Time, _fact(TempLeft, _nodeField(activechild, TempTerm)))
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTOR),
		_tempChildOnSide(tempResultRoot, TempLeft, left),
		_newMonoTerm(Time, TempTerm, Num).
_activateTempNode(Time, TempTerm, mono)
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTOR),
		_newMonoTerm(Time, TempTerm, Num).
% set the new coeff and deg values
_tempHolds(Time, _fact(TempTerm, _nodeField(coeff, NewCoeff)))
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTOR),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_isTheCoefficientOf(Time, Mono, MonoCoeff),
		_selectedCommonCoeff(Time, CommonCoeff),
		_coeffFactorPairOf(CommonCoeff, NewCoeff, MonoCoeff).

_tempHolds(Time, _fact(TempTerm, _nodeField(degree, NewDeg)))
	:-	_ruleForTimeStep(Time, weCanSimplifyByFactoringOutAFACTOR),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_isTheDegreeOf(Time, Mono, MonoDeg),
		_selectedCommonDeg(Time, CommonDeg),
		NewDeg = MonoDeg - CommonDeg.

% save result
_setResultTo(Time, Poly)
	:-	_operand(Time, Poly, weCanSimplifyByFactoringOutAFACTOR, left).

%================================================================================
% multByZero:	A*0 --> 0
%================================================================================
_applicable(Time, _rule(theProductOfTheseTermsIs0, _operands(ZeroTerm)))
    :-  _weAreMultiplyingSomeTermsBy0(Time, ZeroTerm). 

_weAreMultiplyingSomeTermsBy0(Time, ZeroTerm) 
	:-	_isZero(Time, ZeroTerm),
		_isBeingMultiplied(Time, ZeroTerm).

_setToZero(Time, Parent)
	:-	_operand(Time, ZeroTerm, theProductOfTheseTermsIs0, left),
		_isATermOf(Time, Parent, ZeroTerm).

%================================================================================
% multIdentity:	A*1 --> A
%================================================================================
_applicable(Time, _rule(weCanSimplifyByCancellingThe1, _operands(UnitTerm)))
    :-  _weAreMultiplyingSomeTermsBy1(Time, UnitTerm). 

_weAreMultiplyingSomeTermsBy1(Time, UnitTerm) 
	:-	_isOne(Time, UnitTerm),
        _areBeingMultiplied(Time, OtherTerm, UnitTerm),
        not __isMono(Time, OtherTerm).  % for monomials we use the mono multiply rule

_cancelTerm(Time, UnitTerm)
	:-	_operand(Time, UnitTerm, weCanSimplifyByCancellingThe1, left).

%================================================================================
% TODO: rewrite to generate better explanation
%           should isPolynomial be used to choose what we multiply by??
% multNumerAndDenom:	A/B --> (A*C)/(B*C)
%================================================================================
% NOTE: This rule requres max tree depth to be at least 4, otherwise the generated
% expression is too large and we get a node overflow.
% Additionally, we can only multiply expression by a polynomial expression already existing
% somewhere in the equation
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
_applicable(Time, _rule(canBeSubtractedFromTheEquation, _operands(Node)))
	:-	__isMono(Time, Node),
        _isConstant(Time, Node), 
        _isOnTheRightSideOfTheEquation(Node),
        not _isZero(Time, Node).

_eqnOp(Time, Operand, sub)
	:-	_operand(Time, Operand, canBeSubtractedFromTheEquation, left).
% save the results
_saveEqnResult(Time)
	:-	_ruleForTimeStep(Time, canBeSubtractedFromTheEquation).

%================================================================================
% MulEqn: A = B  --> A * D = B * D
%================================================================================
% canBeUsedToMultiplyBothSidesOfEquation
_applicable(Time, _rule(weCanSimplifyByMultiplyingBothSidesOfTheEquationByThisDenominator, _operands(Denom)))
	:-	_oneSideOfTheEquationIsAFractionAndThisIsItsDenominator(Time, Denom).

_oneSideOfTheEquationIsAFractionAndThisIsItsDenominator(Time, Denom) 
	:-	__rootNode(EqnSide),
        _isFraction(Time, EqnSide),
        _denominatorOf(Time, EqnSide, Denom),
        not _isOne(Time, Denom).
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
_applicable(Time, _rule(canDivideBothSidesOfTheEquation, _operands(Node)))
	:-	%_coeff(Coeff),
        __isMono(Time, Node).
        %%_isMultiplicationOperation(Time, leftSide).%%
        %%_factorOf(Time, leftSide, LeftFactor).%%
        %%_factorOf(Time, rightSide, RightFactor),%%
        %%_areEqual(Time, LeftFactor, RightFactor).%%
_eqnOp(Time, Coeff, divConst)
	:-	_operand(Time, Coeff, canDivideBothSidesOfTheEquation, left).
% save the results
_saveEqnResult(Time)
	:-	_ruleForTimeStep(Time, canDivideBothSidesOfTheEquation).

%================================================================================
% TODO: rewrite to generate better explanation
% decreaseDeg: x^4 + x^2= 0  --> x^2 + 1 = 0 (example)
%================================================================================
_applicable(Time, _rule(weCanSimplifyBySubstitutingYForXDEG, _operands(leftSide)))
	:-	%_equationHasNonConstantTerms(Time),
        _theDegreeOfEveryVariableInTheEquationIsDivisibleBy(Time, DEG).
_update(Time, Node, degree, ResultDeg)
	:-	_ruleForTimeStep(Time, weCanSimplifyBySubstitutingYForXDEG),
		_smallestNonZeroDeg(Time, DividingDeg),
		_isTheDegreeOf(Time, Node, OrigDeg),
		OrigDeg != 0,
		_degProduct(OrigDeg, DividingDeg, ResultDeg).

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

%================================================================================
% TODO: rewrite to generate better explanation replace not isFraction with isNotFraction
% mulWithFrac: (A/B) * D --> (A*D)/B
%================================================================================
_applicable(Time, _rule(weCanSimplifyByMultiplyingTheNumeratorByTheTerm, _operands(Fraction, NotFraction)))
	:-	_weAreMultiplyingAFractionByATerm(Time, Fraction, NotFraction).

_weAreMultiplyingAFractionByATerm(Time, Fraction, NotFraction)
	:-	_areBeingMultiplied(Time, Fraction, NotFraction),
		_isFraction(Time, Fraction),
		not _isFraction(Time, NotFraction).

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
_rule(thisFractionCanBeSimplifiedTo1).
_rule(weCanSimplifyByPerformingFractionMultiplicationOnTheseTwoTerms).
_rule(weCanSimplifyByMultiplyingByTheInverseOfThisFractionInstead).
_rule(soTheNumeratorOfThisFractionMustBeEqualToZero).
_rule(weCanSimplifyByAddingTheseTwoTermsTogether).
_rule(weCanSimplifyByCombiningTheseIntoASingleTerm).
_rule(weCanSimplifyByCancellingThisTermInTheNumeratorAndTheDenominator).
_rule(canBeFactored).
_rule(weCanSimplifyByCombiningTheseTwoFractionsIntoASingleFraction).
_rule(weCanSimplifyByDistributingThisConstant).
_rule(weCanSimplifyByCancellingTheDenominatorOfThisFraction).
_rule(weCanSimplifyByCancellingThe0).
_rule(isATermThatCanBeFactored).
_rule(weCanSimplifyByFactoringOutAFACTOR).
_rule(theProductOfTheseTermsIs0).
_rule(weCanSimplifyByCancellingThe1).
_rule(weCanSimplifyByMultiplyingTheNumeratorAndDenominatorByTERM).
_rule(weCanSimplifyByCancellingTheseTerms).
_rule(canBeSubtractedFromTheEquation).
_rule(weCanSimplifyByMultiplyingBothSidesOfTheEquationByThisDenominator).
_rule(canDivideBothSidesOfTheEquation).
_rule(weCanSimplifyBySubstitutingYForXDEG).
_rule(weCanSimplifyByMultiplyingTheNumeratorByTheTerm).

