from dag_gen import *
import eqn_viz
class DemoRunner:
	"""Run clingo based on command line arguments"""
	BASE_COMMAND = "clingo eqn_generator.lp --outf=2"
	misc_params = { 'heurSeq' :  '', 'numSets': '1' , 'clingo' : '', 'random' : 'false', 'featuresFile' : 'None'}
	def __init__(self):
		self.cmd_parser	=	self.initCmdParser()
		self.args		=	self.cmd_parser.parse_args()
		self.cmd_line_args = []

	def initCmdParser(self):
		param_file = open('solver_default_config.txt')
		cmd_parser = argparse.ArgumentParser(description='create DAG with ASP code')
		# init parser with available arguments/default values 
		for line in param_file:
			param, default_value = line.split()
			cmd_parser.add_argument('--'+param, default=default_value, required=False)

		# add params relevant to problem generation too
		for param, default_value in DemoRunner.misc_params.items():
			cmd_parser.add_argument('--'+param, default=default_value, required=False)
		param_file.close()
		return cmd_parser

	def getHeuristicSequence(self, param_dict):
		if param_dict['heurSeq'] == '':
			return ''
		heuristics = param_dict['heurSeq']
		heur_list = []
		for step, heur in enumerate(heuristics.split(' ')):
			time_step = '_time(' + str(step) + ',1)'
			heur_list.append(':- not selectedHeuristic(' + time_step + ', ' + heur + ').')
		return '\n'.join(heur_list) + '\n'

	def getRequiredFeatures(self, param_dict):
		if param_dict['featuresFile'] == 'None':
			return ''
		req_file = open(param_dict['featuresFile'], 'r')
		requirements_str = ''
		for line in req_file:
			rule, feature, value = line.split()
			requirements_str += ':- not ruleFeature('+rule+',' + feature +',' + value +').'
		return requirements_str


	def writeSolverConfigFile(self, param_dict, filename='config_params.lp'):
		solver_file = open(filename, 'w')
		other_args = DemoRunner.misc_params.keys()
		for (param, value) in param_dict.items():
			if param not in other_args:
				solver_file.write('#const ' + param + ' = ' + value +'.\n')
		# write any sequence of arguments

		# also write overflow constraints
		solver_file.write(':- _coeffOverflow.\n')
		solver_file.write(':- _degOverflow.\n')
		solver_file.write(self.getHeuristicSequence(param_dict))
		solver_file.write(self.getRequiredFeatures(param_dict))

		solver_file.close()

	def getClingoFlags(self, param_dict):
		flags = ''
		if param_dict.has_key('numSets'):
			flags += '-n ' + param_dict['numSets']
		if param_dict.has_key('clingo'):
			flags +=  ' ' + param_dict['clingo']
		if param_dict.has_key('random') and param_dict['random'] == 'true':
			flags +=  ' --sign-def=3 '
		return flags
	def runSolver(self):
		# write the config file needed to run the program
		param_dict = vars(self.args)
		self.writeSolverConfigFile(param_dict)
		# create the run command
		cmd_string = DemoRunner.BASE_COMMAND + ' ' + self.getClingoFlags(param_dict)
		# run the process
		#print 'running command:' + cmd_string
		process = subprocess.Popen(cmd_string.split(), stdout=subprocess.PIPE)
		output = process.communicate()[0]
		self.parseGeneratedProblems(output)
		#print 'done :) '
	def parseGeneratedProblems(self, json_output):
		problems = eqn_viz.getAllSolnFromJSON(json_output)
		soln_parsers = []
		for prob in problems:
			# for now taking only the first solution, hence subscript 1
			all_soln = eqn_viz.parseSolutions(prob['Value'])
			sample_soln = all_soln[1]
			print sample_soln.getSolutionString()
			print '-'*10 + '\n'
			soln_parsers.append(sample_soln)
		#self.graph = Graph(soln_parsers)
		#print self.graph.getGraphEdges()
		#print self.graph.nodes.keys()
		# quick test to see that nodes are generated correctly
		#for node_label in self.graph.nodes.keys():
			#print node_label


if __name__ == "__main__":
	DemoRunner().runSolver()
		
