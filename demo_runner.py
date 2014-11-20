from dag_gen import *
class DemoRunner(ClingoRunner):
	"""Runs clingo for demos"""
	def __init__(self):
		ClingoRunner.__init__(self)
	def runSolver(self):
		print 'It works, yay!'


if __name__ == "__main__":
	DemoRunner().runSolver()
		
