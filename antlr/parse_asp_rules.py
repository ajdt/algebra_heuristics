import sys
from antlr4 import *
from PrologRulesLexer import *
from PrologRulesParser import *

from collections import namedtuple
Predicate           =   namedtuple('Predicate', ['name', 'args', 'arity'])
Rule                =   namedtuple('Rule', ['head', 'body'])
Comparision         =   namedtuple('Comparison', ['left', 'comparator', 'right'] )

#   body should be a list of conditions
PredCount           =   namedtuple('PredCount', ['left_count', 'predicate', 'body', 'right_count']) 
#class DefinedPredicate(Predicate):
    #"""A DefinedPredicate is just an ASP rule"""
    #def __new__(cls, name, args, arity, defining_predicates):
        #self = super(DefinedPredicate, cls).__new__(cls, name, args, arity)
        #self.def_predicates = defining_predicates
        #return self
    #def __str__(self):
        #return Predicate.__str__(self) + 'definiton: ' + ','.join([str(p) for p in self.def_predicates])

#prolog_file = FileStream('rules.lp')
prolog_file = FileStream(sys.argv[1])
lexer = PrologRulesLexer(prolog_file)
tokens = CommonTokenStream(lexer)
parser = PrologRulesParser(tokens)
tree = parser.listofrules()

# try get token stream? or consume
class RuleWalker(PrologRulesListener):
    """custom listener will walk a parse tree, and generate list of rules parsed """
    def __init__(self):
        super(RuleWalker, self).__init__()
        self.tree = []      # will contain list of parsed rules after walking the parsed tree

        # while tree is walked, this class gets a callback when a grammar rule (NOT ASP rule) defined in antlr
        # is entered, and when it's exited. container_stack is used to preserve the nested structure of
        # the rules. Whenever a non-terminal rule is entered, it pushes an empty list to this stack ,
        # to store all children in its parse subtree. When a rule finishes firing, we pop this same list (now
        # populated) from the stack, operate on it, and append it to the second to last list on the stack.
        # this way container_stack[0] will contain a list of parsed rules at the end.
        self.container_stack = [self.tree]

    # callback functions overridden from super class
    def enterPrologrule(self, ctx):
        self.pushContainer([])
    def exitPrologrule(self, ctx):
        parsed_rule = self.popContainer()
        head = parsed_rule[0]
        body = parsed_rule[1:]
        self.appendToLastContainer(Rule(head, body))
    def enterPredicate(self, ctx):
        self.pushContainer([])
    def exitPredicate(self, ctx):
        parsed_pred = self.popContainer()
        name = parsed_pred[0]
        if len(parsed_pred) > 1:
            args = parsed_pred[1]
            arity = len(args)
        else:
            args = None
            arity = 0 
        pred_obj = Predicate(name, args, arity)
        self.appendToLastContainer(pred_obj)
    def enterArgs(self, ctx):
        self.pushContainer([])
    def exitArgs(self, ctx):
        arg_list = self.popContainer()
        if len(arg_list) > 0:
            self.appendToLastContainer(arg_list)
    def exitAtom(self, ctx):
        self.appendToLastContainer(str(ctx.WORD()))

    # stack helpers, written only as a convenience
    def pushContainer(self, elem):
        self.container_stack.append(elem)
    def popContainer(self):
        last_elem = self.container_stack.pop()
        return last_elem
    def appendToLastContainer(self, elem):
        self.container_stack[-1].append(elem)

# print some info rpom parsing
printer = RuleWalker()
walker = ParseTreeWalker()

walker.walk(printer, tree)
print printer.tree
        

# misc classes needed:
# change definedPredicate to Rule:
# add code for comparison, test it out
# add code for predCount
# body is a list of predicates, comparisions and counts
# change atom to be either an identifier or a number

# should we have a base class for condition?
    # predicate
    # comparisons : variables, : can be turned into predicate easily, don't convert to avoid conflicts with predicate names
    # counters:     : have nested conditions, can't be turned into predicates so easily 
        # conditions could be factored out, but seems unnecessary to do so

