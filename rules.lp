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

% set result as a fraction with numer and denom as fractions
_activateTempAndSetChildren(Time, tempRoot, div, 2)
	:-	_actionForTimeStep(Time, multFrac).
_treeOp(Time, TempNumer, FstNumer, SndNumer, mul)
	:-	_tempChildNum(tempRoot, TempNumer, left),
		_numerOfOperand(Time, FstNumer, left),
		_numerOfOperand(Time, SndNumer, right).
_treeOp(Time, TempDenom, FstDenom, SndDenom, mul)
	:-	_tempChildNum(tempRoot, TempDenom, right),
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
_applicable(Time, _action(fracDiv, _data(DenomFrac)))
			:-	_siblings(Time, NumerFrac, DenomFrac),
				_isDiv(Time, NumerFrac),
				_isDiv(Time, DenomFrac),
				_parentType(Time, NumerFrac, div).

:- not _actionForTimeStep(_time(0,1), fracDiv).

% TODO: find out why this constraint is necessary
:- _isMono(Time, Mono), 0 { _degOf(Time, Mono, Deg) : _degree(Deg) } 0.
 

