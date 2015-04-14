#!/usr/bin/env python
#
# Author:   Armando Diaz Tolentino <ajdt@cs.washington.edu> 
#
# Desc:     Manages a single answer set's predicates and handles unification
#           when we generate explanations.
#
from collections import defaultdict

class ModelManager(object):
    """records every atom for a generated model (answer set)"""
    # NOTE: I actually use a different ModelManager for each time step within a given model
    def __init__(self):
        super(ModelManager, self).__init__()
        self.model_predicates = defaultdict(list)
    def addPredicate(self, predicate_string):
        """add grounded predicate to model"""
        pred_name, operands = ModelManager.splitPredicate(predicate_string)
        pred_key = (pred_name, len(operands))
        self.model_predicates[pred_key].append(operands)

    def unify(self, pred_key, partial_assign):
        if not self.model_predicates.has_key(pred_key):
            return []
        match_key = self.model_predicates[pred_key]
        return [grounding for grounding in match_key if self.matches(grounding, partial_assign)]

    def matches(self, grounding, partial_assign):
        # checks if partial assignment of variables is consistent with given grounding
        return all(map(lambda x,y: x == y or y == None, grounding, partial_assign))

    # TODO: remove, for testing purposes only
    def printModel(self):
        for pred_key, val_list in self.model_predicates.items():
            print pred_key[0]
            for values in val_list:
                print '\t\t', values

    @staticmethod
    def splitPredicate(pred_string):
        """return predicate name and list of operands from predicate string"""
        # remove all whitespace first
        pred_string = ''.join(pred_string.split())
        open_paren  = pred_string.find('(')
        close_paren = pred_string.rfind(')')

        if open_paren == -1 or close_paren == -1:
            return (pred_string, [])
            
        pred_name       = pred_string[:open_paren]
        operand_str     = pred_string[open_paren+1:close_paren]
        # split operands into an array
        start_idx       = 0
        paren_level     = 0

        operands = []
        for index in range(0, len(operand_str)):
            if operand_str[index] == '(':
                paren_level += 1
            elif operand_str[index] == ')':
                paren_level -= 1
            elif operand_str[index] == ',' and paren_level == 0:
                operands.append(operand_str[start_idx:index])
                start_idx = index + 1
                continue

            # add the last operand
            if index == len(operand_str) - 1 and paren_level == 0: 
                operands.append(operand_str[start_idx:])
                
        return (pred_name, operands)

    # TODO: figure out how this code is used externally
    # TODO: any redundant code above is depricated

    # XXX: the code below uses pred objects as defined in pred_parser.py
    #       and rule objects defined in parse_asp_rules.py.

    # get all ground instances of a certain predicate key
    def getAllGroundInstancesOf(self, pred_key):
        return list(self.model_predicates[pred_key])

        



