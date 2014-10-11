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


%================================================================================
% divIdentity: A / A ----> 1
%================================================================================
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

_writeBinaryOp(Time, LeftFrac, RightFrac)
	:-	_operand(Time, LeftFrac, oper(multFrac, left)),
		_operand(Time, RightFrac, oper(multFrac, right)).

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
% contains as a special case:		addIdentity: a*x^b + 0 ----> a*x^b 

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

_writeBinaryOp(Time, LeftMono, RightMono)
	:-	_operand(Time, LeftMono, oper(addMonom, left)),
		_operand(Time, RightMono, oper(addMonom, right)).

%================================================================================
% monomult (a + b ) * c --> a*c + b*c
%================================================================================
% contains as special case:		multIdentity: a*x^b * 1 ----> a*x^b 
_applicable(Time, _action(monoMult, _data(LeftMono, RightMono)))
	:-	_siblings(Time, LeftMono, RightMono),
		_isMono(Time, LeftMono),
		_isMono(Time, RightMono),
		LeftMono != RightMono,
		_parentType(Time, LeftMono, mul).
 
_monoOp(Time, tempRoot, LeftMono, RightMono, mul)
	:-	_operand(Time, LeftMono, oper(monoMult, left)),
		_operand(Time, RightMono, oper(monoMult, right)).

_writeBinaryOp(Time, LeftMono, RightMono)
	:-	_operand(Time, LeftMono, oper(monoMult, left)),
		_operand(Time, RightMono, oper(monoMult, right)).

%================================================================================
% fracCancel A*B/C*B --> A/C
%================================================================================
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
% factor (ax^2 + bx + c) --> (x + e) * (x + d)
%================================================================================
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
_writeBinaryOp(Time, Fst, Snd)
	:-	_operand(Time, Fst, oper(addSameFrac, left)),
		_operand(Time, Snd, oper(addSameFrac, right)).
	
%================================================================================
% addDiffFrac A/B + C/D --> (A*D+C*B)/B*D
%================================================================================
_applicable(Time, _action(addDiffFrac, _data(Fst, Snd)))
	:-	_siblings(Time, Fst, Snd),
		_isDiv(Time, Fst),
		_isDiv(Time, Snd),
		_parentType(Time, Fst, add).

:- not _actionForTimeStep(_time(0,1), addDiffFrac).

