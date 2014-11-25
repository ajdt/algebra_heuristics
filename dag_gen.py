import subprocess
import argparse
import eqn_viz
import pygraphviz as pgv

class ClingoRunner:
	"""Run clingo based on command line arguments"""
	BASH_COMMAND = "clingo eqn_generator.lp --project -n 0 --outf=2 "
	TEST_COMMAND = "cat three_steps_output" # used for testing, for faster turnaround

	BOOLEAN_FLAGS = ['iterative', 'json']
	def __init__(self):
		self.cmd_parser	=	self.initCmdParser()
		self.args		=	self.cmd_parser.parse_args()

	def initCmdParser(self):
		param_file = open('solver_default_config.txt')
		cmd_parser = argparse.ArgumentParser(description='create DAG with ASP code')
		# init parser with available arguments/default values 
		for line in param_file:
			param, default_value = line.split()
			cmd_parser.add_argument('--'+param, default=default_value, required=False)
		param_file.close()

		# add optional flags
		for flag in ClingoRunner.BOOLEAN_FLAGS:
			cmd_parser.add_argument('--' + flag, action='store_true')
		return cmd_parser

	def writeSolverConfigFile(self, param_dict, filename='config_params.lp'):
		solver_file = open(filename, 'w')
		for (param, value) in param_dict.items():
			if param not in ClingoRunner.BOOLEAN_FLAGS:
				solver_file.write('#const ' + param + ' = ' + value +'.\n')

		# also write overflow constraints
		solver_file.write(':- _coeffOverflow.\n')
		solver_file.write(':- _degOverflow.\n')
		solver_file.close()

	def runSolver(self):
		# write the config file needed to run the program
		param_dict = vars(self.args)
		if param_dict.has_key('iterative'):
			generated = self.iterativeDeepeningGeneration(param_dict)
		else:
			generated = self.computeAnsSets(param_dict)

		self.displayAnsSets(generated)

	def displayAnsSets(self, ans_sets):
		# display
		soln_parsers = []
		for prob in ans_sets:
			# for now taking only the first solution, hence subscript 1
			all_soln = eqn_viz.parseSolutions(prob['Value'])
			sample_soln = all_soln[1]
			print sample_soln.getSolutionString()
			print '-'*10 + '\n'
			soln_parsers.append(sample_soln)

		# create graph
		self.graph = Graph(soln_parsers)
		#print self.graph.getGraphEdges()
		#print self.graph.nodes.keys()

	def iterativeDeepeningGeneration(self, param_dict):
		output = []
		for num_steps in range(1, int(param_dict['maxSteps']) + 1):
			param_dict['maxSteps'] = str(num_steps)
			output += (self.computeAnsSets(param_dict))
		return output

	def computeAnsSets(self, param_dict):
		self.writeSolverConfigFile(param_dict)
		# run the process
		process = subprocess.Popen(ClingoRunner.BASH_COMMAND.split(), stdout=subprocess.PIPE)
		output = process.communicate()[0]
		return self.parseGeneratedProblems(output)

	def parseGeneratedProblems(self, json_output):
		return eqn_viz.getAllSolnFromJSON(json_output)



class Node(object):
	def __init__(self, soln_parser):
		super(Node, self).__init__()
		self.soln_parser = soln_parser
		self.label = self.makeLabel()
		self.actions = sorted(self.soln_parser.getActions()) # sort actions so they're in some canonical order
		self.n_gram_dict = {}
		self.initNGrams()
	def makeLabel(self):
		actions = sorted(self.soln_parser.getActions())
		return ':'.join(actions)
	def getProblem(self):
		return self.soln_parser.solution_steps[0].getEqnString()
	def getLabel(self):
		return self.label
	def getSolution(self):
		return self.soln_parser.getSolutionString()
	def initNGrams(self, num=2):
		for n_gram in range(1,num+1):
			current_n_gram_list = []
			for start_idx in range(0, len(self.actions)):
				stop_idx = start_idx+n_gram
				new_ngram = ''.join(self.actions[start_idx:stop_idx])
				current_n_gram_list.append(new_ngram)
			self.n_gram_dict[n_gram] = current_n_gram_list

class Graph(object):
	def __init__(self, all_solns):
		super(Graph, self).__init__()
		self.all_solns	= all_solns
		self.nodes		= {}
		self.edges		= []
		for soln in all_solns:
			self.addNodeFromSoln(soln)
		# now form the edges of the graph
		self.formGraphEdges()
		
		# add pygraphviz object for images
		self.visual_graph = pgv.AGraph()
		self.initVisualGraph()

	def addNodeFromSoln(self, soln_parser):
		new_node = Node(soln_parser)
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

		

		
# TODO: must have a unique name (based on 1-gram)
# TODO: unnecessary remove later
class DAGSolnParser(eqn_viz.SolnParser):
	"""parses an entire solution and contains aux information to form rule DAG"""
	def __init__(self):
		super(DAGSolnParser, self).__init__()
		
if __name__ == "__main__":
	ClingoRunner().runSolver()
