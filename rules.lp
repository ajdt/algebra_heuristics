% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file defines rules and their rewrite actions on an equation.
% A rule is applicable at a particular time step for a particular solution.
% These rules are used by eqn_solver.lp to solve a generated problem
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EXTRACTING RULE OPERANDS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% most operations are either binary or unary
_operand(Time, OnlyOper, oper(Name, left))
	:-	_doAction(Time, _action(Name, _data(OnlyOper))).
_operand(Time, Fst, oper(Name, left))
	:-	_doAction(Time, _action(Name, _data(Fst, Snd))).
_operand(Time, Snd, oper(Name, right))
	:-	_doAction(Time, _action(Name, _data(Fst, Snd))).
_operandDenom(Time, Denom, Operation)
	:-	_operand(Time, Frac, Operation),
		_denomOf(Time, Frac, Denom).
_operandNumer(Time, Numer, Operation)
	:-	_operand(Time, Frac, Operation),
		_numerOf(Time, Frac, Numer).

% writing result of a binary operation
% _writeBinaryOp/1. must be generated explicitly to write result as a binary operation
_writeBinaryOp(Time, Fst, Snd)
	:-	_operand(Time, Fst, oper(Operation, left)),
		_operand(Time, Snd, oper(Operation, right)),
		_writeBinaryOp(Time).


%================================================================================
% divIdentity: A / A ----> 1
%================================================================================
% NOTE: applicable only to subtrees over which equality is defined
_applicable(Time, _action(divIdent, _data(Fraction)))
	:-	_isDiv(Time, Fraction),
		_numerOf(Time, Fraction, Numer),
		_denomOf(Time, Fraction, Denom),
		_equal(Time, Numer, Denom).
_setToOne(Time, Fraction)
	:-	_operand(Time, Fraction, oper(divIdent, left)).

%================================================================================
% multFrac: a/b * c/d --> (a*c)/(b*d)
%================================================================================
_applicable(Time, _action(multFrac, _data(LeftFrac, RightFrac)))
	:-	_isDiv(Time, LeftFrac),
		_isDiv(Time, RightFrac),
		_siblings(Time, LeftFrac, RightFrac),
		_parentType(Time, LeftFrac, mul).

% set result as a fraction with numer and denom as fractions
_activateTempAndSetChildren(Time, tempRoot, div, 2)
	:-	_actionForTimeStep(Time, multFrac).
_treeOp(Time, TempNumer, FstNumer, SndNumer, mul)
	:-	_tempChildOnSide(tempRoot, TempNumer, left),
		_numerOfOperand(Time, FstNumer, left),
		_numerOfOperand(Time, SndNumer, right).
_treeOp(Time, TempDenom, FstDenom, SndDenom, mul)
	:-	_tempChildOnSide(tempRoot, TempDenom, right),
		_denomOfOperand(Time, FstDenom, left),
		_denomOfOperand(Time, SndDenom, right).

% isolate the numerators and denominators
_numerOfOperand(Time, Numer, Side)
	:-	_operand(Time, Frac, oper(multFrac, Side)),
		_numerOf(Time, Frac, Numer).
_denomOfOperand(Time, Numer, Side)
	:-	_operand(Time, Frac, oper(multFrac, Side)),
		_denomOf(Time, Frac, Numer).

_writeBinaryOp(Time)
	:-	_actionForTimeStep(Time, multFrac).

%================================================================================
% fracDiv: a/c / b/d --> a/c * d/b
%================================================================================
_applicable(Time, _action(fracDiv, _data(NumerFrac, DenomFrac)))
			:-	_siblings(Time, NumerFrac, DenomFrac),
				_isDiv(Time, NumerFrac),
				_isDiv(Time, DenomFrac),
				NumerFrac < DenomFrac, % to ensure NumerFrac actually corresponds to numerator
				_parentType(Time, NumerFrac, div).

% set root node to multiplication node
_activateTempAndSetChildren(Time, tempRoot, mul, 2)
	:-	_actionForTimeStep(Time, fracDiv).
% 'left' fraction remains unchanged
_deepCopy(Time, LeftTemp, NumerFrac)
	:-	_tempChildOnSide(tempRoot, LeftTemp, left),
		_actionForTimeStep(Time, fracDiv),
		_operand(Time, NumerFrac, oper(fracDiv, left)).
% flip numer/denom fields
_treeOp(Time, RightTemp, Numer, Denom, reciprocal)
	:-	_operand(Time, DenomFrac, oper(fracDiv, right)),
		_numerOf(Time, DenomFrac, Numer),
		_denomOf(Time, DenomFrac, Denom),
		_tempChildOnSide(tempRoot, RightTemp, right).

_setResultTo(Time, Root)
	:-	_operand(Time, DenomFrac, oper(fracDiv, right)),
		_activeChild(Time, Root, DenomFrac).

%================================================================================
% ignore denominator: a / b = 0 --> a = 0
%================================================================================
_applicable(Time, _action(numerSimp, _data(leftSide)))
	:-	_isZero(Time, rightSide),
		_isDiv(Time, leftSide).

% assumes that fraction is poly/poly
_deepCopy(Time, tempRoot, Numer)
	:-	_operand(Time, Frac, oper(numerSimp, left)),
		_numerOf(Time, Frac, Numer).
_setResultTo(Time, leftSide)
	:-	_actionForTimeStep(Time, numerSimp).


%================================================================================
% addMonom: a*x^b + c*x^b ----> (a+c)*x^b
%================================================================================
% TODO: contains as a special case:		addIdentity: a*x^b + 0 ----> a*x^b 
% is this problematic?

_applicable(Time, _action(addMonom, _data(LeftMono, RightMono)))
	:-	_siblings(Time, LeftMono, RightMono),
		_equalDegs(Time, LeftMono, RightMono),
		_isMono(Time, LeftMono),
		_isMono(Time, RightMono),
		LeftMono != RightMono,
		_parentType(Time, LeftMono, add).

_monoOp(Time, tempRoot, LeftMono, RightMono, add)
	:-	_operand(Time, LeftMono, oper(addMonom, left)),
		_operand(Time, RightMono, oper(addMonom, right)).

_writeBinaryOp(Time)
	:-	_actionForTimeStep(Time, addMonom).

%================================================================================
% monomult ax^b  * cx^d --> (a*c)x^(b+d)
%================================================================================
_applicable(Time, _action(monoMult, _data(LeftMono, RightMono)))
	:-	_siblings(Time, LeftMono, RightMono),
		_isMono(Time, LeftMono),
		_isMono(Time, RightMono),
		LeftMono != RightMono,
		_parentType(Time, LeftMono, mul).
 
_monoOp(Time, tempRoot, LeftMono, RightMono, mul)
	:-	_operand(Time, LeftMono, oper(monoMult, left)),
		_operand(Time, RightMono, oper(monoMult, right)).

_writeBinaryOp(Time)
	:-	_actionForTimeStep(Time, monoMult).

%================================================================================
% fracCancel A*B/C*B --> A/C
%================================================================================
% NOTE: relies on equal/3 predicate to work
_applicable(Time, _action(fracCancel, _data(FstNode, SndNode)))
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
	:-	_operand(Time, Numer, oper(fracCancel, left)),
		_operand(Time, Denom, oper(fracCancel, right)).
_cancelTerm(Time, Fst)
	:-	_factorsToCancel(Time, Fst, Snd).
_cancelTerm(Time, Snd)
	:-	_factorsToCancel(Time, Fst, Snd).

%================================================================================
% factor (x^2 + bx + c) --> (x + e) * (x + d)
%================================================================================
% NOTE: squared term must have coeff 1, divide by constant my be required to reach 
% this form
_applicable(Time, _action(factor, _data(Node)))
	:-	_isPolynomial(Time, Node),
		_isQuadratic(Time, Node),
		_isFactorable(Time, Node).

% select the factors to use
_factorsForBinomials(Time, FstFactor, SndFactor)
	:-	_operand(Time, Poly,  oper(factor, left)),
		_monoTermOfPoly(Time, Poly, 1, LinearTerm),
		_monoTermOfPoly(Time, Poly, 0, ConstTerm),
		_factors(FstFactor, SndFactor, LinearTerm, ConstTerm),
		FstFactor <= SndFactor. % NOTE: sanity check, ensure this rule is used @ most once per time step
% result is product of two binomials
_activateTempAndSetChildren(Time, tempRoot, mul, 2)
	:-	_actionForTimeStep(Time, factor).

% initialize binomials
_setToBinomial(Time, LeftChild, FstFactor)
	:-	_tempChildNum(tempRoot, LeftChild, 1),
		_factorsForBinomials(Time, FstFactor, SndFactor).
_setToBinomial(Time, RightChild, SndFactor)
	:-	_tempChildNum(tempRoot, RightChild, 2),
		_factorsForBinomials(Time, FstFactor, SndFactor).

% save the result of factoring
_setResultTo(Time, Poly)
	:-	_operand(Time, Poly,  oper(factor, left)).


%================================================================================
% addSameFrac A/B + C/B --> (A+C)/B
%================================================================================
% NOTE: _sameDenom depends on equals/3 predicate (which applies only to monomials)
_applicable(Time, _action(addSameFrac, _data(Fst, Snd)))
	:-	_siblings(Time, Fst, Snd),
		_sameDenom(Time, Fst, Snd),
		_parentType(Time, Fst, add).

% set root to a fraction
_activateTempAndSetChildren(Time, tempRoot, div, 2)
	:-	_actionForTimeStep(Time, addSameFrac).

% set numerator to a sum
_treeOp(Time, TempNumer, FstNumer, SndNumer, add)
	:-	_tempChildNum(tempRoot, TempNumer, 1),
		_operandNumer(Time, FstNumer, oper(addSameFrac, left)),
		_operandNumer(Time, SndNumer, oper(addSameFrac, right)).
% set denom 
_deepCopy(Time, TempDenom, FstDenom)
	:-	_tempChildNum(tempRoot, TempDenom, 2),
		_operandDenom(Time, FstDenom, oper(addSameFrac, left)).
% save result
_writeBinaryOp(Time)
	:-	_actionForTimeStep(Time, addSameFrac).
	
%================================================================================
% addDiffFrac A/B + C/D --> (A*D+C*B)/B*D
%================================================================================
% NOTE: requires max depth of allowable expression trees to be at least 4 
% NOTE: also dependent on equal/3 predicate
_applicable(Time, _action(addDiffFrac, _data(Fst, Snd)))
	:-	_siblings(Time, Fst, Snd),
		_isDiv(Time, Fst),
		_isDiv(Time, Snd),
		_parentType(Time, Fst, add).

% set root to a fraction
_activateTempAndSetChildren(Time, tempRoot, div, 2)
	:-	_actionForTimeStep(Time, addDiffFrac).

% set numer to sum of products
_activateTempAndSetChildren(Time, Numer, add, 2)
	:-	_actionForTimeStep(Time, addDiffFrac),
		_tempChildNum(tempRoot, Numer, 1).

_treeOp(Time, FstProd, FstNumer, SndDenom, mul)
	:-	_tempChildNum(tempRoot, Numer, 1),
		_tempChildNum(Numer, FstProd, 1),
		_operandNumer(Time, FstNumer, oper(addDiffFrac, left)),
		_operandDenom(Time, SndDenom, oper(addDiffFrac, right)).

_treeOp(Time, SndProd, SndNumer, FstDenom, mul)
	:-	_tempChildNum(tempRoot, Numer, 1),
		_tempChildNum(Numer, SndProd, 2),
		_operandNumer(Time, SndNumer, oper(addDiffFrac, right)),
		_operandDenom(Time, FstDenom, oper(addDiffFrac, left)).

% set denominator to product of two original numerators
_treeOp(Time, RootDenom, FstDenom, SndDenom, mul)
	:-	_tempChildNum(tempRoot, RootDenom, 2),
		_operandDenom(Time, FstDenom, oper(addDiffFrac, left)),
		_operandDenom(Time, SndDenom, oper(addDiffFrac, right)).
% save result
_writeBinaryOp(Time)
	:-	_actionForTimeStep(Time, addDiffFrac).

%================================================================================
% distribute (a + b) * C --> (a*C + b*C)
%================================================================================
_applicable(Time, _action(distribute, _data(PlusTerm, DistribTerm)))
	:-	_siblings(Time, PlusTerm, DistribTerm),
		_parentType(Time, PlusTerm, mul),
		_isAdd(Time, PlusTerm).

% every term in original plus node, is multiplied by distributed term
_activateTempNode(Time, tempRoot, add)
	:-	_actionForTimeStep(Time, distribute).

_treeOp(Time, TempNode, Term, DistribTerm, mul)
	:-	_operand(Time, DistribTerm, oper(distribute, right)),
		_operand(Time, PlusTerm, oper(distribute, left)),
		_activeChild(Time, PlusTerm, Term),
		_childNum(PlusTerm, Term, ChildNum),
		_tempChildNum(tempRoot, TempNode, ChildNum).

% setup parent child links 
% NOTE: must be done explicitly b/c there may be gaps between active children
_holds(Time, _fact(tempRoot, _nodeField(activechild, Temp)))
	:-	_holds(Time, _fact(Temp, _nodeField(active, yes))),
		_validTempChildOf(tempRoot, Temp).
% save result
_writeBinaryOp(Time)
	:-	_actionForTimeStep(Time, distribute).


%================================================================================
% divByOne A/1 --> A
%================================================================================
_applicable(Time, _action(divByOne, _data(Fraction)))
	:-	_denomOf(Time, Fraction, Denom),
		_isOne(Time, Denom).

_deepCopy(Time, Fraction, Numer)
	:-	_operand(Time, Fraction, oper(divByOne, left)),
		_numerOf(Time, Fraction, Numer).
%================================================================================
% addZero A + 0 --> A
%================================================================================
_applicable(Time, _action(addZero, _data(Mono)))
	:-	_isZero(Time, Mono),
		_parentType(Time, Mono, add).

_cancelTerm(Time, ZeroTerm)
	:-	_operand(Time, ZeroTerm, oper(addZero, left)).

%================================================================================
% factorMonom:	ax^k  --> bx^m * cx^n 
%================================================================================
% NOTE: this is the same rule as factorCommTerm, except written specifically for monomials
_applicable(Time, _action(factorMonom, _data(Mono)))
	:-	_isMono(Time, Mono),
		not _isOne(Time, Mono),
		not _isZero(Time, Mono).
% select coefficient factors,
1 { _selectedCoeffFactors(Time, FstFactor, SndFactor) 
		: _factors(FstFactor, SndFactor, FactorSum, Coeff) } 1
	:-	_operand(Time, Mono, oper(factorMonom, left)),
		_coeffOf(Time, Mono, Coeff).
% select degree factors
1 { _selectedDegDecomposition(Time, Fst, Snd) 
		: _degree(Fst), _degree(Snd),
			MonoDeg = Fst + Snd } 1
	:-	_operand(Time, Mono, oper(factorMonom, left)),
		_degOf(Time, Mono, MonoDeg).
% form product of monomials (careful with code reuse here!!)
_activateTempAndSetChildren(Time, tempRoot, mul, 2)
	:-	_actionForTimeStep(Time, factorMonom).
_activateTempNode(Time, Child, mono)
	:-	_actionForTimeStep(Time, factorMonom),
		_tempChildOnSide(tempRoot, Child, Side).
_addMonomToNode(Time, LeftChild, FstDeg, FstCoeff)
	:-	_actionForTimeStep(Time, factorMonom),
		_tempChildOnSide(tempRoot, LeftChild, left),
		_selectedCoeffFactors(Time, FstCoeff, SndCoeff),
		_selectedDegDecomposition(Time, FstDeg, SndDeg).
_addMonomToNode(Time, RightChild, SndDeg, SndCoeff)
	:-	_actionForTimeStep(Time, factorMonom),
		_tempChildOnSide(tempRoot, RightChild, right),
		_selectedCoeffFactors(Time, FstCoeff, SndCoeff),
		_selectedDegDecomposition(Time, FstDeg, SndDeg).
% save result 
_setResultTo(Time, Mono)
	:-	_operand(Time, Mono, oper(factorMonom, left)).

%================================================================================
% factorCommTerm:	(a*x^k + b*x^l ) --> (a*x^m + b*x^n ) * x^j
%================================================================================
_applicable(Time, _action(factorCommTerm, _data(Poly)))
	:-	_isPolynomial(Time, Poly),
		_hasCommonCoeff(Time, Poly),
		_hasCommonDeg(Time, Poly).

% select common term to factor our
1 { _selectedCommonDeg(Time, Deg) : _hasCommonDeg(Time, Poly, Deg) } 1
	:-	_operand(Time, Poly, oper(factorCommTerm, left)).
1 { _selectedCommonCoeff(Time, Coeff) : _hasCommonCoeff(Time, Poly, Coeff) } 1
	:-	_operand(Time, Poly, oper(factorCommTerm, left)).

% setup correct tree structure
_activateTempAndSetChildren(Time, tempRoot, mul, 2)
	:-	_actionForTimeStep(Time, factorCommTerm).

% save monomial that we factored out
_activateTempNode(Time, TempRight, mono)
	:-	_actionForTimeStep(Time, factorCommTerm),
		_tempChildOnSide(tempRoot, TempRight, right).
_addMonomToNode(Time, TempRight, Deg, Coeff)
	:-	_actionForTimeStep(Time, factorCommTerm),
		_tempChildOnSide(tempRoot, TempRight, right),
		_selectedCommonDeg(Time, Deg),
		_selectedCommonCoeff(Time, Coeff).
% perform the division
_activateTempNode(Time, TempLeft, add)
	:-	_actionForTimeStep(Time, factorCommTerm),
		_tempChildOnSide(tempRoot, TempLeft, left).
_originalMonoTerm(Time, Mono, Num)	% isolate monomial terms
	:-	_operand(Time, Poly, oper(factorCommTerm, left)),
		_activeChild(Time, Poly, Mono),
		_childNum(Poly, Mono, Num).
_newMonoTerm(Time, TempChild, Num)
	:-	_tempChildOnSide(tempRoot, TempLeft, left),
		_originalMonoTerm(Time, Mono, Num),
		_tempChildNum(TempLeft, TempChild, Num).

_holds(Time, _fact(TempLeft, _nodeField(activechild, TempTerm)))
	:-	_actionForTimeStep(Time, factorCommTerm),
		_tempChildOnSide(tempRoot, TempLeft, left),
		_newMonoTerm(Time, TempTerm, Num).
_activateTempNode(Time, TempTerm, mono)
	:-	_actionForTimeStep(Time, factorCommTerm),
		_newMonoTerm(Time, TempTerm, Num).
% set the new coeff and deg values
_holds(Time, _fact(TempTerm, _nodeField(coeff, NewCoeff)))
	:-	_actionForTimeStep(Time, factorCommTerm),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_coeffOf(Time, Mono, MonoCoeff),
		_selectedCommonCoeff(Time, CommonCoeff),
		_coeffFactorPairOf(CommonCoeff, NewCoeff, MonoCoeff).

_holds(Time, _fact(TempTerm, _nodeField(degree, NewDeg)))
	:-	_actionForTimeStep(Time, factorCommTerm),
		_originalMonoTerm(Time, Mono, Num),
		_newMonoTerm(Time, TempTerm, Num),
		_degOf(Time, Mono, MonoDeg),
		_selectedCommonDeg(Time, CommonDeg),
		NewDeg = MonoDeg - CommonDeg.

% save result
_setResultTo(Time, Poly)
	:-	_operand(Time, Poly, oper(factorCommTerm, left)).

%================================================================================
% multByZero:	A*0 --> 0
%================================================================================
_applicable(Time, _action(multByZero, _data(ZeroTerm)))
	:-	_isZero(Time, ZeroTerm),
		_parentType(Time, ZeroTerm, mul).

_setToZero(Time, Parent)
	:-	_operand(Time, ZeroTerm, oper(multByZero, left)),
		_activeChild(Time, Parent, ZeroTerm).

%================================================================================
% multIdentity:	A*1 --> A
%================================================================================
_applicable(Time, _action(multIdentity, _data(UnitTerm)))
	:-	_isOne(Time, UnitTerm),
		_parentType(Time, UnitTerm, mul).
_cancelTerm(Time, UnitTerm)
	:-	_operand(Time, UnitTerm, oper(multIdentity, left)).

%================================================================================
% multNumerAndDenom:	A/B --> (A*C)/(B*C)
%================================================================================
% NOTE: This rule requres max tree depth to be at least 4, otherwise the generated
% expression is too large and we get a node overflow.
% Additionally, we can only multiply expression by a polynomial expression already existing
% somewhere in the equation
_applicable(Time, _action(multNumerAndDenom, _data(Fraction, Poly)))
	:-	_isDiv(Time, Fraction),
		_isPolynomial(Time, Poly).

% set root to div
_activateTempAndSetChildren(Time, tempRoot, div, 2)
	:-	_actionForTimeStep(Time, multNumerAndDenom).

% multiply numer
_treeOp(Time, TempNode, Numer, Poly, mul)
	:-	_operandNumer(Time, Numer, oper(multNumerAndDenom, left)),
		_operand(Time, Poly, oper(multNumerAndDenom, right)),
		_tempChildOnSide(tempRoot, TempNode, left).

% multiply denom
_treeOp(Time, TempNode, Denom, Poly, mul)
	:-	_operandDenom(Time, Denom, oper(multNumerAndDenom, left)),
		_operand(Time, Poly, oper(multNumerAndDenom, right)),
		_tempChildOnSide(tempRoot, TempNode, right).

% save the result
_setResultTo(Time, Fraction)
	:-	_operand(Time, Fraction, oper(multNumerAndDenom, left)).

%================================================================================
% addMonoToEqn:	A = B --> A + e = B + e
%================================================================================
_applicable(Time, _action(addMonoToEqn, _data(leftSide, rightSide)))
	:-	_validTime(Time).	

% select an arbitrary degree and coefficient
1 { _selectedDeg(Time, Deg) : _degree(Deg) } 1
	:-	_actionForTimeStep(Time, addMonoToEqn).
1 { _selectedCoeff(Time, Coeff) : _coeff(Coeff) } 1
	:-	_actionForTimeStep(Time, addMonoToEqn).

_eqnMonoOp(Time, Coeff, Deg, add)
	:-	_actionForTimeStep(Time, addMonoToEqn),
		_selectedDeg(Time, Deg),
		_selectedCoeff(Time, Coeff).

% save the results
_deepCopy(Time, leftSide, tempRoot)
	:-	_actionForTimeStep(Time, addMonoToEqn).
_deepCopy(Time, rightSide, tempRightRoot)
	:-	_actionForTimeStep(Time, addMonoToEqn).

%================================================================================
% multEqnWithMono:	A = B --> A * e = B * e
%================================================================================
_applicable(Time, _action(multEqnWithMono, _data(leftSide, rightSide)))
	:-	_validTime(Time).	

% select an arbitrary degree and coefficient
1 { _selectedDeg(Time, Deg) : _degree(Deg) } 1
	:-	_actionForTimeStep(Time, multEqnWithMono).
1 { _selectedCoeff(Time, Coeff) : _coeff(Coeff) } 1
	:-	_actionForTimeStep(Time, multEqnWithMono).

_eqnMonoOp(Time, Coeff, Deg, mul)
	:-	_actionForTimeStep(Time, multEqnWithMono),
		_selectedDeg(Time, Deg),
		_selectedCoeff(Time, Coeff).

% save the results
_deepCopy(Time, leftSide, tempRoot)
	:-	_actionForTimeStep(Time, multEqnWithMono).
_deepCopy(Time, rightSide, tempRightRoot)
	:-	_actionForTimeStep(Time, multEqnWithMono).

%================================================================================
% swapTerms: A*B --> B*A, or A+B --> B*A	
%================================================================================
_applicable(Time, _action(swapTerms, _data(FstTerm, SndTerm)))
	:-	_swappableTerms(Time, FstTerm, SndTerm),
		not _equal(Time, FstTerm, SndTerm).	% NOTE: swapping equal terms is basically a NO-OP

_deepCopy(Time, FstTerm, SndTerm)
	:-	_operand(Time, FstTerm, oper(swapTerms, left)),
		_operand(Time, SndTerm, oper(swapTerms, right)),
		_siblings(Time, FstTerm, SndTerm).	% specify operands are siblings to avoid excessively large grounding

_deepCopy(Time, SndTerm, FstTerm)
	:-	_operand(Time, FstTerm, oper(swapTerms, left)),
		_operand(Time, SndTerm, oper(swapTerms, right)),
		_siblings(Time, FstTerm, SndTerm).

:- not _actionForTimeStep(_time(0,1), swapTerms).

