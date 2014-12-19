from dag_gen import *
import eqn_viz
class DemoRunner(ClingoRunner):
	"""Run clingo based on command line arguments"""
	BASE_COMMAND = "clingo eqn_generator.lp --outf=2 "
	additional_params = { 'heurSeq' :  '', 'numSets': '1' , 'clingo' : '', 'random' : 'false', 'featuresFile' : 'None', 'json_output': 'true'}
	def __init__(self):
		self.cmd_line_args = []
		ClingoRunner.__init__(self, DemoRunner.BASE_COMMAND, flags=[], misc_params=DemoRunner.additional_params)

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
		heur_and_features = self.getHeuristicSequence(param_dict) + '\n' + self.getRequiredFeatures(param_dict)
		ClingoRunner.writeSolverConfigFile(self, param_dict, filename, misc_constraints=heur_and_features)

	def getClingoFlags(self, param_dict):
		flags = ''
		if param_dict.has_key('numSets'):
			flags += '-n ' + param_dict['numSets'] + ' '
		if param_dict.has_key('clingo'):
			flags +=   param_dict['clingo'] + ' '
		if param_dict.has_key('random') and param_dict['random'] == 'true':
			flags +=  ' --sign-def=3 '
		return flags

	def runSolver(self):
		# include additional bash commands
		param_dict = vars(self.args)
		self.bash_cmd += self.getClingoFlags(param_dict)
		ClingoRunner.runSolver(self, make_graph=False)

if __name__ == "__main__":
	DemoRunner().runSolver()
		
