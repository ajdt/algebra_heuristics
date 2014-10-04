% Armando Diaz Tolentino <ajdt@cs.washington.edu> 
% 
% This file defines the nodes used in expression tree generation, and 
% useful predicates describing their properties. 
%
% NODE DESC:
% Nodes are grouped into layers, with the number of layers determined by the
% maximum tree depth allowed. There are two nodes in the first layer,
% nodes of each layer are assigned a specific number of children
% (see childrenForLayer predicate).
% 
%

% TODO: detect node overflow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODE LAYERS AND NODES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_nodeLayer(1..numNodeLayers).
_childrenForLayer(1, 4).	%(layer, count)
_childrenForLayer(2, 3).
_childrenForLayer(3, 3).
_childrenForLayer(4, 2).

% define left and right sides of eqn 
#const rightSide		= _id(1,2).	
#const leftSide 		= _id(1,1).

% define nodes based on layers and nodes in each layer
_rootNode(rightSide;leftSide).
_node(Node) 
		:-	_rootNode(Node).
_layerOfNode(_id(Layer, Number), Layer)
		:-	_node(_id(Layer, Number)).
_numberOfNode(_id(Layer, Number), Number)
		:-	_node(_id(Layer, Number)).

% number of children a node may have (varies by node depth)
_maxNumChildren(Node, NumChildren)
		:-	_childrenForLayer(Layer, NumChildren),
			_layerOfNode(Node, Layer).
_validNumChildren(Node, Num)
		:-	_maxNumChildren(Node, NumChildren),
			Num = 2..NumChildren.

% TODO: don't like the way nodes are defined 
_childNum(Node, NewNode, ChildNum)
		:-	_node(Node),
			_maxNumChildren(Node, NumChildren),
			_layerOfNode(Node, Layer),
			_numberOfNode(Node, NodeNum),
			NewNode = _id(NewLayer, ChildID),
			NewLayer = Layer+1,
			NewLayer <= numNodeLayers,
			ChildNum = 1..NumChildren,
			ChildID =(NodeNum - 1)*NumChildren + ChildNum.

_validChildOf(Parent, Child) 
		:-	_childNum(Parent, Child, ChildNum).
_node(Child)
		:-	_validChildOf(Parent, Child).

% NOTE: _id(...) should not be referenced outside of this code!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NODE PROPERTIES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
_depthOfNode(Node, Layer)	
		:-	_layerOfNode(Node, Layer).
% a node can only be a parent of nodes in succeeding layer

% enforcing the valid child constraint
:- _holds(Time, _fact(Parent, _nodeField(activechild, Child))),
	not _validChildOf(Parent, Child).

%  types of nodeField fields
_type(div;mul;add;mono).
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
		:-	_holds(Time, _fact(Node, _nodeField(active, yes))).
_hasType(Time, Node, Type)
		:-	_holds(Time, _fact(Node, _nodeField(type, Type))).
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
			not _isMono(Time, Node).

_activeChild(Time, Parent, Child)
		:-	_isActive(Time, Parent),
			_isActive(Time, Child),
			_validChildOf(Parent, Child).

% NOTE: monomials store degree and coeff info separately, to limit groundings when copying nodeFields
_degOf(Time, Node, Deg)
		:-	_holds(Time, _fact(Node, _nodeField(degree, Deg))).
_coeffOf(Time, Node, Coeff)
		:-	_holds(Time, _fact(Node, _nodeField(coeff, Coeff))).

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
% TODO: for testing visualizer only, remove later
_holds(_time(0,1), Fact)
		:-	_holds(initially, Fact).

_hasTwoTerms(Time, Node)
		:-	_validTime(Time),
			_node(Node),
			2 { _activeChild(Time, Node, Child) : _validChildOf(Node, Child) } 2.
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
_clearNodeDeleteDescendants(Time, Node)
		:-	_cancelTerm(Time, Node).
_removePointersToNode(Time, Node)
		:-	_cancelTerm(Time, Node).
_remove(Time, _fact(Parent, _nodeField(activechild, Node)))
		:-	_removePointersToNode(Time, Node),
			_activeChild(Time, Parent, Node).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% COPYING NODES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: all copying is deep copying

% deep copying means copying all attributes and deep copying children
_copyAttributes(Time, Copy, Orig)
		:-	_deepCopy(Time, Copy, Orig).
_deepCopyChildren(Time, Copy, Orig)
		:-	_deepCopy(Time, Copy, Orig).
% copying attributes
_introduce(Time, _fact(Copy, NodeFact))
		:-	_copyAttributes(Time, Copy, Original),
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
			_holds(Time, _fact(Original, _nodeField(activechild, OrigChild))),
			_childNum(Original, OrigChild, ChildNum),
			_childNum(Copy, CopyChild, ChildNum).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TEMPNODES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOTE: predicates for temp Nodes are different to make clear when we're
% talking about temp nodes.
_tempNode(_temp(Node))
		:-	_node(Node).
_layerOfTempNode(_temp(Node), Layer)
		:-	_layerOfNode(Node, Layer).
_numberOfTempNode(_temp(Node), Number)
		:-	_numberOfNode(Node, Number).
% number of children a node may have (varies by node depth)
_maxNumTempChildren(TempNode, NumChildren)
		:-	_childrenForLayer(Layer, NumChildren),
			_layerOfTempNode(TempNode, Layer).
_validNumTempChildren(TempNode, Num)
		:-	_maxNumTempChildren(TempNode, NumChildren),
			Num = 2..NumChildren.

% TODO: don't like the way nodes are defined 
_tempChildNum(_temp(Node), _temp(Child), childNum)
		:-	_childNum(Node, Child, ChildNum).

_validTempChildOf(_temp(Parent), _temp(Child))
		:-	_childNum(Parent, Child, ChildNum).

% useful handle for both types of nodes
_anyNode(TempNode)
		:-	_tempNode(TempNode).
_anyNode(Node)
		:-	_node(Node).
