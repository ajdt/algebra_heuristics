#!/bin/bash
#substitutions=("s/monoMult,/canBeMultipliedTogether,/g" "s/monoMult)/canBeMultipliedTogether)/g")

#orig_names=("fracCancel" "factor" "addSameFrac" "distribute" "divByOne" "addZero" "factorMonom" "factorCommTerm" "multByZero" "multIdentity" "multNumerAndDenom" "addMonoToEqn" "cancelNegatives" "percolateNeg" "ungroup" "cancelSumTerm" "addInverses" "subtractFromEqn" "mulEqn" "divEqnByConst" "addEqn" "mulWithFrac")

#new_names=("canHaveTheirCommonFactorCancelled" "canBeFactored" "canBeAddedAsOneFraction" "canBeDistributed" "canHaveItsDenominatorCancelled" "canBeCancelled" "isATermThatCanBeFactored" "hasATermThatCanBeFactoredOut" "isEqualToZero" "canBeIgnored" "numeratorAndDenominatorCanBeMultipliedBySameTerm" "canHaveTheSameTermAddedToBothSides" "areBothNegativeOperationsThatCancelOut" "negationCanBeDistributed" "canBeUngrouped" "areTermsThatCanBeCancelled" "addUpToZero" "canBeSubtractedFromTheEquation" "canBeMultipliedAcrossBothSidesOfTheEquation" "canDivideBothSidesOfTheEquation" "canBeAddedToBothSidesOfTheEquation" "fractionCanBeMultipliedWithNonFraction")
#
#orig_names=("equalDegs" "degOf" "coeffOf")
#new_names=("haveEqualDegrees" "isTheDegreeOf" "isTheCoefficientOf")
orig_names=("combine")
new_names=("blah")
arLen=${#new_names[@]}
#for (( i=0; i<${arLen}; i++ )); do

## for replacing predicate names
#for (( i=0; i<${arLen}; i++ )); do
    #sed -i delete_this "s/${orig_names[$i]}(/${new_names[$i]}(/g" *.lp
#done

# for replacing constants inside of predicates
for (( i=0; i<${arLen}; i++ )); do
    sed -i delete_this "s/${orig_names[$i]},/${new_names[$i]},/g" *.lp
    sed -i delete_this "s/${orig_names[$i]})/${new_names[$i]})/g" *.lp
    # replace rule names in yaml testing file too
    sed -i delete_this "s/${orig_names[$i]}:/${new_names[$i]}:/g" *.yaml
    sed -i delete_this "s/${orig_names[$i]})/${new_names[$i]})/g" *.yaml
done

# remove all temp files generated in search/replace
rm *delete_this
