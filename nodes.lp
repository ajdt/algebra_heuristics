% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file defines the nodes used in expression tree generation, and 
% useful predicates describing their properties. 
%
% NODE DESC:
% Nodes are grouped into layers, with the number of layers determined by the
% maximum tree depth allowed. There are two nodes in the first layer,
% nodes of each layer are assigned a specific number of children
% (see childrenAtDepth predicate).
% 
%

% TODO: detect node overflow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODE DEPTH, CHILDREN AND NODE GENERATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_depthValue(1..maxDepth).

_childCount(2..maxChildren).	% childCount defines upper and lower limit on number of children allowable
								% childrenAtDepth defines a more constraining upper limit depending on node depth
_childrenAtDepth(1, 3).	%(depth, numChildren)
_childrenAtDepth(2, 3).
_childrenAtDepth(3, 3).
_childrenAtDepth(4, 2).

% define left and right sides of eqn 
#const rightSide		= _id(1,2).	
#const leftSide 		= _id(1,1).
#const tempRoot			= _temp(_id(1,1)).
#const tempRightRoot	= _temp(_id(1,2)).

% define nodes based on layers and nodes in each layer
_rootNode(rightSide;leftSide).
_node(Node) 
		:-	_rootNode(Node).
_nodeDepth(_id(Depth, Number), Depth)
		:-	_node(_id(Depth, Number)).
_numberOfNode(_id(Depth, Number), Number)
		:-	_node(_id(Depth, Number)).

% number of children a node may have (varies by node depth)
_maxNumChildren(Node, NumChildren)
		:-	_childrenAtDepth(Depth, NumChildren),
			_nodeDepth(Node, Depth),
			Depth < maxDepth.
_maxNumChildren(Node, 0)	% leaf nodes don't have children
		:-	_nodeDepth(Node, Depth),
			Depth == maxDepth.

% TODO: don't like the way nodes are defined 
_childNum(Node, NewNode, ChildNum)
		:-	_node(Node),
			_maxNumChildren(Node, NumChildren),
			_nodeDepth(Node, Depth),
			_numberOfNode(Node, NodeNum),
			NewNode = _id(NewDepth, ChildID),
			NewDepth = Depth+1,
			NewDepth <= maxDepth,
			ChildNum = 1..NumChildren,
			ChildID =(NodeNum - 1)*NumChildren + ChildNum.
% useful aliases for first two children
_childOnSide(Node, Child, left)
	:-	_childNum(Node, Child, 1).
_childOnSide(Node, Child, right)
	:-	_childNum(Node, Child, 2).

_validChildOf(Parent, Child) 
		:-	_childNum(Parent, Child, ChildNum).
_node(Child)
		:-	_validChildOf(Parent, Child).

% NOTE: _id(...) should not be referenced outside of this code!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% a node can only be a parent of nodes in succeeding layer

% CONSTRAINT: enforcing the valid child constraint
:- _holds(Time, _fact(Parent, _nodeField(activechild, Child))),
	_node(Parent), _node(Child),
	not _validChildOf(Parent, Child).

%  types of nodeField fields
_type(div;mul;add;mono).
_commutatitve(mul;add).
_pointerField(activechild).
% for lack of a better name, simple facts are safe to make shallow copies of
_simpleField(type;degree;coeff;active). 

% derived node properties: don't need to be updated, but rather can be 
% obtained from regular holds() predicates

					%%% Aliases %%%
% These are 'derived' fluents from the holds(..) fluents.
% Outside code should mostly reference these aliases so
% changes to node representation can be made easily.
% node type
_isActive(Time, Node)
		:-	_holds(Time, _fact(Node, _nodeField(active, yes))),
			_node(Node).
_hasType(Time, Node, Type)
		:-	_holds(Time, _fact(Node, _nodeField(type, Type))),
			_node(Node).

_isDiv(Time, Node)
		:-	_hasType(Time, Node, div).
_isMul(Time, Node)
		:-	_hasType(Time, Node, mul).
_isAdd(Time, Node)
		:-	_hasType(Time, Node, add).
_isMono(Time, Node)
		:-	_hasType(Time, Node, mono).
_isOper(Time, Node)
		:-	_isActive(Time, Node),
			_hasType(Time, Node, Type),
			Type != mono.

_parentType(Time, Child, Type)
		:-	_activeChild(Time, Parent, Child),
			_hasType(Time, Parent, Type).

_activeChild(Time, Parent, Child)
		:-	_isActive(Time, Parent),
			_isActive(Time, Child),
			_validChildOf(Parent, Child).

_siblings(Time, FstChild, SndChild)
		:-	_activeChild(Time, Parent, FstChild),
			_activeChild(Time, Parent, SndChild),
			FstChild != SndChild.
_swappableTerms(Time, Fst, Snd)
		:-	_siblings(Time, Fst, Snd),
			_parentType(Time, Fst, Type),
			_commutatitve(Type).

% nodes equal to zero
_isOne(Time, Node)
	:-	_isMono(Time, Node),
		_coeffOf(Time, Node, 1),
		_degOf(Time, Node, 0).

_isZero(Time, Node)
		:-	_coeffOf(Time, Node, 0).
_reducibleToZero(Time, Node)
		:-	_isZero(Time, Node).
_reducibleToZero(Time, Node)
		:-	_isMul(Time, Node),
			_activeChild(Time, Node, Child),
			_reducibleToZero(Time, Child).
_reducibleToZero(Time, Node)
		:-	_isOper(Time, Node),
			_everyChildReducesToZero(Time, Node).
_everyChildReducesToZero(Time, Node)
		:-	_isOper(Time, Node),
			not _hasNonZeroChild(Time, Node).
_hasNonZeroChild(Time, Node)
		:-	_isOper(Time, Node),
			_activeChild(Time, Node, Child),
			not _reducibleToZero(Time, Child).
					%%% node fields %%%
% NOTE: monomials store degree and coeff info separately, to limit groundings when copying nodeFields
_degOf(Time, Node, Deg)
		:-	_holds(Time, _fact(Node, _nodeField(degree, Deg))),
			_node(Node).
_coeffOf(Time, Node, Coeff)
		:-	_holds(Time, _fact(Node, _nodeField(coeff, Coeff))),
			_node(Node).

% NOTE: used for fraction cancel rule, not much else
_factorOf(Time, Node, Child)
	:-	_isMul(Time, Node),
		_activeChild(Time, Node, Child).
_factorOf(Time, Node, Node)
	:-	_isActive(Time, Node),
		not _isMul(Time, Node).
_haveCommonFactors(Time, FstNode, SndNode)
	:-	_siblings(Time, FstNode, SndNode),
		_factorOf(Time, FstNode, FstFactor),
		_factorOf(Time, SndNode, SndFactor),
		_equal(Time, FstFactor, SndFactor).

% node fields
_numerOf(Time, Parent, Child)
		:-	_isDiv(Time, Parent),
			_activeChild(Time, Parent, Child),
			_childNum(Parent, Child, 1).
_denomOf(Time, Parent, Child)
		:-	_isDiv(Time, Parent),
			_activeChild(Time, Parent, Child),
			_childNum(Parent, Child, 2).

% TODO: come up with more permanent solution for numer/denom stuff
_holds(Time, _fact(Parent, _nodeField(numer, Child)))
		:-	_numerOf(Time, Parent, Child).

_holds(Time, _fact(Parent, _nodeField(denom, Child)))
		:-	_denomOf(Time, Parent, Child).

_hasTwoTerms(Time, Node)
		:-	_validTime(Time),
			_node(Node),
			2 { _activeChild(Time, Node, Child) : _validChildOf(Node, Child) } 2.
_parentHasTwoChildren(Time, Child)
		:-	_hasTwoTerms(Time, Parent),
			_activeChild(Time, Parent, Child).

% fractions that have same denominator
% XXX: fractions must be siblings to be considered for sameDenom
_sameDenom(Time, FstFrac, SndFrac)
	:-	_siblings(Time, FstFrac, SndFrac),
		_denomOf(Time, FstFrac, FstDenom),
		_denomOf(Time, SndFrac, SndDenom),
		_equal(Time, FstDenom, SndDenom).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CHANGING NODE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_update(Time, Node, type, Oper)
		:-	_setNodeType(Time, Node, Oper).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SUBTREE OPERATIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_nodeOper(delete;deallocate;clear).

_applyNodeOp(Time, Node, Op)
		:-	_applyNodeOpRecursive(Time, Node, Op).
_applyNodeOpRecursive(Time, Child, Op)
		:-	_applyNodeOpRecursive(Time, Node, Op),
			_activeChild(Time, Node, Child).

% applying the operations
% NOTE: won't delete any nodes in the subtree rooted at 'Node'
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
			_activeChild(Time, RootNode, Child).
%% remove a subtree including pointers to it
% cancelTerm -- used to remove terms cancelled via division operation, may update parent
% deleteTerm -- delete a subtree
% NOTE: three different ways to cancelTerm depending on context

_setToOne(Time, Node)	% term is numer or denom of a fraction
		:-	_cancelTerm(Time, Node),
			_parentType(Time, Node, div).

_replaceParent(Time, Sibling) 	% term is one of two children, replace parent with other child
		:-	_cancelTerm(Time, Node),
			not _parentType(Time, Node, div),
			_parentHasTwoChildren(Time, Node),
			_siblings(Time, Node, Sibling),
			not _cancelTerm(Time, Sibling),	% ensure the other child isn't also cancelled
			Sibling != Node.
% NOTE: if parent has more than two children, we assume that @ least two children will
% remain after current time step
_deleteTerm(Time, Term)
		:-	_cancelTerm(Time, Term).

_clearNodeDeleteDescendants(Time, Node)
		:-	_deleteTerm(Time, Node).
_removePointersToNode(Time, Node)
		:-	_deleteTerm(Time, Node).
		
_remove(Time, _fact(Parent, _nodeField(activechild, Node)))
		:-	_removePointersToNode(Time, Node),
			_activeChild(Time, Parent, Node).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COPYING NODES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: all copying is deep copying

% replace parent with one of its children
_deepCopy(Time, Parent, Node)
		:-	_replaceParent(Time, Node),
			_activeChild(Time, Parent, Node).

% deep copying means copying all attributes and deep copying children
_copyAttributes(Time, Copy, Orig)
		:-	_deepCopy(Time, Copy, Orig).
_deepCopyChildren(Time, Copy, Orig)
		:-	_deepCopy(Time, Copy, Orig).
_clearNodeDeleteDescendants(Time, Copy)
		:-	_deepCopy(Time, Copy, Orig),
			_node(Copy).	% NOTE: temp nodes don't have to be cleared
% copying attributes
_introduce(Time, _fact(Copy, NodeFact))
		:-	_copyAttributes(Time, Copy, Original),
			_node(Copy),
			_holds(Time, _fact(Original, _nodeField(Field, Value))),
			_simpleField(Field),
			NodeFact = _nodeField(Field, Value).
% deep copying children
_deepCopy(Time, CopyChild, OrigChild)
		:-	_deepCopyChildren(Time, Copy, Original),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_childNum(Copy, CopyChild, ChildNum).
_introduce(Time, Copy, activechild, CopyChild)
		:-	_deepCopyChildren(Time, Copy, Original),
			_node(Copy),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_childNum(Copy, CopyChild, ChildNum).

% deep copying children of temp nodes
_deepCopy(Time, CopyChild, OrigChild)
		:-	_deepCopyChildren(Time, Copy, Original),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_tempChildNum(Original, OrigChild, ChildNum),
			_childNum(Copy, CopyChild, ChildNum).
_introduce(Time, Copy, activechild, CopyChild)
		:-	_deepCopyChildren(Time, Copy, Original),
			_node(Copy),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_tempChildNum(Original, OrigChild, ChildNum),
			_childNum(Copy, CopyChild, ChildNum).

% if copying into a tempNode, use holds instead we want copy to exist during current 'Time'
_holds(Time, _fact(Copy, NodeFact))	
		:-	_copyAttributes(Time, Copy, Original),
			_tempNode(Copy),
			_holds(Time, _fact(Original, _nodeField(Field, Value))),
			_simpleField(Field),
			NodeFact = _nodeField(Field, Value).
% TODO: this is needed to copy from regular node to a temp node. Try simplifying all of this copying code!!!
_holds(Time, _fact(Copy, _nodeField(activechild, CopyChild)))
		:-	_deepCopyChildren(Time, Copy, Original),
			_tempNode(Copy),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_tempChildNum(Copy, CopyChild, ChildNum).
_deepCopy(Time, CopyChild, OrigChild) % NOTE: necessary for copying from regular to tempNode
		:-	_deepCopyChildren(Time, Copy, Original),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_tempChildNum(Copy, CopyChild, ChildNum).

% detecting insufficient nodes: 
% TODO: copying code has gotten too complex, simplify it
_insufficientNodesError % copying from tempnode to regular node
		:-	_deepCopyChildren(Time, Copy, Original),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_tempChildNum(Original, OrigChild, ChildNum),
			_maxNumChildren(Copy, MaxNumKids),
			ChildNum > MaxNumKids.
_insufficientNodesError	% copying from original node to temp node 
		:-	_deepCopyChildren(Time, Copy, Original),
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_maxNumTempChildren(Copy, MaxNumTempKids),
			ChildNum > MaxNumTempKids.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TEMPNODES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: predicates for temp Nodes are different to make clear when we're
% talking about temp nodes.
_matchingTempNode(Node, _temp(Node))
	:-	_node(Node).
_tempNode(_temp(Node))
		:-	_node(Node).
_tempNodeDepth(_temp(Node), Depth)	% TODO: may not be needed
		:-	_nodeDepth(Node, Depth).
_numberOfTempNode(_temp(Node), Number) % TODO: may not be needed
		:-	_numberOfNode(Node, Number).
% number of children a node may have (varies by node depth)
_maxNumTempChildren(_temp(Node), NumChildren)
		:-	_maxNumChildren(Node, NumChildren).
_validNumTempChildren(TempNode, Num)
		:-	_maxNumTempChildren(TempNode, NumChildren),
			Num = 2..NumChildren.

_tempChildNum(_temp(Node), _temp(Child), ChildNum)
		:-	_childNum(Node, Child, ChildNum).
_tempChildOnSide(Temp, Child, left)
	:-	_tempChildNum(Temp, Child, 1).
_tempChildOnSide(Temp, Child, right)
	:-	_tempChildNum(Temp, Child, 2).

_validTempChildOf(_temp(Parent), _temp(Child))
		:-	_childNum(Parent, Child, ChildNum).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SETTING TEMP NODE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_activateTempNode(Time, Temp, Type)
		:-	_activateTempAndSetChildren(Time, Temp, Type, NumChildren),
			_tempNode(Temp).
_setTempChildren(Time, Temp, NumChildren)
		:-	_activateTempAndSetChildren(Time, Temp, Type, NumChildren),
			_tempNode(Temp).
_holds(Time, _fact(Temp, _nodeField(type, Type)))
		:-	_activateTempNode(Time, Temp, Type),
			_tempNode(Temp).
_holds(Time, _fact(Temp, _nodeField(active, yes)))
		:-	_activateTempNode(Time, Temp, Type),
			_tempNode(Temp).

% set as child any node with childNum in range 1..NumChildren
_holds(Time, _fact(Temp, _nodeField(activechild, Child)))
		:-	_setTempChildren(Time, Temp, NumChildren),
			_tempNode(Temp),
			_tempChildNum(Temp, Child, Num),
			Num <= NumChildren.

% error checking: more temp nodes are requested than are available
_insufficientNodesError
		:-	_setTempChildren(Time, Temp, NumChildren),
			_maxNumTempChildren(Temp, MaxNumChildren),
			NumChildren > MaxNumChildren.

% fail if more children are requested  than are available
_insufficientNodesError
		:-	_setTempChildren(Time, Temp, NumChildren),
			_tempNode(Temp),
			not _validNumTempChildren(Temp, NumChildren).

% setting to binomial
_activateTempAndSetChildren(Time, TempNode, add, 2)
	:-	_setToBinomial(Time, TempNode, Factor).

_activateTempNode(Time, Child, mono)
	:-	_setToBinomial(Time, TempNode, Factor),
		_tempChildOnSide(TempNode, Child, Side).

_addMonomToNode(Time, LeftChild, 1, 1)	% time, node, degree, coeff
	:-	_setToBinomial(Time, TempNode, Factor),
		_tempChildOnSide(TempNode, LeftChild, left).
_addMonomToNode(Time, RightChild, 0, Factor)
	:-	_setToBinomial(Time, TempNode, Factor),
		_tempChildOnSide(TempNode, RightChild, right).

% adding monomial to temp node
_holds(Time, _fact(Temp, _nodeField(degree, Deg)))
	:-	_addMonomToNode(Time, Temp, Deg, Coeff),
		_tempNode(Temp),
		_degree(Deg),
		_coeff(Coeff).
_holds(Time, _fact(Temp, _nodeField(coeff, Coeff)))
	:-	_addMonomToNode(Time, Temp, Deg, Coeff),
		_tempNode(Temp),
		_degree(Deg),
		_coeff(Coeff).
%%% CONSTRAINT: if we run out of nodes then fail
:- _insufficientNodesError.

%%% CONSTRAINT: for some reason _hasType was not being generated for all nodes
:-	_holds(Time, _fact(Node, _nodeField(type, Type))), not _hasType(Time, Node, Type), _node(Node).
