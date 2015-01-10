import sys
from antlr4 import *
from PrologRulesLexer import *
from PrologRulesParser import *
from collections import namedtuple

# define tuples to store parsed predicate info
Predicate           =   namedtuple('Predicate', ['name', 'args', 'arity'])
Rule                =   namedtuple('Rule', ['head', 'body'])
Comparison          =   namedtuple('Comparison', ['left', 'comparator'] )
PredCount           =   namedtuple('PredCount', ['left_count', 'predicate', 'conditions', 'right_count']) # body is list of conditions

# try get token stream? or consume
class RuleListener(PrologRulesListener):
    """custom listener will generate list of rules parsed, when passed to a tree walker """
    def __init__(self):
        super(RuleListener, self).__init__()
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
    def enterComparator(self, ctx):
        self.pushContainer([])
    def exitComparator(self, ctx):
        compared_atoms = self.popContainer()
        var_name    = compared_atoms[0]
        comparison  = str(ctx.RELOPERATOR())
        comp_object = Comparison(var_name, comparison) 
        self.appendToLastContainer(comp_object)
    def enterGuessrule(self, ctx):  # want to ignore guessrules
        self.pushContainer([])
    def exitGuessrule(self, ctx):
        self.popContainer()
    def enterPredcount(self, ctx):
        self.pushContainer([])
    def isolatePredcountData(self, predcount_data):
        """ Isolate predcount data from a parse tree walk.
            predcount_data may look like: [left_count, head, body, right_count].
            Only head is guaranteed to exist, anything else will exist in that relative order if at all.
        """
        left_count, head, body, right_count = (None, None, None, None)

        # find and set the value for head 
        head_idx = map(lambda x : isinstance(x, Predicate), predcount_data).index(True)
        head = predcount_data[head_idx]

        # check if a left_count comes before head
        if head_idx == 1 :
            left_count = predcount_data[0]

        # parse body and right_count
        other_data = predcount_data[head_idx+1:]
        if len(other_data) == 1 :
            if isinstance(other_data[0], list):
                body = other_data[0]
            else:
                right_count = other_data[0]
        elif len(other_data) == 2 :
            body = other_data[0]
            right_count = other_data[1]

        return (left_count, head, body, right_count)
    def exitPredcount(self, ctx):
        result = self.popContainer()
        left, head, body, right = self.isolatePredcountData(result)
        pred_count = PredCount(left, head, body, right )
        self.appendToLastContainer(pred_count)

    # callbacks for terminal nodes: push text value of terminal node
    def exitAtom(self, ctx):
        if ctx.NUMBER() != None:
            self.appendToLastContainer(str(ctx.NUMBER()))
        # NOTE: if Atom is WORD then it's parsed as an identifer and exitIdentifier() adds it to last container
    def exitIdentifier(self, ctx):
        self.appendToLastContainer(str(ctx.WORD()))


    # stack helpers, written only as a convenience
    def pushContainer(self, elem):
        self.container_stack.append(elem)
        #print self.container_stack
    def popContainer(self):
        last_elem = self.container_stack.pop()
        #print self.container_stack
        return last_elem
    def appendToLastContainer(self, elem):
        self.container_stack[-1].append(elem)
        #print self.container_stack

def parseRulesFromFile(file_name):
    """return a list of ASP rules parsed from given file
        XXX: expects the file to contain only rules (no const definitions, facts, comments, or constraints). Other functions handle cleanup
    """
    # read asp file, lex, parse and create parse tree for its contents 
    prolog_file = FileStream(file_name)
    lexer = PrologRulesLexer(prolog_file)
    tokens = CommonTokenStream(lexer)
    parser = PrologRulesParser(tokens)
    tree = parser.listofrules()

    # initialize listener and walk tree (generates tree info)
    printer = RuleListener()
    walker = ParseTreeWalker()
    walker.walk(printer, tree)
    return printer.tree

def main():
    for rule in parseRulesFromFile(sys.argv[1]):
        print rule 
        print '\n'

if __name__ == '__main__':
    main()
