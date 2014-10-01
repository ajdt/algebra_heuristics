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
_pointerFact(activechild).
% for lack of a better name, simple facts are safe to make shallow copies of
_simpleFact(type;degree;coeff). 

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
