import subprocess
import tempfile # for temporarily saving piped output from clingo
import sys
import argparse
import eqn_viz
import pygraphviz as pgv

class ClingoRunner:
    """Run clingo based on command line arguments, optionally generates graph based on generated problems"""
    BASH_COMMAND = "clingo eqn_generator.lp --project -n 0 --outf=2 "
    TEST_COMMAND = "cat three_steps_output" # used for testing, for faster turnaround

    BOOLEAN_FLAGS = ['iterative', 'json']
    def __init__(self, bash_cmd=BASH_COMMAND, flags=BOOLEAN_FLAGS, misc_params=dict()):
        self.bash_cmd   =   bash_cmd
        self.boolean_flags = flags
        self.misc_params = misc_params
        self.cmd_parser =   self.initCmdParser()
        self.args       =   self.cmd_parser.parse_args()

    def initCmdParser(self):
        param_file = open('solver_default_config.txt')
        cmd_parser = argparse.ArgumentParser(description='create DAG with ASP code')
        # init parser with available arguments/default values 
        for line in param_file:
            param, default_value = line.split()
            cmd_parser.add_argument('--'+param, default=default_value, required=False)
        param_file.close()

        # add optional flags
        for flag in self.boolean_flags:
            cmd_parser.add_argument('--' + flag, action='store_true')

        # add more params as required
        for param, default_value in self.misc_params.items():
            cmd_parser.add_argument('--'+param, default=default_value, required=False)
        return cmd_parser

    def writeSolverConfigFile(self, param_dict, filename='config_params.lp', misc_constraints=''):
        solver_file = open(filename, 'w')
        for (param, value) in param_dict.items():
            if param not in self.boolean_flags and param not in self.misc_params:
                solver_file.write('#const ' + param + ' = ' + value +'.\n')

        # also write overflow constraints
        # solver_file.write(':- _coeffOverflow.\n')
        # solver_file.write(':- _degOverflow.\n')
        solver_file.write(misc_constraints)
        solver_file.close()

    def runSolver(self, make_graph=True):
        # write the config file needed to run the program
        param_dict = vars(self.args)
        if param_dict.has_key('iterative'):
            generated = self.iterativeDeepeningGeneration(param_dict)
        else:
            generated = [self.computeAnsSets(param_dict)]

        self.displayAnsSets(generated, make_graph)

    def displayAnsSets(self, ans_set_list, make_graph=True):
        # display each answer set, and save the generated problems in a separate list
        # NOTE: when running iterative deepening, we produce several ans_set_managers
        #       each answer set manager can contain multiple answer sets, and each answer set
        #       can contain multiple problems, so the generated problems may be heavily nested
        generated_problems = []
        for ans_set_manager in ans_set_list:
            ans_set_manager.printAnswerSets()
            # for now taking only the first solution, hence subscript 1
            for ans_set in ans_set_manager.getGeneratedAnsSets():
                generated_problems.append(ans_set.getMathProblems()[0])


        # create graph
        if make_graph:
            self.graph = Graph(generated_problems)
        #print self.graph.getGraphEdges()
        #print self.graph.nodes.keys()

    def iterativeDeepeningGeneration(self, param_dict):
        """ return a list of AnswerSetManager instances"""
        ans_set_manager_list = []
        for num_steps in range(1, int(param_dict['maxSteps']) + 1):
            param_dict['maxSteps'] = str(num_steps)
            ans_set_manager_list.append(self.computeAnsSets(param_dict))
        return ans_set_manager_list

    def computeAnsSets(self, param_dict):
        """ run clingo with param_dict options, and return the resulting AnswerSetManager instance"""
        self.writeSolverConfigFile(param_dict)
        # run the process
        process = subprocess.Popen(self.bash_cmd.split(), stdout=subprocess.PIPE)
        output = process.communicate()[0]
        return self.parseGeneratedProblems(output)

    def parseGeneratedProblems(self, json_output):
        """ parse output string with AnswerSetManager and return the manager"""
        # set stdin to be json_output
        # NOTE: eqn_viz.AnswerSetManager can only read from file or from stdin, so
        # we save output to a temporary file and set it to stdin
        old_stdin = sys.stdin
        temp_file = tempfile.TemporaryFile(mode='w+')
        temp_file.write(json_output)
        temp_file.seek(0) # file obj only has one file pointer (go to start of file for reading)
        sys.stdin = temp_file

        # initialize manager
        manager = eqn_viz.AnswerSetManager({}) # NOTE: we're not passing any cmd line args
        manager.initFromSTDIN()

        # set stdin to old value
        sys.stdin = old_stdin

        return manager



class Node(object):
    def __init__(self, generated_prob):
        super(Node, self).__init__()
        self.generated_prob = generated_prob
        self.actions = sorted(self.generated_prob.equation_parameters['selected_heuristics']) # sort actions so they're in some canonical order
        self.label = self.makeLabel()
        self.n_gram_dict = {}
        self.initNGrams()
    def makeLabel(self):
        return ':'.join(self.actions)
    def getProblem(self):
        return self.generated_prob.getProblemString()
    def getLabel(self):
        return self.label
    def getSolution(self):
        return self.generated_prob.getSolutionString()
    def initNGrams(self, num=2):
        for n_gram in range(1,num+1):
            current_n_gram_list = []
            for start_idx in range(0, len(self.actions)):
                stop_idx = start_idx+n_gram
                new_ngram = ''.join(self.actions[start_idx:stop_idx])
                current_n_gram_list.append(new_ngram)
            self.n_gram_dict[n_gram] = current_n_gram_list

class Graph(object):
    def __init__(self, generated_probs):
        super(Graph, self).__init__()
        self.generated_probs  = generated_probs
        self.nodes      = {}
        self.edges      = []
        for prob in generated_probs:
            self.addNodeFromSoln(prob)
        # now form the edges of the graph
        self.formGraphEdges()
        
        # add pygraphviz object for images
        self.visual_graph = pgv.AGraph()
        self.initVisualGraph()

    def addNodeFromSoln(self, generated_problem):
        new_node = Node(generated_problem)
        if new_node.getLabel() == '': # don't save cases where no rule is used
            return
        self.nodes[new_node.getLabel()] = new_node
    def formGraphEdges(self):
        for node in self.nodes.values():
            self.addEdgesForNode(node, ngram_level=1)
    def addEdgesForNode(self, node, ngram_level=1):
        for n_gram in node.n_gram_dict[ngram_level]:
            if n_gram == node.label: # no self loops
                continue
            # node with n-gram label exists, so create edge between the nodes
            elif self.nodes.has_key(n_gram):
                self.edges.append((n_gram, node.label))
    def getGraphEdges(self):
        return '\n'.join([ src + '->' + dest for src, dest in self.edges])
    def addNodesToGraphViz(self):
        for node in self.nodes.values():
            self.visual_graph.add_node(node.label, label=node.label+'\n'+node.getProblem())
    def initVisualGraph(self):
        self.visual_graph = pgv.AGraph(directed=True)
        self.addNodesToGraphViz()
        self.visual_graph.add_edges_from(self.edges)
        self.visual_graph.layout(prog='fdp')
        self.visual_graph.draw('graph.png')


if __name__ == "__main__":
    ClingoRunner().runSolver()
