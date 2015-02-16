% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file defines the nodes used in expression tree generation, and 
% useful predicates describing their properties. 
%
% NODE DESC:
% Nodes are grouped into layers, with the number of layers determined by the
% maximum tree depth allowed. There are two nodes in the first layer,
% nodes of each layer are assigned a specific number of children
% (see maxChildrenAtDepth predicate).
% 
%

% TODO: detect node overflow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODE DEPTH, CHILDREN AND NODE GENERATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_depthValue(1..maxDepth).

_childCount(2..maxChildren).	% childCount defines upper and lower limit on number of children allowable
								% maxChildrenAtDepth defines a more constraining upper limit depending on node depth
_maxChildrenAtDepth(1, 3).	%(depth, numChildren)
_maxChildrenAtDepth(2, 3).
_maxChildrenAtDepth(3, 3).
_maxChildrenAtDepth(4, 2).

% define left and right sides of eqn 
#const rightSide		= _id(1,2).	
#const leftSide 		= _id(1,1).
#const tempLeftRoot		= _temp(_id(1,1)).
#const tempRightRoot	= _temp(_id(1,2)).
#const tempResultRoot	= tempLeftRoot.		% convention: operation results are rooted on tempLeftRoot

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DECLARING NODES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: _id(...) should not be referenced outside of this code!!
_rootNode(rightSide;leftSide).	% right and left side nodes explicitly declared. 
								% Remaining nodes generated as children of existing nodes
_node(Node) 
		:-	_rootNode(Node).

% defining node properties
_nodeDepth(_id(Depth, Number), Depth)
		:-	_node(_id(Depth, Number)).
_numberOfNode(_id(Depth, Number), Number)
		:-	_node(_id(Depth, Number)).

_maxNumChildren(Node, NumChildren)
		:-	_maxChildrenAtDepth(Depth, NumChildren),
			_nodeDepth(Node, Depth),
			Depth < maxDepth.
_maxNumChildren(Node, 0)	% leaf nodes don't have children
		:-	_nodeDepth(Node, Depth),
			Depth == maxDepth.

% generate children for internal nodes, if they have any
_childNum(Node, NewNode, ChildNum) % (Parent, ChildNode, NumberOfChildNode)
		:-	_node(Node),
			_maxNumChildren(Node, NumChildren),
			_nodeDepth(Node, Depth),
			_numberOfNode(Node, NodeNum),
			NewNode = _id(NewDepth, ChildID),
			NewDepth = Depth+1,
			NewDepth <= maxDepth,
			ChildNum = 1..NumChildren,
			ChildID =(NodeNum - 1)*NumChildren + ChildNum.
_validChildOf(Parent, Child) 
		:-	_childNum(Parent, Child, ChildNum).
_node(Child)	% declare children as nodes in their own right
		:-	_validChildOf(Parent, Child).

% useful aliases for first two children
_childOnSide(Node, Child, left)
	:-	_childNum(Node, Child, 1).
_childOnSide(Node, Child, right)
	:-	_childNum(Node, Child, 2).

% CONSTRAINT: enforcing the valid child constraint
:- _holds(Time, _fact(Parent, _nodeField(activechild, Child))),
	_node(Parent), _node(Child),
	not _validChildOf(Parent, Child).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  types of nodeField's 
_type(div;mul;add;mono;neg).
_commutatitve(mul;add).
_unary(neg).

_pointerField(activechild).
_simpleField(type;degree;coeff;active).  % these fields are safe to make shallow copies of

					%%% Aliases %%%
% These fluents alias expression tree fluents wrapped in holds() predicates
% that way holds(...) and tree representation can be changed more easily

% node type
__isActive(Time, Node)
		:-	_holds(Time, _fact(Node, _nodeField(active, yes))),
			_node(Node).
_hasType(Time, Node, Type)
		:-	_holds(Time, _fact(Node, _nodeField(type, Type))).

_isFraction(Time, Node)
		:-	_hasType(Time, Node, div).
_isMultiplicationOperation(Time, Node)
		:-	_hasType(Time, Node, mul).
_isAdditionOperation(Time, Node)
		:-	_hasType(Time, Node, add).
_isNeg(Time, Node)
		:-	_hasType(Time, Node, neg).
__isMono(Time, Node)
		:-	_hasType(Time, Node, mono).
_isOper(Time, Node)
		:-	__isActive(Time, Node),
			_hasType(Time, Node, Type),
			Type != mono.
_isTheDegreeOf(Time, Node, Deg)
		:-	_holds(Time, _fact(Node, _nodeField(degree, Deg))),
			_node(Node).
_isTheCoefficientOf(Time, Node, Coeff)
		:-	_holds(Time, _fact(Node, _nodeField(coeff, Coeff))),
			_node(Node).

% used to simulate an OR of these two types
_isASingleTermOrSumOfTerms(Time, Node)	:-	__isMono(Time, Node).
_isASingleTermOrSumOfTerms(Time, Node)	:-	_isAdditionOperation(Time, Node).
_mulOrDiv(Time, Node)	:-	_isFraction(Time, Node).
_mulOrDiv(Time, Node)	:-	_isMultiplicationOperation(Time, Node).

					%%% Derived Properties %%%
% Useful, secondary properties of tree nodes.
% Derived from holds() predicates or their aliases
_absoluteValueIsOne(Time, Node)
	:- _isNegOne(Time, Node).
_absoluteValueIsOne(Time, Node)
	:- _isOne(Time, Node).
_isNegOne(Time, Node)
	:-	__isMono(Time, Node),
		_isTheCoefficientOf(Time, Node, -1),
		_isTheDegreeOf(Time, Node, 0).
_isOne(Time, Node)
	:-	__isMono(Time, Node),
		_isTheCoefficientOf(Time, Node, 1),
		_isTheDegreeOf(Time, Node, 0).
_isZero(Time, Node)
		:-	_isTheCoefficientOf(Time, Node, 0).
% node fields
_numeratorOf(Time, Parent, Child)
		:-	_isFraction(Time, Parent),
			_isATermOf(Time, Parent, Child),
			_childNum(Parent, Child, 1).
_denominatorOf(Time, Parent, Child)
		:-	_isFraction(Time, Parent),
			_isATermOf(Time, Parent, Child),
			_childNum(Parent, Child, 2).
%% NOTE: need these numer/denom fields for visualizer
_holds(Time, _fact(Parent, _nodeField(numer, Child)))
		:-	_numeratorOf(Time, Parent, Child).
_holds(Time, _fact(Parent, _nodeField(denom, Child)))
		:-	_denominatorOf(Time, Parent, Child).

					%%% Properties Derived From Tree Structure %%%
% NOTE: a nested grouping: is an operator node nested inside another of the same type that can be ungrouped
% as in (x+b)+c --> x + b + c
_nestedGrouping(Time, Child)
		:-	_isATermOf(Time, Parent, Child),
			_isAdditionOperation(Time, Parent),
			_isAdditionOperation(Time, Child).
_nestedGrouping(Time, Child)
		:-	_isATermOf(Time, Parent, Child),
			_isMultiplicationOperation(Time, Parent),
			_isMultiplicationOperation(Time, Child).

_parentType(Time, Child, Type)
		:-	_isATermOf(Time, Parent, Child),
			_hasType(Time, Parent, Type).
_isBeingMultiplied(Time, Child)
        :-  _parentType(Time, Child, mul).
_isBeingDivided(Time, Child)
        :-  _parentType(Time, Child, div).
_isBeingAdded(Time, Child)
        :-  _parentType(Time, Child, add).
_isBeingNegated(Time, Child)
        :-  _parentType(Time, Child, neg).

_areBeingAdded(Time, Fst, Snd)
        :-  _areSiblings(Time, Fst, Snd),
           _isBeingAdded(Time, Fst).

_areBeingMultiplied(Time, Fst, Snd)
        :-  _areSiblings(Time, Fst, Snd),
           _isBeingMultiplied(Time, Fst).

_formAFraction(Time, Fst, Snd)
        :-  _areSiblings(Time, Fst, Snd),
           _isBeingDivided(Time, Fst).

_isATermOf(Time, Parent, Child)
		:-	__isActive(Time, Parent),
			__isActive(Time, Child),
			_validChildOf(Parent, Child).

_areSiblings(Time, FstChild, SndChild)
		:-	_isATermOf(Time, Parent, FstChild),
			_isATermOf(Time, Parent, SndChild),
			FstChild != SndChild.

_swappableTerms(Time, Fst, Snd)
		:-	_areSiblings(Time, Fst, Snd),
			_parentType(Time, Fst, Type),
			_commutatitve(Type).

% NOTE: indicates that a subtree obviously reduces to zero
_reducibleToZero(Time, Node)
		:-	_isZero(Time, Node).
_reducibleToZero(Time, Node)
		:-	_isMultiplicationOperation(Time, Node),
			_isATermOf(Time, Node, Child),
			_reducibleToZero(Time, Child).
_reducibleToZero(Time, Node)
		:-	_isOper(Time, Node),
			_everyChildReducesToZero(Time, Node).
_everyChildReducesToZero(Time, Node)
		:-	_isOper(Time, Node),
			not _hasNonZeroChild(Time, Node).
_hasNonZeroChild(Time, Node)
		:-	_isOper(Time, Node),
			_isATermOf(Time, Node, Child),
			not _reducibleToZero(Time, Child).

% NOTE: A factor (for a node) is a subtree that divides the node with no remainder.
% if node is a multiplication op, then all it's children are factors. Otherwise,
% we consider the node its own factor.
% Mostly, used for fraction cancel rule.
_factorOf(Time, Node, Child)
	:-	_isMultiplicationOperation(Time, Node),
		_isATermOf(Time, Node, Child).
_factorOf(Time, Node, Node)
	:-	__isActive(Time, Node),
		not _isMultiplicationOperation(Time, Node).
_isFactorInNumeratorOf(Time, Fraction, NumerFactor)
    :-  _numeratorOf(Time, Fraction, Numer),
        _factorOf(Time, Numer, NumerFactor).
_isFactorInDenominatorOf(Time, Fraction, DenomFactor)
    :-  _denominatorOf(Time, Fraction, Denom),
        _factorOf(Time, Denom, DenomFactor).

_hasTwoTerms(Time, Node)
		:-	__validTime(Time),
			_node(Node),
			2 { _isATermOf(Time, Node, Child) : _validChildOf(Node, Child) } 2.
_parentHasTwoChildren(Time, Child)
		:-	_hasTwoTerms(Time, Parent),
			_isATermOf(Time, Parent, Child).

% fractions that have same denominator
% XXX: fractions must be siblings to be considered for sameDenom
_sameDenom(Time, FstFrac, SndFrac)
	:-	_areSiblings(Time, FstFrac, SndFrac),
		_denominatorOf(Time, FstFrac, FstDenom),
		_denominatorOf(Time, SndFrac, SndDenom),
		_areEqual(Time, FstDenom, SndDenom).

% counting number of children
% XXX: requires that we 'slide' down siblings of a deleted node, to work correctly
_numActiveChildren(Time, Node, Num)
	:-	_isATermOf(Time, Node, FstChild),
		_childNum(Node, FstChild, Num),
		_childNum(Node, SndChild, Num+1),
		not __isActive(Time, SndChild).
_numActiveChildren(Time, Node, Num)
	:-	_isATermOf(Time, Node, FstChild),
		_childNum(Node, FstChild, Num),
		_maxNumChildren(Node, Num).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CHANGING NODE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_update(Time, Node, type, Oper)
		:-	_setNodeType(Time, Node, Oper).

% set node to monomial
_clearNodeDeleteDescendants(Time, Node)
	:-	_setToMono(Time, Node, Deg, Coeff).
_setNodeType(Time, Node, mono)
	:-	_setToMono(Time, Node, Deg, Coeff),
		_coeff(Coeff), _degree(Deg).
_introduce(Time, Node, coeff, Coeff)
	:-	_setToMono(Time, Node, Deg, Coeff),
		_coeff(Coeff), _degree(Deg).
_introduce(Time, Node, degree, Deg)
	:-	_setToMono(Time, Node, Deg, Coeff),
		_coeff(Coeff), _degree(Deg).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SUBTREE OPERATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_nodeOper(delete;deallocate;clear).

_applyNodeOp(Time, Node, Op)
		:-	_applyNodeOpRecursive(Time, Node, Op).
_applyNodeOpRecursive(Time, Child, Op)
		:-	_applyNodeOpRecursive(Time, Node, Op),
			_isATermOf(Time, Node, Child).

% applying the operations
% NOTE: clearing won't delete any nodes in the subtree rooted at 'Node'
_remove(Time, _fact(Node, Info))			% clearing a node
		:-	_applyNodeOp(Time, Node, clear),
			_holds(Time, _fact(Node, Info)),
			Info != _nodeField(active,yes).

_applyNodeOp(Time, Node, clear)				% deleting a node
		:-	_applyNodeOp(Time, Node, delete).
_applyNodeOp(Time, Node, deallocate)	
		:-	_applyNodeOp(Time, Node, delete).


% XX: deallocation doesn't remove pointers to deleted node or any nodeFields
_deallocated(Time, Node)					% deallocating a node
		:-	_applyNodeOp(Time, Node, deallocate).
_remove(Time, _fact(Node, _nodeField(active, yes)))	
		:-	_applyNodeOp(Time, Node, deallocate).

%% clear node, delete its descendants
_applyNodeOp(Time, Node, clear)
		:-	_clearNodeDeleteDescendants(Time, Node).

_applyNodeOpRecursive(Time, Child, delete)
		:-	_clearNodeDeleteDescendants(Time, RootNode),
			_isATermOf(Time, RootNode, Child).
			%%% remove a subtree including pointers to it
% cancelTerm -- used to remove terms cancelled via division operation, may update parent
% deleteTerm -- just deletes a subtree

% NOTE: three different ways to cancelTerm depending on context
% NOTE: if parent has more than two children, we assume that @ least two children will
_setToOne(Time, Node)	% term is numer or denom of a fraction
		:-	_cancelTerm(Time, Node),
			_isBeingDivided(Time, Node).
_setToNegOne(Time, Node)	% term is negated, so we still have a -1 term
		:-	_cancelTerm(Time, Node),
			_isBeingNegated(Time, Node).

_replaceParent(Time, Sibling) 	% term is one of two children, replace parent with other child
		:-	_cancelTerm(Time, Node),
			not _isBeingDivided(Time, Node),
			_parentHasTwoChildren(Time, Node),
			_areSiblings(Time, Node, Sibling),
			not _cancelTerm(Time, Sibling),	% ensure the other child isn't also cancelled
			Sibling != Node.

%% shifting down terms
%%	NOTE: we want to maintain the invariant that if a node has k children, then they
%% 			occupy children numbered 1..k. 
%%			So if we delete a child for a node with 3 or more children, we shift down 
%%			all other siblings and delete the node at the end
_shiftDownTerms(Time, Node)
		:-	_cancelTerm(Time, Node),
			not _isBeingDivided(Time, Node),
			not _parentHasTwoChildren(Time, Node).	% XXX: assumes parent has 3 or more children
_shiftAdjacentTermDown(Time, Node, AdjacentSibling)
		:-	_shiftDownTerms(Time, Node),
			_childNum(Parent, Node, Num),
			_childNum(Parent, AdjacentSibling, Num+1),
			__isActive(Time, AdjacentSibling).
_deepCopy(Time, Node, Adjacent)
		:-	_shiftAdjacentTermDown(Time, Node, Adjacent).
_shiftDownTerms(Time, Adjacent)
		:-	_shiftAdjacentTermDown(Time, Node, Adjacent).
_deleteTerm(Time, Node)								% last active node is the only one we delete
		:-	_shiftDownTerms(Time, Node),
			_childNum(Parent, Node, Num),
			_childNum(Parent, AdjacentSibling, Num+1),
			not __isActive(Time, AdjacentSibling).
_deleteTerm(Time, Node)								% second case, we are already deleting the last node
		:-	_shiftDownTerms(Time, Node),
			_childNum(Parent, Node, Num),
			_maxNumChildren(Parent, Num).

% deleteTerm
_clearNodeDeleteDescendants(Time, Node)
		:-	_deleteTerm(Time, Node).
_removeReferencesToNode(Time, Node)
		:-	_deleteTerm(Time, Node).
		
_remove(Time, _fact(Parent, _nodeField(activechild, Node)))
		:-	_removeReferencesToNode(Time, Node),
			_isATermOf(Time, Parent, Node).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COPYING NODES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: all copying is deep copying

% deep copying means copying all attributes and deep copying children
_copyAttributes(Time, Copy, Orig)
		:-	_deepCopy(Time, Copy, Orig).
_deepCopyChildren(Time, Copy, Orig)
		:-	_deepCopy(Time, Copy, Orig).
_clearNodeDeleteDescendants(Time, Copy)
		:-	_deepCopy(Time, Copy, Orig),
			_node(Copy).	% NOTE: temp nodes don't have to be cleared
	
% copying attributes
		% from regular node  to regular node
_introduce(Time, _fact(Copy, NodeFact))
		:-	_copyAttributes(Time, Copy, Original),
			_node(Copy),
			_holds(Time, _fact(Original, _nodeField(Field, Value))),
			_simpleField(Field),
			NodeFact = _nodeField(Field, Value).
		% from reg node to temp node
_tempHolds(Time, _fact(Copy, NodeFact))	
		:-	_copyAttributes(Time, Copy, Original),
			_tempNode(Copy),
			_holds(Time, _fact(Original, _nodeField(Field, Value))),
			_simpleField(Field),
			NodeFact = _nodeField(Field, Value).
		% from temp node to reg node
_introduce(Time, _fact(Copy, NodeFact))
		:-	_copyAttributes(Time, Copy, Original),
			_node(Copy),
			_tempHolds(Time, _fact(Original, _nodeField(Field, Value))),
			_simpleField(Field),
			NodeFact = _nodeField(Field, Value).
% deep copying children
_copyChildPtrStructure(Time, Copy, Orig)	% setup corresp parent/child pointers for Copy node
	:-	_deepCopyChildren(Time, Copy, Orig).
		% from reg node to reg node
_introduce(Time, Copy, activechild, CopyChild)
		:-	_copyChildPtrStructure(Time, Copy, Original),
			_node(Original),
			_node(Copy),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_childNum(Copy, CopyChild, ChildNum).
_deepCopy(Time, CopyChild, OrigChild)
		:-	_deepCopyChildren(Time, Copy, Original),
			_node(Original),
			_node(Copy),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_childNum(Copy, CopyChild, ChildNum).
		% from reg node to temp node
_tempHolds(Time, _fact(Copy, _nodeField(activechild, CopyChild)))
		:-	_copyChildPtrStructure(Time, Copy, Original),
			_node(Original),
			_tempNode(Copy),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_tempChildNum(Copy, CopyChild, ChildNum).
_deepCopy(Time, CopyChild, OrigChild) 
		:-	_deepCopyChildren(Time, Copy, Original),
			_node(Original),
			_tempNode(Copy),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_tempChildNum(Copy, CopyChild, ChildNum).
		% from temp node to reg node
_introduce(Time, Copy, activechild, CopyChild)
		:-	_copyChildPtrStructure(Time, Copy, Original),
			_tempNode(Original),
			_node(Copy),
			_tempHolds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_tempChildNum(Original, OrigChild, ChildNum),
			_childNum(Copy, CopyChild, ChildNum).
_deepCopy(Time, CopyChild, OrigChild)
		:-	_deepCopyChildren(Time, Copy, Original),
			_tempNode(Original),
			_node(Copy),
			_tempHolds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_tempChildNum(Original, OrigChild, ChildNum),
			_childNum(Copy, CopyChild, ChildNum).


% detecting insufficient nodes: 
_insufficientNodesError % copying from tempnode to regular node
		:-	_deepCopyChildren(Time, Copy, Original),
			_tempNode(Original), _node(Copy),
			_tempHolds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_tempChildNum(Original, OrigChild, ChildNum),
			_maxNumChildren(Copy, MaxNumKids),
			ChildNum > MaxNumKids.
_insufficientNodesError	% copying from regular node to temp node 
		:-	_deepCopyChildren(Time, Copy, Original),
			_node(Original), _tempNode(Copy),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_maxNumTempChildren(Copy, MaxNumTempKids),
			ChildNum > MaxNumTempKids.
_insufficientNodesError	% copying from regular node to regular node 
		:-	_deepCopyChildren(Time, Copy, Original),
			_node(Original), _node(Copy),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_maxNumChildren(Copy, MaxNumTempKids),
			ChildNum > MaxNumTempKids.

% MISC Code
% replace parent with one of its children
_deepCopy(Time, Parent, Node)
		:-	_replaceParent(Time, Node),
			_isATermOf(Time, Parent, Node).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DEFINING TEMPNODES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: predicates for temp Nodes are different to avoid integrity 
% constraints being applied to tempNodes
_tempNode(_temp(Node))
		:-	_node(Node).

% create required predicates for temp nodes
_tempChildNum(_temp(Node), _temp(Child), ChildNum)	% parent, child, childnum
		:-	_childNum(Node, Child, ChildNum).
_tempChildOnSide(Temp, Child, left)
	:-	_tempChildNum(Temp, Child, 1).
_tempChildOnSide(Temp, Child, right)
	:-	_tempChildNum(Temp, Child, 2).
_validTempChildOf(_temp(Parent), _temp(Child))		% valid children
		:-	_childNum(Parent, Child, ChildNum).
_maxNumTempChildren(TempNode, NumChildren)			% max number of children
		:-	_maxNumChildren(Node, NumChildren), TempNode = _temp(Node).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SETTING TEMP NODE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% _tempHolds wraps fluents for temp nodes so they aren't persistent between time steps unlike _holds()
_activateTempNode(Time, Temp, Type)
		:-	_activateTempAndSetChildren(Time, Temp, Type, NumChildren),
			_tempNode(Temp).
_setTempChildren(Time, Temp, NumChildren)
		:-	_activateTempAndSetChildren(Time, Temp, Type, NumChildren),
			_tempNode(Temp).
_tempHolds(Time, _fact(Temp, _nodeField(type, Type)))
		:-	_activateTempNode(Time, Temp, Type),
			_tempNode(Temp).
_tempHolds(Time, _fact(Temp, _nodeField(active, yes)))
		:-	_activateTempNode(Time, Temp, Type),
			_tempNode(Temp).

% set as child any node with childNum in range 1..NumChildren
_tempHolds(Time, _fact(Temp, _nodeField(activechild, Child)))
		:-	_setTempChildren(Time, Temp, NumChildren),
			_tempNode(Temp),
			_tempChildNum(Temp, Child, Num),
			Num <= NumChildren.

% error checking: more temp nodes are requested than are available
_insufficientNodesError
		:-	_setTempChildren(Time, Temp, NumChildren),
			_maxNumTempChildren(Temp, MaxNumChildren),
			NumChildren > MaxNumChildren.

% helpers for copying
_copyAttributes(Time, Copy, Orig)
	:-	_copyAttribAndChildPtrStructure(Time, Copy, Orig).
_copyChildPtrStructure(Time, Copy, Orig)
	:-	_copyAttribAndChildPtrStructure(Time, Copy, Orig).

				%%% set temp Node to first degree binomial (x + c)
_activateTempAndSetChildren(Time, TempNode, add, 2)
	:-	_setToBinomial(Time, TempNode, Factor).

_activateTempNode(Time, Child, mono)
	:-	_setToBinomial(Time, TempNode, Factor),
		_tempChildOnSide(TempNode, Child, Side).

_setTempNodeToMono(Time, LeftChild, 1, 1)	% time, node, degree, coeff
	:-	_setToBinomial(Time, TempNode, Factor),
		_tempChildOnSide(TempNode, LeftChild, left).
_setTempNodeToMono(Time, RightChild, 0, Factor)
	:-	_setToBinomial(Time, TempNode, Factor),
		_tempChildOnSide(TempNode, RightChild, right).

				%%% adding monomial to temp node
_tempHolds(Time, _fact(Temp, _nodeField(degree, Deg)))
	:-	_setTempNodeToMono(Time, Temp, Deg, Coeff),
		_tempNode(Temp),
		_degree(Deg),
		_coeff(Coeff).
_tempHolds(Time, _fact(Temp, _nodeField(coeff, Coeff)))
	:-	_setTempNodeToMono(Time, Temp, Deg, Coeff),
		_tempNode(Temp),
		_degree(Deg),
		_coeff(Coeff).
_activateTempNode(Time, Temp, mono)
	:-	_setTempNodeToMono(Time, Temp, Deg, Coeff).

%%% CONSTRAINT: if we run out of nodes then fail
:- _insufficientNodesError.
%%% CONSTRAINT: for some reason _hasType was not being generated for all nodes
_hasNoType(Time, Node)
	:-	_holds(Time, _fact(Node, _nodeField(type, Type))), not _hasType(Time, Node, Type), _node(Node).
:-	_hasNoType(Time, Node).
