import sys
from antlr4 import *
from PrologRulesLexer import *
from PrologRulesParser import *

from collections import namedtuple
Predicate   =   namedtuple('Predicate', ['name', 'args', 'arity'])
class DefinedPredicate(Predicate):
    """A DefinedPredicate is just an ASP rule"""
    def __init__(self, name, args, arity, defining_predicates):
        Predicate.__init__(name, args, arity)
        self.def_predicates = defining_predicates
    def __str__(self):
        return Predicate.__str__(self) + 'definiton: ' + ','.join([p.__str__ for p in self.def_predicates])

#prolog_file = FileStream('rules.lp')
prolog_file = FileStream(sys.argv[1])
lexer = PrologRulesLexer(prolog_file)
tokens = CommonTokenStream(lexer)
parser = PrologRulesParser(tokens)
tree = parser.prologrule()

# try get token stream? or consume
class KeyPrinter(PrologRulesListener):
    """custom listener will print info"""
    def __init__(self):
        super(KeyPrinter, self).__init__()
        self.tree = []
        self.container_queue = [self.tree]
    def enterPredicate(self, ctx):
        self.container_queue.append([])
    def exitPredicate(self, ctx):
        parsed_pred = self.container_queue.pop()
        name = parsed_pred[0]
        if len(parsed_pred) > 1:
            args = parsed_pred[1]
            arity = len(args)
        else:
            args = None
            arity = 0 
        pred_obj = Predicate(name, args, arity)
        self.container_queue[-1].append(pred_obj)
    def enterArgs(self, ctx):
        self.container_queue.append([])
    def exitArgs(self, ctx):
        arg_list = self.container_queue.pop()
        if len(arg_list) > 0:
            self.container_queue[-1].append(arg_list)
    def exitAtom(self, ctx):
        self.container_queue[-1].append(str(ctx.WORD()))

# print some info rpom parsing
printer = KeyPrinter()
walker = ParseTreeWalker()

walker.walk(printer, tree)
print printer.tree
        
# classes to be created
# Predicate
    # name and variables
# DefinedPredicate (aka rule)
    # has other Predicates as explanations
    # has an arity field
    # has a generate explanations field
    # (will be added to a dict that indexes based on name and arity)
# args: can just be a tuple or list, remember to preserve order
        
