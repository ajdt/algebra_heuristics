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

% setting numer and denom!!
_activateTempAndSetChildren(Time, tempRoot, div, 2)
	:-	_actionForTimeStep(Time, multFrac).
_activateTempAndSetChildren(Time, TempNumer, mul, 2)
	:-	_tempChildNum(tempRoot, TempNumer, 1),
		_actionForTimeStep(Time, multFrac).
_activateTempAndSetChildren(Time, TempDenom, mul, 2)
	:-	_tempChildNum(tempRoot, TempDenom, 2),
		_actionForTimeStep(Time, multFrac).

% isolate the numerators and denominators
_numerOfOperand(Time, Numer, Side)
	:-	_operand(Time, Frac, oper(multFrac, Side)),
		_numerOf(Time, Frac, Numer).
_denomOfOperand(Time, Numer, Side)
	:-	_operand(Time, Frac, oper(multFrac, Side)),
		_denomOf(Time, Frac, Numer).

% critique: access is too convoluted: simpler way?
% copy the left numer and right numer as children of tempNumerator
_deepCopy(Time, LeftTerm, LeftNumer)
	:-	_numerOfOperand(Time, LeftNumer, left),
		_tempChildNum(tempRoot, TempNumer, 1),
		_tempChildNum(TempNumer, LeftTerm, 1).
_deepCopy(Time, LeftTerm, RightNumer)
	:-	_numerOfOperand(Time, RightNumer, right),
		_tempChildNum(tempRoot, TempNumer, 1),
		_tempChildNum(TempNumer, LeftTerm, 2).

% copy the left denom and right denom  as children of tempDenominator
_deepCopy(Time, LeftTerm, LeftDenom)
	:-	_denomOfOperand(Time, LeftDenom, left),
		_tempChildNum(tempRoot, TempDenom, 2),
		_tempChildNum(TempDenom, LeftTerm, 1).
_deepCopy(Time, LeftTerm, RightDenom)
	:-	_denomOfOperand(Time, RightDenom, right),
		_tempChildNum(tempRoot, TempDenom, 2),
		_tempChildNum(TempDenom, LeftTerm, 2).

_writeBinaryOp(Time, LeftFrac, RightFrac)
	:-	_operand(Time, LeftFrac, oper(multFrac, left)),
		_operand(Time, RightFrac, oper(multFrac, right)).

:- not _actionForTimeStep(_time(0,1), multFrac).
