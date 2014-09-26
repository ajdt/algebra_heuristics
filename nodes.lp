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
#include "config_params.lp".
_nodeLayer(1..numNodeLayers).
_childrenForLayer(1, 4).	%(layer, count)
_childrenForLayer(2, 3).
_childrenForLayer(3, 3).
_childrenForLayer(4, 2).

% define left and right sides of eqn 
#const rightSide		= _id(1,2).	
#const leftSide 		= _id(1,1).

% define nodes based on layers and nodes in each layer
_node(rightSide;leftSide).
_layerOfNode(_id(Layer, Number), Layer)
		:-	_node(_id(Layer, Number)).
_numberOfNode(_id(Layer, Number), Number)
		:-	_node(_id(Layer, Number)).

% TODO: don't like the way nodes are defined 
_childNum(Node, NewNode, ChildNum)
		:-	_node(Node),
			_layerOfNode(Node, Layer),
			_numberOfNode(Node, NodeNum),
			_childrenForLayer(Layer, NumChildren),
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
		:-	_layerOf(Node, Layer).
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

% node fields
_numerOf(Time, Node, Child)
		:-	_holds(Time, _fact(Node, _nodeField(numer, Child))).
_denomOf(Time, Node, Child)
		:-	_holds(Time, _fact(Node, _nodeField(denom, Child))).

% NOTE: monomials store degree and coeff info separately, to limit groundings when copying nodeFields
_degOf(Time, Node, Deg)
		:-	_holds(Time, _fact(Node, _nodeField(degree, Deg))).
_coeffOf(Time, Node, Coeff)
		:-	_holds(Time, _fact(Node, _nodeField(coeff, Coeff))).

