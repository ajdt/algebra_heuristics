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
_applicable(Time, _rule(hasNumeratorAndDenominatorThatCancel, _operands(Fraction)))
	:-	_isFraction(Time, Fraction),
		_numeratorOf(Time, Fraction, Numer),
		_denominatorOf(Time, Fraction, Denom),
		_areEqual(Time, Numer, Denom).
_setToOne(Time, Fraction)
	:-	_operand(Time, Fraction, hasNumeratorAndDenominatorThatCancel, left).

%================================================================================
% canBeMultipliedAsFractions: a/b * c/d --> (a*c)/(b*d)
%================================================================================
_applicable(Time, _rule(canBeMultipliedAsFractions, _operands(LeftFrac, RightFrac)))
	:-	_isFraction(Time, LeftFrac),
		_isFraction(Time, RightFrac),
		LeftFrac < RightFrac,
		_areBeingMultiplied(Time, LeftFrac, RightFrac).

% set result as a fraction with numer and denom as fractions
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, canBeMultipliedAsFractions).
_treeOp(Time, TempNumer, FstNumer, SndNumer, mul)
	:-	_tempChildOnSide(tempResultRoot, TempNumer, left),
		_operandNumer(Time, FstNumer, canBeMultipliedAsFractions, left),
		_operandNumer(Time, SndNumer, canBeMultipliedAsFractions, right).
_treeOp(Time, TempDenom, FstDenom, SndDenom, mul)
	:-	_tempChildOnSide(tempResultRoot, TempDenom, right),
		_operandDenom(Time, FstDenom, canBeMultipliedAsFractions, left),
		_operandDenom(Time, SndDenom, canBeMultipliedAsFractions, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, canBeMultipliedAsFractions).

%================================================================================
% canBeMultipliedByInverseOf: a/c / b/d --> a/c * d/b
%================================================================================
_applicable(Time, _rule(canBeMultipliedByInverseOf, _operands(NumerFrac, DenomFrac)))
			:-	_formAFraction(Time, NumerFrac, DenomFrac),
				_isFraction(Time, NumerFrac),
				_isFraction(Time, DenomFrac),
				NumerFrac < DenomFrac. % to ensure NumerFrac actually corresponds to numerator

% set root node to multiplication node
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, canBeMultipliedByInverseOf).
% 'left' fraction remains unchanged
_deepCopy(Time, LeftTemp, NumerFrac)
	:-	_tempChildOnSide(tempResultRoot, LeftTemp, left),
		_ruleForTimeStep(Time, canBeMultipliedByInverseOf),
		_operand(Time, NumerFrac, canBeMultipliedByInverseOf, left).
% flip numer/denom fields
_treeOp(Time, RightTemp, Numer, Denom, reciprocal)
	:-	_operand(Time, DenomFrac, canBeMultipliedByInverseOf, right),
		_numeratorOf(Time, DenomFrac, Numer),
		_denominatorOf(Time, DenomFrac, Denom),
		_tempChildOnSide(tempResultRoot, RightTemp, right).

_setResultTo(Time, Root)
	:-	_operand(Time, DenomFrac, canBeMultipliedByInverseOf, right),
		_isATermOf(Time, Root, DenomFrac).

%================================================================================
% ignore denominator: a / b = 0 --> a = 0
%================================================================================
_applicable(Time, _rule(canBeReducedToItsNumerator, _operands(leftSide)))
	:-	_isZero(Time, rightSide),
		_isFraction(Time, leftSide).

% assumes that fraction is poly/poly
_deepCopy(Time, tempResultRoot, Numer)
	:-	_operand(Time, Frac, canBeReducedToItsNumerator, left),
		_numeratorOf(Time, Frac, Numer).
_setResultTo(Time, leftSide)
	:-	_ruleForTimeStep(Time, canBeReducedToItsNumerator).


%================================================================================
% canBeAddedTogether: a*x^b + c*x^b ----> (a+c)*x^b
%================================================================================

_applicable(Time, _rule(canBeAddedTogether, _operands(LeftMono, RightMono)))
	:-	_areBeingAdded(Time, LeftMono, RightMono),
		_haveEqualDegrees(Time, LeftMono, RightMono),
		__isMono(Time, LeftMono),
		__isMono(Time, RightMono),
		not _isZero(Time, LeftMono),	% if either mono is zero, then addZero rule is used instead
		not _isZero(Time, RightMono),
		LeftMono < RightMono.

_monoOp(Time, tempResultRoot, LeftMono, RightMono, add)
	:-	_operand(Time, LeftMono, canBeAddedTogether, left),
		_operand(Time, RightMono, canBeAddedTogether, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, canBeAddedTogether).

%================================================================================
% monomult ax^b  * cx^d --> (a*c)x^(b+d)
%================================================================================
_applicable(Time, _rule(canBeMultipliedTogether, _operands(LeftMono, RightMono)))
	:-	_areBeingMultiplied(Time, LeftMono, RightMono),
		__isMono(Time, LeftMono),
		__isMono(Time, RightMono),
        not _isOne(Time, LeftMono),
        not _isOne(Time, RightMono),
		LeftMono < RightMono.
 
_monoOp(Time, tempResultRoot, LeftMono, RightMono, mul)
	:-	_operand(Time, LeftMono, canBeMultipliedTogether, left),
		_operand(Time, RightMono, canBeMultipliedTogether, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, canBeMultipliedTogether).

%================================================================================
% fracCancel A*B/C*B --> A/C
%================================================================================
% NOTE: relies on equal/3 predicate to work
_applicable(Time, _rule(areFactorsThatCancel, _operands(NumerFactor, DenomFactor)))
	:-	_isFraction(Time, Fraction),
		_isFactorInNumeratorOf(Time, Fraction, NumerFactor),
        _isFactorInDenominatorOf(Time, Fraction, DenomFactor),
        _areEqual(Time, NumerFactor, DenomFactor).
_cancelTerm(Time, Factor)
	:-	_operand(Time, Factor, areFactorsThatCancel, Side).

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
_applicable(Time, _rule(canBeAddedAsOneFraction, _operands(Fst, Snd)))
	:-	_areBeingAdded(Time, Fst, Snd),
		_haveTheSameDenominator(Time, Fst, Snd),
		Fst < Snd.

% set root to a fraction
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, canBeAddedAsOneFraction).

% set numerator to a sum
_treeOp(Time, TempNumer, FstNumer, SndNumer, add)
	:-	_tempChildNum(tempResultRoot, TempNumer, 1),
		_operandNumer(Time, FstNumer, canBeAddedAsOneFraction, left),
		_operandNumer(Time, SndNumer, canBeAddedAsOneFraction, right).
% set denom 
_deepCopy(Time, TempDenom, FstDenom)
	:-	_tempChildNum(tempResultRoot, TempDenom, 2),
		_operandDenom(Time, FstDenom, canBeAddedAsOneFraction, left).
% save result
_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, canBeAddedAsOneFraction).
	
%================================================================================
% distribute (a + b) * C --> (a*C + b*C)
%================================================================================
_applicable(Time, _rule(canBeDistributed, _operands(PlusTerm, DistribTerm)))
	:-	_areBeingMultiplied(Time, PlusTerm, DistribTerm),
		PlusTerm < DistribTerm, % TODO: this is necessary, but prevents distribute if C occurs before (a+b) term
		_isSumOfTerms(Time, PlusTerm).

% every term in original plus node, is multiplied by distributed term
_activateTempNode(Time, tempResultRoot, add)
	:-	_ruleForTimeStep(Time, canBeDistributed).

_treeOp(Time, TempNode, Term, DistribTerm, mul)
	:-	_operand(Time, DistribTerm, canBeDistributed, right),
		_operand(Time, PlusTerm, canBeDistributed, left),
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
	:-	_ruleForTimeStep(Time, canBeDistributed).


%================================================================================
% divByOne A/1 --> A
%================================================================================
_applicable(Time, _rule(canHaveItsDenominatorCancelled, _operands(Fraction)))
	:-	_denominatorOf(Time, Fraction, Denom),
		_isOne(Time, Denom).

_deepCopy(Time, Fraction, Numer)
	:-	_operand(Time, Fraction, canHaveItsDenominatorCancelled, left),
		_numeratorOf(Time, Fraction, Numer).
%================================================================================
% addZero A + 0 --> A
%================================================================================
_applicable(Time, _rule(canBeCancelled, _operands(Mono)))
	:-	_isZero(Time, Mono),
		_isBeingAdded(Time, Mono).

_cancelTerm(Time, ZeroTerm)
	:-	_operand(Time, ZeroTerm, canBeCancelled, left).

%================================================================================
% TODO: rewrite to generate better explanation
% factorMonom:	ax^k  --> bx^m * cx^n 
%================================================================================
% NOTE: this is the same rule as hasATermThatCanBeFactoredOut, except written specifically for monomials
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
_applicable(Time, _rule(hasATermThatCanBeFactoredOut, _operands(Poly)))
	:-	_isPolynomial(Time, Poly),
		_hasCommonCoeff(Time, Poly),
		_hasCommonDeg(Time, Poly).

% select common term to factor our
1 { _selectedCommonDeg(Time, Deg) : _hasCommonDeg(Time, Poly, Deg) } 1
	:-	_operand(Time, Poly, hasATermThatCanBeFactoredOut, left).
1 { _selectedCommonCoeff(Time, Coeff) : _hasCommonCoeff(Time, Poly, Coeff) } 1
	:-	_operand(Time, Poly, hasATermThatCanBeFactoredOut, left).
%%% CONSTRAINT: don't allow factoring out a 1
:-  _selectedCommonDeg(Time, 0), _selectedCommonCoeff(Time, 1).

% setup correct tree structure
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, hasATermThatCanBeFactoredOut).

% save monomial that we factored out
_setTempNodeToMono(Time, TempRight, Deg, Coeff)
	:-	_ruleForTimeStep(Time, hasATermThatCanBeFactoredOut),
		_tempChildOnSide(tempResultRoot, TempRight, right),
		_selectedCommonDeg(Time, Deg),
		_selectedCommonCoeff(Time, Coeff).
% perform the division
_activateTempNode(Time, TempLeft, add)
	:-	_ruleForTimeStep(Time, hasATermThatCanBeFactoredOut),
		_tempChildOnSide(tempResultRoot, TempLeft, left).
_originalMonoTerm(Time, Mono, Num)	% isolate monomial terms
	:-	_operand(Time, Poly, hasATermThatCanBeFactoredOut, left),
		_isATermOf(Time, Poly, Mono),
		_childNum(Poly, Mono, Num).
_newMonoTerm(Time, TempChild, Num)
	:-	_tempChildOnSide(tempResultRoot, TempLeft, left),
		_originalMonoTerm(Time, Mono, Num),
		_tempChildNum(TempLeft, TempChild, Num).

_tempHolds(Time, _fact(TempLeft, _nodeField(activechild, TempTerm)))
	:-	_ruleForTimeStep(Time, hasATermThatCanBeFactoredOut),
		_tempChildOnSide(tempResultRoot, TempLeft, left),
		_newMonoTerm(Time, TempTerm, Num).
_activateTempNode(Time, TempTerm, mono)
	:-	_ruleForTimeStep(Time, hasATermThatCanBeFactoredOut),
		_newMonoTerm(Time, TempTerm, Num).
% set the new coeff and deg values
_tempHolds(Time, _fact(TempTerm, _nodeField(coeff, NewCoeff)))
	:-	_ruleForTimeStep(Time, hasATermThatCanBeFactoredOut),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_isTheCoefficientOf(Time, Mono, MonoCoeff),
		_selectedCommonCoeff(Time, CommonCoeff),
		_coeffFactorPairOf(CommonCoeff, NewCoeff, MonoCoeff).

_tempHolds(Time, _fact(TempTerm, _nodeField(degree, NewDeg)))
	:-	_ruleForTimeStep(Time, hasATermThatCanBeFactoredOut),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_isTheDegreeOf(Time, Mono, MonoDeg),
		_selectedCommonDeg(Time, CommonDeg),
		NewDeg = MonoDeg - CommonDeg.

% save result
_setResultTo(Time, Poly)
	:-	_operand(Time, Poly, hasATermThatCanBeFactoredOut, left).

%================================================================================
% multByZero:	A*0 --> 0
%================================================================================
_applicable(Time, _rule(isEqualToZero, _operands(ZeroTerm)))
	:-	_isZero(Time, ZeroTerm),
		_isBeingMultiplied(Time, ZeroTerm).

_setToZero(Time, Parent)
	:-	_operand(Time, ZeroTerm, isEqualToZero, left),
		_isATermOf(Time, Parent, ZeroTerm).

%================================================================================
% multIdentity:	A*1 --> A
%================================================================================
_applicable(Time, _rule(canBeIgnored, _operands(UnitTerm)))
	:-	_isOne(Time, UnitTerm),
        _areBeingMultiplied(Time, OtherTerm, UnitTerm),
        not __isMono(Time, OtherTerm).  % for monomials we use the mono multiply rule
_cancelTerm(Time, UnitTerm)
	:-	_operand(Time, UnitTerm, canBeIgnored, left).

%================================================================================
% TODO: rewrite to generate better explanation
%           should isPolynomial be used to choose what we multiply by??
% multNumerAndDenom:	A/B --> (A*C)/(B*C)
%================================================================================
% NOTE: This rule requres max tree depth to be at least 4, otherwise the generated
% expression is too large and we get a node overflow.
% Additionally, we can only multiply expression by a polynomial expression already existing
% somewhere in the equation
_applicable(Time, _rule(numeratorAndDenominatorCanBeMultipliedBySameTerm, _operands(Fraction, Term)))
	:-	_isFraction(Time, Fraction),
		__isActive(Time, Term).

% set root to div
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, numeratorAndDenominatorCanBeMultipliedBySameTerm).

% multiply numer
_treeOp(Time, TempNode, Numer, Poly, mul)
	:-	_operandNumer(Time, Numer, numeratorAndDenominatorCanBeMultipliedBySameTerm, left),
		_operand(Time, Poly, numeratorAndDenominatorCanBeMultipliedBySameTerm, right),
		_tempChildOnSide(tempResultRoot, TempNode, left).

% multiply denom
_treeOp(Time, TempNode, Denom, Poly, mul)
	:-	_operandDenom(Time, Denom, numeratorAndDenominatorCanBeMultipliedBySameTerm, left),
		_operand(Time, Poly, numeratorAndDenominatorCanBeMultipliedBySameTerm, right),
		_tempChildOnSide(tempResultRoot, TempNode, right).

% save the result
_setResultTo(Time, Fraction)
	:-	_operand(Time, Fraction, numeratorAndDenominatorCanBeMultipliedBySameTerm, left).

%================================================================================
% cancelNegatives: -(-A) --> A
%================================================================================
_applicable(Time, _rule(areBothNegativeOperationsThatCancelOut, _operands(Parent, Child)))
	:-	_isATermOf(Time, Parent, Child),
		_isNeg(Time, Parent),
		_isNeg(Time, Child).

_deepCopy(Time, GrandParent, GrandChild)
	:-	_operand(Time, GrandParent, areBothNegativeOperationsThatCancelOut, left),
		_operand(Time, Parent, areBothNegativeOperationsThatCancelOut, right),
		_isATermOf(Time, Parent, GrandChild).

%================================================================================
% distributeNegative: -(a + b) --> -a - b
%================================================================================
_applicable(Time, _rule(negationCanBeDistributed, _operands(Node, Node)))
	:-	_isASingleTermOrSumOfTerms(Time, Node),
		_isBeingNegated(Time, Node).

			%%% negating nodes
% mono case
_setTempNodeToMono(Time, tempResultRoot, Deg, NegatedCoeff)
	:-	_operand(Time, RootNode, negationCanBeDistributed, left),
		__isMono(Time, RootNode),
		_isTheCoefficientOf(Time, RootNode, Coeff),
        NegatedCoeff = Coeff*-1,
		_isTheDegreeOf(Time, RootNode, Deg).
% add operator case
_treeOp(Time, tempResultRoot, RootNode, RootNode, negateChildren)
	:-	_operand(Time, RootNode, negationCanBeDistributed, left),
		_isSumOfTerms(Time, RootNode).
    
% save the result
_setResultTo(Time, Parent)
	:-	_operand(Time, RootNode, negationCanBeDistributed, left),
		_isATermOf(Time, Parent, RootNode).
%================================================================================
% negativeSignCanBePassedToChildOf:          -(a*b*c) --> -a*b*c
%================================================================================
_applicable(Time, _rule(negativeSignCanBePassedToTermOf, _operands(Node, Child)))
	:-	_mulOrDiv(Time, Node),
		_isBeingNegated(Time, Node),
		_isATermOf(Time, Node, Child).
% div or mul case
_treeOp(Time, tempResultRoot, RootNode, Child, negateSingleChild)
	:-	_operand(Time, RootNode, negativeSignCanBePassedToTermOf, left),
		_operand(Time, Child, negativeSignCanBePassedToTermOf, right),
		_mulOrDiv(Time, RootNode).

% save the result
_setResultTo(Time, Parent)
	:-	_operand(Time, RootNode, negativeSignCanBePassedToTermOf, left),
		_isATermOf(Time, Parent, RootNode).

%================================================================================
% cancelSumTerm: A + B = A + C --> B = C
%================================================================================
_applicable(Time, _rule(areTermsThatCanBeCancelled, _operands(LeftChild, RightChild)))
	:-	_isSumOfTerms(Time, leftSide),
		_isSumOfTerms(Time, rightSide),
		_isATermOf(Time, leftSide, LeftChild),
		_isATermOf(Time, rightSide, RightChild),
		_areEqual(Time, LeftChild, RightChild).
_cancelTerm(Time, Node)
	:-	_operand(Time, Node, areTermsThatCanBeCancelled, Side).

%================================================================================
% addInverses: A + -A --> 0 
%================================================================================
_applicable(Time, _rule(addUpToZero, _operands(SndSibling, FstSibling)))
	:-	_areBeingAdded(Time, FstSibling, SndSibling),
		_isNeg(Time, SndSibling),
		_isATermOf(Time, SndSibling, Child),
		_areEqual(Time, FstSibling, Child).

% we know the result is zero, writeBinaryOp handles the rewrite 
_setTempNodeToMono(Time, tempResultRoot, 0, 0)	
	:-	_ruleForTimeStep(Time, addUpToZero).
_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, addUpToZero).

%================================================================================
% TODO: rewrite to generate better explanation
% subtractFromEqn: A = B  --> A - D = B - D
%================================================================================
_applicable(Time, _rule(canBeSubtractedFromTheEquation, _operands(Node)))
	:-	__isMono(Time, Node),
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
_applicable(Time, _rule(canBeMultipliedAcrossBothSidesOfTheEquation, _operands(Denom)))
	:-	__rootNode(EqnSide),
        _isFraction(Time, EqnSide),
        _denominatorOf(Time, EqnSide, Denom),
        not _isOne(Time, Denom).
_eqnOp(Time, Operand, mul)
	:-	_operand(Time, Operand, canBeMultipliedAcrossBothSidesOfTheEquation, left).
% save the results
_saveEqnResult(Time)
	:-	_ruleForTimeStep(Time, canBeMultipliedAcrossBothSidesOfTheEquation).

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
_applicable(Time, _rule(decreaseDeg, _operands(leftSide)))
	:-	_equationHasNonConstantTerms(Time),
        _canDivideEveryDegree(Time, Deg).
_update(Time, Node, degree, ResultDeg)
	:-	_ruleForTimeStep(Time, decreaseDeg),
		_smallestNonZeroDeg(Time, DividingDeg),
		_isTheDegreeOf(Time, Node, OrigDeg),
		OrigDeg != 0,
		_degProduct(OrigDeg, DividingDeg, ResultDeg).

_canDivideEveryDegree(Time, Deg)
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
_applicable(Time, _rule(fractionCanBeMultipliedWithNonFraction, _operands(Fraction, NotFraction)))
	:-	_areBeingMultiplied(Time, Fraction, NotFraction),
		_isFraction(Time, Fraction),
		not _isFraction(Time, NotFraction).
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, fractionCanBeMultipliedWithNonFraction).
_treeOp(Time, FstChild, Numer, NotFraction, append(mul))
	:-	_operand(Time, Fraction, fractionCanBeMultipliedWithNonFraction, left),
		_numeratorOf(Time, Fraction, Numer),
		_operand(Time, NotFraction, fractionCanBeMultipliedWithNonFraction, right),
		_tempChildNum(tempResultRoot, FstChild, 1).
_deepCopy(Time, SndChild, Denom)
	:-	_operand(Time, Fraction, fractionCanBeMultipliedWithNonFraction, left),
		_denominatorOf(Time, Fraction, Denom),
		_tempChildNum(tempResultRoot, SndChild, 2).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, fractionCanBeMultipliedWithNonFraction).

%% Rules Listed: Used to generate default rule heuristics
_rule(hasNumeratorAndDenominatorThatCancel).
_rule(canBeMultipliedAsFractions).
_rule(canBeMultipliedByInverseOf).
_rule(canBeReducedToItsNumerator).
_rule(canBeAddedTogether).
_rule(canBeMultipliedTogether).
_rule(areFactorsThatCancel).
_rule(canBeFactored).
_rule(canBeAddedAsOneFraction).
_rule(canBeDistributed).
_rule(canHaveItsDenominatorCancelled).
_rule(canBeCancelled).
_rule(isATermThatCanBeFactored).
_rule(hasATermThatCanBeFactoredOut).
_rule(isEqualToZero).
_rule(canBeIgnored).
_rule(numeratorAndDenominatorCanBeMultipliedBySameTerm).
_rule(areBothNegativeOperationsThatCancelOut).
_rule(negationCanBeDistributed).
_rule(negationCanBeDistributed).
_rule(areTermsThatCanBeCancelled).
_rule(addUpToZero).
_rule(canBeSubtractedFromTheEquation).
_rule(canBeMultipliedAcrossBothSidesOfTheEquation).
_rule(canDivideBothSidesOfTheEquation).
_rule(decreaseDeg).
_rule(fractionCanBeMultipliedWithNonFraction).
_rule(negativeSignCanBePassedToTermOf).

