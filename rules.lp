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
		_denomOf(Time, Frac, Denom).
_operandNumer(Time, Numer, RuleName, Side)
	:-	_operand(Time, Frac, RuleName, Side),
		_numerOf(Time, Frac, Numer).

% writing result of a binary operation
% _writeBinaryOp/1. must be generated explicitly to write result as a binary operation
_writeBinaryOp(Time, Fst, Snd)
	:-	_operand(Time, Fst, Operation, left),
		_operand(Time, Snd, Operation, right),
		_writeBinaryOp(Time).


%================================================================================
% divIdentity: A / A ----> 1
%================================================================================
% NOTE: applicable only to subtrees over which equality is defined
_applicable(Time, _rule(divIdent, _operands(Fraction)))
	:-	_isDiv(Time, Fraction),
		_numerOf(Time, Fraction, Numer),
		_denomOf(Time, Fraction, Denom),
		_equal(Time, Numer, Denom).
_setToOne(Time, Fraction)
	:-	_operand(Time, Fraction, divIdent, left).

%================================================================================
% multFrac: a/b * c/d --> (a*c)/(b*d)
%================================================================================
_applicable(Time, _rule(multFrac, _operands(LeftFrac, RightFrac)))
	:-	_isDiv(Time, LeftFrac),
		_isDiv(Time, RightFrac),
		LeftFrac < RightFrac,
		_siblings(Time, LeftFrac, RightFrac),
		_parentType(Time, LeftFrac, mul).

% set result as a fraction with numer and denom as fractions
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, multFrac).
_treeOp(Time, TempNumer, FstNumer, SndNumer, mul)
	:-	_tempChildOnSide(tempResultRoot, TempNumer, left),
		_operandNumer(Time, FstNumer, multFrac, left),
		_operandNumer(Time, SndNumer, multFrac, right).
_treeOp(Time, TempDenom, FstDenom, SndDenom, mul)
	:-	_tempChildOnSide(tempResultRoot, TempDenom, right),
		_operandDenom(Time, FstDenom, multFrac, left),
		_operandDenom(Time, SndDenom, multFrac, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, multFrac).

%================================================================================
% fracDiv: a/c / b/d --> a/c * d/b
%================================================================================
_applicable(Time, _rule(fracDiv, _operands(NumerFrac, DenomFrac)))
			:-	_siblings(Time, NumerFrac, DenomFrac),
				_isDiv(Time, NumerFrac),
				_isDiv(Time, DenomFrac),
				NumerFrac < DenomFrac, % to ensure NumerFrac actually corresponds to numerator
				_parentType(Time, NumerFrac, div).

% set root node to multiplication node
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, fracDiv).
% 'left' fraction remains unchanged
_deepCopy(Time, LeftTemp, NumerFrac)
	:-	_tempChildOnSide(tempResultRoot, LeftTemp, left),
		_ruleForTimeStep(Time, fracDiv),
		_operand(Time, NumerFrac, fracDiv, left).
% flip numer/denom fields
_treeOp(Time, RightTemp, Numer, Denom, reciprocal)
	:-	_operand(Time, DenomFrac, fracDiv, right),
		_numerOf(Time, DenomFrac, Numer),
		_denomOf(Time, DenomFrac, Denom),
		_tempChildOnSide(tempResultRoot, RightTemp, right).

_setResultTo(Time, Root)
	:-	_operand(Time, DenomFrac, fracDiv, right),
		_activeChild(Time, Root, DenomFrac).

%================================================================================
% ignore denominator: a / b = 0 --> a = 0
%================================================================================
_applicable(Time, _rule(numerSimp, _operands(leftSide)))
	:-	_isZero(Time, rightSide),
		_isDiv(Time, leftSide).

% assumes that fraction is poly/poly
_deepCopy(Time, tempResultRoot, Numer)
	:-	_operand(Time, Frac, numerSimp, left),
		_numerOf(Time, Frac, Numer).
_setResultTo(Time, leftSide)
	:-	_ruleForTimeStep(Time, numerSimp).


%================================================================================
% addMonom: a*x^b + c*x^b ----> (a+c)*x^b
%================================================================================
% TODO: contains as a special case:		addIdentity: a*x^b + 0 ----> a*x^b 
% is this problematic?

_applicable(Time, _rule(addMonom, _operands(LeftMono, RightMono)))
	:-	_siblings(Time, LeftMono, RightMono),
		_equalDegs(Time, LeftMono, RightMono),
		_isMono(Time, LeftMono),
		_isMono(Time, RightMono),
		LeftMono < RightMono,
		_parentType(Time, LeftMono, add).

_monoOp(Time, tempResultRoot, LeftMono, RightMono, add)
	:-	_operand(Time, LeftMono, addMonom, left),
		_operand(Time, RightMono, addMonom, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, addMonom).

%================================================================================
% monomult ax^b  * cx^d --> (a*c)x^(b+d)
%================================================================================
_applicable(Time, _rule(monoMult, _operands(LeftMono, RightMono)))
	:-	_siblings(Time, LeftMono, RightMono),
		_isMono(Time, LeftMono),
		_isMono(Time, RightMono),
		LeftMono < RightMono,
		_parentType(Time, LeftMono, mul).
 
_monoOp(Time, tempResultRoot, LeftMono, RightMono, mul)
	:-	_operand(Time, LeftMono, monoMult, left),
		_operand(Time, RightMono, monoMult, right).

_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, monoMult).

%================================================================================
% fracCancel A*B/C*B --> A/C
%================================================================================
% NOTE: relies on equal/3 predicate to work
_applicable(Time, _rule(fracCancel, _operands(FstNode, SndNode)))
	:-	_haveCommonFactors(Time, FstNode, SndNode),
		_siblings(Time, FstNode, SndNode),
		_isMul(Time, FstNode),
		_isMul(Time, SndNode),
		_parentType(Time, FstNode, div),
		FstNode < SndNode. % ensure numerator comes first

% select a common factor and then cancel it
1 { _factorsToCancel(Time, NumerFactor, DenomFactor) : 
		_factorOf(Time, Numer, NumerFactor), 
		_factorOf(Time, Denom, DenomFactor),
		_equal(Time, NumerFactor, DenomFactor) } 1
	:-	_operand(Time, Numer, fracCancel, left),
		_operand(Time, Denom, fracCancel, right).
_cancelTerm(Time, Fst)
	:-	_factorsToCancel(Time, Fst, Snd).
_cancelTerm(Time, Snd)
	:-	_factorsToCancel(Time, Fst, Snd).

%================================================================================
% factor (x^2 + bx + c) --> (x + e) * (x + d)
%================================================================================
% NOTE: squared term must have coeff 1, divide by constant my be required to reach 
% this form
_applicable(Time, _rule(factor, _operands(Node)))
	:-	_isPolynomial(Time, Node),
		_isQuadratic(Time, Node),
		_isFactorable(Time, Node).

% select the factors to use
_factorsForBinomials(Time, FstFactor, SndFactor)
	:-	_operand(Time, Poly,  factor, left),
		_monoTermOfPoly(Time, Poly, 1, LinearTerm),
		_monoTermOfPoly(Time, Poly, 0, ConstTerm),
		_factors(FstFactor, SndFactor, LinearTerm, ConstTerm),
		FstFactor <= SndFactor. % NOTE: sanity check, ensure this rule is used @ most once per time step
% result is product of two binomials
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, factor).

% initialize binomials
_setToBinomial(Time, LeftChild, FstFactor)
	:-	_tempChildNum(tempResultRoot, LeftChild, 1),
		_factorsForBinomials(Time, FstFactor, SndFactor).
_setToBinomial(Time, RightChild, SndFactor)
	:-	_tempChildNum(tempResultRoot, RightChild, 2),
		_factorsForBinomials(Time, FstFactor, SndFactor).

% save the result of factoring
_setResultTo(Time, Poly)
	:-	_operand(Time, Poly,  factor, left).


%================================================================================
% addSameFrac A/B + C/B --> (A+C)/B
%================================================================================
% NOTE: _sameDenom depends on equals/3 predicate (which applies only to monomials)
_applicable(Time, _rule(addSameFrac, _operands(Fst, Snd)))
	:-	_siblings(Time, Fst, Snd),
		_sameDenom(Time, Fst, Snd),
		Fst < Snd,
		_parentType(Time, Fst, add).

% set root to a fraction
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, addSameFrac).

% set numerator to a sum
_treeOp(Time, TempNumer, FstNumer, SndNumer, add)
	:-	_tempChildNum(tempResultRoot, TempNumer, 1),
		_operandNumer(Time, FstNumer, addSameFrac, left),
		_operandNumer(Time, SndNumer, addSameFrac, right).
% set denom 
_deepCopy(Time, TempDenom, FstDenom)
	:-	_tempChildNum(tempResultRoot, TempDenom, 2),
		_operandDenom(Time, FstDenom, addSameFrac, left).
% save result
_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, addSameFrac).
	
%================================================================================
% addDiffFrac A/B + C/D --> (A*D+C*B)/B*D
%================================================================================
% NOTE: requires max depth of allowable expression trees to be at least 4 
% NOTE: also dependent on equal/3 predicate
_applicable(Time, _rule(addDiffFrac, _operands(Fst, Snd)))
	:-	_siblings(Time, Fst, Snd),
		_isDiv(Time, Fst),
		_isDiv(Time, Snd),
		Fst < Snd, 
		_parentType(Time, Fst, add).

% set root to a fraction
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, addDiffFrac).

% set numer to sum of products
_activateTempAndSetChildren(Time, Numer, add, 2)
	:-	_ruleForTimeStep(Time, addDiffFrac),
		_tempChildNum(tempResultRoot, Numer, 1).

_treeOp(Time, FstProd, FstNumer, SndDenom, mul)
	:-	_tempChildNum(tempResultRoot, Numer, 1),
		_tempChildNum(Numer, FstProd, 1),
		_operandNumer(Time, FstNumer, addDiffFrac, left),
		_operandDenom(Time, SndDenom, addDiffFrac, right).

_treeOp(Time, SndProd, SndNumer, FstDenom, mul)
	:-	_tempChildNum(tempResultRoot, Numer, 1),
		_tempChildNum(Numer, SndProd, 2),
		_operandNumer(Time, SndNumer, addDiffFrac, right),
		_operandDenom(Time, FstDenom, addDiffFrac, left).

% set denominator to product of two original numerators
_treeOp(Time, RootDenom, FstDenom, SndDenom, mul)
	:-	_tempChildNum(tempResultRoot, RootDenom, 2),
		_operandDenom(Time, FstDenom, addDiffFrac, left),
		_operandDenom(Time, SndDenom, addDiffFrac, right).
% save result
_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, addDiffFrac).

%================================================================================
% distribute (a + b) * C --> (a*C + b*C)
%================================================================================
_applicable(Time, _rule(distribute, _operands(PlusTerm, DistribTerm)))
	:-	_siblings(Time, PlusTerm, DistribTerm),
		_parentType(Time, PlusTerm, mul),
		PlusTerm < DistribTerm, % TODO: this is necessary, but prevents distribute if C occurs before (a+b) term
		_isAdd(Time, PlusTerm).

% every term in original plus node, is multiplied by distributed term
_activateTempNode(Time, tempResultRoot, add)
	:-	_ruleForTimeStep(Time, distribute).

_treeOp(Time, TempNode, Term, DistribTerm, mul)
	:-	_operand(Time, DistribTerm, distribute, right),
		_operand(Time, PlusTerm, distribute, left),
		_activeChild(Time, PlusTerm, Term),
		_childNum(PlusTerm, Term, ChildNum),
		_tempChildNum(tempResultRoot, TempNode, ChildNum).

% setup parent child links 
% NOTE: must be done explicitly b/c there may be gaps between active children
_tempHolds(Time, _fact(tempResultRoot, _nodeField(activechild, Temp)))
	:-	_tempHolds(Time, _fact(Temp, _nodeField(active, yes))),
		_validTempChildOf(tempResultRoot, Temp).
% save result
_writeBinaryOp(Time)
	:-	_ruleForTimeStep(Time, distribute).


%================================================================================
% divByOne A/1 --> A
%================================================================================
_applicable(Time, _rule(divByOne, _operands(Fraction)))
	:-	_denomOf(Time, Fraction, Denom),
		_isOne(Time, Denom).

_deepCopy(Time, Fraction, Numer)
	:-	_operand(Time, Fraction, divByOne, left),
		_numerOf(Time, Fraction, Numer).
%================================================================================
% addZero A + 0 --> A
%================================================================================
_applicable(Time, _rule(addZero, _operands(Mono)))
	:-	_isZero(Time, Mono),
		_parentType(Time, Mono, add).

_cancelTerm(Time, ZeroTerm)
	:-	_operand(Time, ZeroTerm, addZero, left).

%================================================================================
% factorMonom:	ax^k  --> bx^m * cx^n 
%================================================================================
% NOTE: this is the same rule as factorCommTerm, except written specifically for monomials
_applicable(Time, _rule(factorMonom, _operands(Mono)))
	:-	_isMono(Time, Mono),
		not _isOne(Time, Mono),
		not _isZero(Time, Mono).
% select coefficient factors,
1 { _selectedCoeffFactors(Time, FstFactor, SndFactor) 
		: _factors(FstFactor, SndFactor, FactorSum, Coeff) } 1
	:-	_operand(Time, Mono, factorMonom, left),
		_coeffOf(Time, Mono, Coeff).
% select degree factors
1 { _selectedDegDecomposition(Time, Fst, Snd) 
		: _degree(Fst), _degree(Snd),
			MonoDeg = Fst + Snd } 1
	:-	_operand(Time, Mono, factorMonom, left),
		_degOf(Time, Mono, MonoDeg).
% form product of monomials (careful with code reuse here!!)
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, factorMonom).
_setTempNodeToMono(Time, LeftChild, FstDeg, FstCoeff)
	:-	_ruleForTimeStep(Time, factorMonom),
		_tempChildOnSide(tempResultRoot, LeftChild, left),
		_selectedCoeffFactors(Time, FstCoeff, SndCoeff),
		_selectedDegDecomposition(Time, FstDeg, SndDeg).
_setTempNodeToMono(Time, RightChild, SndDeg, SndCoeff)
	:-	_ruleForTimeStep(Time, factorMonom),
		_tempChildOnSide(tempResultRoot, RightChild, right),
		_selectedCoeffFactors(Time, FstCoeff, SndCoeff),
		_selectedDegDecomposition(Time, FstDeg, SndDeg).
% save result 
_setResultTo(Time, Mono)
	:-	_operand(Time, Mono, factorMonom, left).

%================================================================================
% factorCommTerm:	(a*x^k + b*x^l ) --> (a*x^m + b*x^n ) * x^j
%================================================================================
_applicable(Time, _rule(factorCommTerm, _operands(Poly)))
	:-	_isPolynomial(Time, Poly),
		_hasCommonCoeff(Time, Poly),
		_hasCommonDeg(Time, Poly).

% select common term to factor our
1 { _selectedCommonDeg(Time, Deg) : _hasCommonDeg(Time, Poly, Deg) } 1
	:-	_operand(Time, Poly, factorCommTerm, left).
1 { _selectedCommonCoeff(Time, Coeff) : _hasCommonCoeff(Time, Poly, Coeff) } 1
	:-	_operand(Time, Poly, factorCommTerm, left).

% setup correct tree structure
_activateTempAndSetChildren(Time, tempResultRoot, mul, 2)
	:-	_ruleForTimeStep(Time, factorCommTerm).

% save monomial that we factored out
_setTempNodeToMono(Time, TempRight, Deg, Coeff)
	:-	_ruleForTimeStep(Time, factorCommTerm),
		_tempChildOnSide(tempResultRoot, TempRight, right),
		_selectedCommonDeg(Time, Deg),
		_selectedCommonCoeff(Time, Coeff).
% perform the division
_activateTempNode(Time, TempLeft, add)
	:-	_ruleForTimeStep(Time, factorCommTerm),
		_tempChildOnSide(tempResultRoot, TempLeft, left).
_originalMonoTerm(Time, Mono, Num)	% isolate monomial terms
	:-	_operand(Time, Poly, factorCommTerm, left),
		_activeChild(Time, Poly, Mono),
		_childNum(Poly, Mono, Num).
_newMonoTerm(Time, TempChild, Num)
	:-	_tempChildOnSide(tempResultRoot, TempLeft, left),
		_originalMonoTerm(Time, Mono, Num),
		_tempChildNum(TempLeft, TempChild, Num).

_tempHolds(Time, _fact(TempLeft, _nodeField(activechild, TempTerm)))
	:-	_ruleForTimeStep(Time, factorCommTerm),
		_tempChildOnSide(tempResultRoot, TempLeft, left),
		_newMonoTerm(Time, TempTerm, Num).
_activateTempNode(Time, TempTerm, mono)
	:-	_ruleForTimeStep(Time, factorCommTerm),
		_newMonoTerm(Time, TempTerm, Num).
% set the new coeff and deg values
_tempHolds(Time, _fact(TempTerm, _nodeField(coeff, NewCoeff)))
	:-	_ruleForTimeStep(Time, factorCommTerm),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_coeffOf(Time, Mono, MonoCoeff),
		_selectedCommonCoeff(Time, CommonCoeff),
		_coeffFactorPairOf(CommonCoeff, NewCoeff, MonoCoeff).

_tempHolds(Time, _fact(TempTerm, _nodeField(degree, NewDeg)))
	:-	_ruleForTimeStep(Time, factorCommTerm),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_degOf(Time, Mono, MonoDeg),
		_selectedCommonDeg(Time, CommonDeg),
		NewDeg = MonoDeg - CommonDeg.

% save result
_setResultTo(Time, Poly)
	:-	_operand(Time, Poly, factorCommTerm, left).

%================================================================================
% multByZero:	A*0 --> 0
%================================================================================
_applicable(Time, _rule(multByZero, _operands(ZeroTerm)))
	:-	_isZero(Time, ZeroTerm),
		_parentType(Time, ZeroTerm, mul).

_setToZero(Time, Parent)
	:-	_operand(Time, ZeroTerm, multByZero, left),
		_activeChild(Time, Parent, ZeroTerm).

%================================================================================
% multIdentity:	A*1 --> A
%================================================================================
_applicable(Time, _rule(multIdentity, _operands(UnitTerm)))
	:-	_isOne(Time, UnitTerm),
		_parentType(Time, UnitTerm, mul).
_cancelTerm(Time, UnitTerm)
	:-	_operand(Time, UnitTerm, multIdentity, left).

%================================================================================
% multNumerAndDenom:	A/B --> (A*C)/(B*C)
%================================================================================
% NOTE: This rule requres max tree depth to be at least 4, otherwise the generated
% expression is too large and we get a node overflow.
% Additionally, we can only multiply expression by a polynomial expression already existing
% somewhere in the equation
_applicable(Time, _rule(multNumerAndDenom, _operands(Fraction, Poly)))
	:-	_isDiv(Time, Fraction),
		_isPolynomial(Time, Poly).

% set root to div
_activateTempAndSetChildren(Time, tempResultRoot, div, 2)
	:-	_ruleForTimeStep(Time, multNumerAndDenom).

% multiply numer
_treeOp(Time, TempNode, Numer, Poly, mul)
	:-	_operandNumer(Time, Numer, multNumerAndDenom, left),
		_operand(Time, Poly, multNumerAndDenom, right),
		_tempChildOnSide(tempResultRoot, TempNode, left).

% multiply denom
_treeOp(Time, TempNode, Denom, Poly, mul)
	:-	_operandDenom(Time, Denom, multNumerAndDenom, left),
		_operand(Time, Poly, multNumerAndDenom, right),
		_tempChildOnSide(tempResultRoot, TempNode, right).

% save the result
_setResultTo(Time, Fraction)
	:-	_operand(Time, Fraction, multNumerAndDenom, left).

%================================================================================
% addMonoToEqn:	A = B --> A + e = B + e
%================================================================================
_applicable(Time, _rule(addMonoToEqn, _operands(leftSide, rightSide)))
	:-	_validTime(Time).	

% select an arbitrary degree and coefficient
1 { _selectedDeg(Time, Deg) : _degree(Deg) } 1
	:-	_ruleForTimeStep(Time, addMonoToEqn).
1 { _selectedCoeff(Time, Coeff) : _coeff(Coeff) } 1
	:-	_ruleForTimeStep(Time, addMonoToEqn).

_eqnMonoOp(Time, Coeff, Deg, add)
	:-	_ruleForTimeStep(Time, addMonoToEqn),
		_selectedDeg(Time, Deg),
		_selectedCoeff(Time, Coeff).

% save the results
_deepCopy(Time, leftSide, tempResultRoot)
	:-	_ruleForTimeStep(Time, addMonoToEqn).
_deepCopy(Time, rightSide, tempRightRoot)
	:-	_ruleForTimeStep(Time, addMonoToEqn).

%================================================================================
% multEqnWithMono:	A = B --> A * e = B * e
%================================================================================
_applicable(Time, _rule(multEqnWithMono, _operands(leftSide, rightSide)))
	:-	_validTime(Time).	

% select an arbitrary degree and coefficient
1 { _selectedDeg(Time, Deg) : _degree(Deg) } 1
	:-	_ruleForTimeStep(Time, multEqnWithMono).
1 { _selectedCoeff(Time, Coeff) : _coeff(Coeff) } 1
	:-	_ruleForTimeStep(Time, multEqnWithMono).

_eqnMonoOp(Time, Coeff, Deg, mul)
	:-	_ruleForTimeStep(Time, multEqnWithMono),
		_selectedDeg(Time, Deg),
		_selectedCoeff(Time, Coeff).

% save the results
_deepCopy(Time, leftSide, tempResultRoot)
	:-	_ruleForTimeStep(Time, multEqnWithMono).
_deepCopy(Time, rightSide, tempRightRoot)
	:-	_ruleForTimeStep(Time, multEqnWithMono).

%================================================================================
% swapTerms: A*B --> B*A, or A+B --> B*A	
%================================================================================
_applicable(Time, _rule(swapTerms, _operands(FstTerm, SndTerm)))
	:-	_swappableTerms(Time, FstTerm, SndTerm),
		not _equal(Time, FstTerm, SndTerm).	% NOTE: swapping equal terms is basically a NO-OP

_deepCopy(Time, FstTerm, SndTerm)
	:-	_operand(Time, FstTerm, swapTerms, left),
		_operand(Time, SndTerm, swapTerms, right),
		_siblings(Time, FstTerm, SndTerm).	% specify operands are siblings to avoid excessively large grounding

_deepCopy(Time, SndTerm, FstTerm)
	:-	_operand(Time, FstTerm, swapTerms, left),
		_operand(Time, SndTerm, swapTerms, right),
		_siblings(Time, FstTerm, SndTerm).

%================================================================================
% cancelNegatives: -(-A) --> A
%================================================================================
_applicable(Time, _rule(cancelNegatives, _operands(Parent, Child)))
	:-	_activeChild(Time, Parent, Child),
		_isNeg(Time, Parent),
		_isNeg(Time, Child).

_deepCopy(Time, GrandParent, GrandChild)
	:-	_operand(Time, GrandParent, cancelNegatives, left),
		_operand(Time, Parent, cancelNegatives, right),
		_activeChild(Time, Parent, GrandChild).

%================================================================================
% percolateNeg: -(a + b) --> -a - b         -(a*b*c) --> -a*b*c
%================================================================================
%%_applicable(Time, _rule(percolateNeg, _operands(Node, Child)))%%
	%%:-	_hasType(Time, Node, Type),%%
		%%_mulOrDiv(Type),%%
		%%_parentType(Time, Node, neg),%%
		%%_activeChild(Time, Node, Child).%%
_applicable(Time, _rule(percolateNeg, _operands(Node, Node)))
	:-	_addOrMono(Time, Node),
		_isMono(Time, Node),
		_parentType(Time, Node, neg).

% mono case:
_negateNode(Time, tempResultRoot, RootNode)
	:-	_operand(Time, RootNode, percolateNeg, left),
		_addOrMono(Time, RootNode).

			%%% negating nodes
% mono case
_setTempNodeToMono(Time, Temp, Deg, Coeff*-1)
	:-	_negateNode(Time, Temp, Node),
		_isMono(Time, Node),
		_coeffOf(Time, Node, Coeff),
		_degOf(Time, Node, Deg).
% add case
_copyAttributes(Time, Temp, Node)
	:-	_negateNode(Time, Temp, Node).
_copyChildStructure(Time, Temp, Node)
	:-	_negateNode(Time, Temp, Node).

_negateNode(Time, TempChild, Child)
	:-	_negateNode(Time, Temp, Node),
		_activeChild(Time, Node, Child),
		_childNum(Node, Child, Num),
		_tempChildNum(Temp, TempChild, Num).

% save the result
_setResultTo(Time, Parent)
	:-	_operand(Time, RootNode, percolateNeg, left),
		_activeChild(Time, Parent, RootNode).

% determine if temp Node is same as 
:- not _ruleForTimeStep(_time(0,1), percolateNeg).
%%:- not _hasType(initially, leftSide, neg).%%
