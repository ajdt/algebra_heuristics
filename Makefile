PARAMS=eqn_params.lp 
GEN=eqn_generator.lp 
SOLVER=eqn_solver.lp
RULES=eqn_rules.lp
HELPER=eqn_helpers.lp
GRINGOFILES=$(PARAMS) $(GEN) $(SOLVER) $(RULES) $(HELPER)
VIZ=python eqn_viz.py

GROUNDFILE = grounding.log
PROFILE=profile.log



run:
	clingo  $(GEN) 
stats:
	clingo  $(GEN)  --stats
show:
	clingo  $(GEN) --outf=2 | $(VIZ)
ground:
	clingo $(GEN) --text  > $(GROUNDFILE)
prof: 
	cat $(GROUNDFILE) | cut -c 1-10 | sort | uniq -c | sort -nr > $(PROFILE)

