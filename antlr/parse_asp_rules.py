import sys
from antlr4 import *
from PrologRulesLexer import *
from PrologRulesParser import *
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
        self.current_pred = None
        self.current_args = None
        self.current_container = None
    def enterPredicate(self, ctx):
        self.current_pred = []
        self.current_container = self.current_pred
    def exitPredicate(self, ctx):
        self.tree.append(self.current_pred)
        self.current_pred = None
        self.current_container = None
    def enterArgs(self, ctx):
        self.current_args = []
        self.current_container = self.current_args
    def exitArgs(self, ctx):
        if self.current_args != None:
            self.current_pred.append(self.current_args)
        self.current_args = None
        self.current_container = self.current_pred
    def exitAtom(self, ctx):
        if self.current_container != None:
            self.current_container.append(str(ctx.WORD()))

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
