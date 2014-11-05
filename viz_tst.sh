# missing addDiffFrac 
RULENAMES=(addMonoToEqn addMonom addSameFrac addZero distribute divByOne divIdent factor factorCommTerm factorMonom fracCancel fracDiv monoMult multByZero multEqnWithMono multFrac multIdentity multNumerAndDenom numerSimp swapTerms)
RESULTFILE=results.txt

rm -f $RESULTFILE
for RULE in ${RULENAMES[@]} ; do
	echo $RULE >> $RESULTFILE
	echo ":- not _ruleForTimeStep(_time(0,1), $RULE )." > extra_cond.lp
	clingo eqn_generator.lp extra_cond.lp --outf=2 | python eqn_viz.py >> $RESULTFILE
done
rm -f extra_cond.lp
echo "finished :)"

