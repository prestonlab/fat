#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Prepare level 1 analysis from an FSL template"
    echo
    echo "Usage:"
    echo "`basename $0` [template] [studydir] [model] [subjids] [runids]"
    echo
    echo "Inputs:"
    echo "studydir   path to base study directory"
    echo "model     name of statistical model"
    echo "subjids   list of subject IDs"
    echo "runids    list of run IDs"
    echo
    echo "Level 1 Template variables:"
    echo "STUDYDIR   path to directory with study data"
    echo "SUBJID     full subject identifier, e.g. prex_01"
    echo "RUNID      full identifier for each run, e.g. pre_1"
    echo
    exit 1
fi

template=$1
studydir=$2
model=$3
subjids="$4"
runids="$5"

# study-level directory for automatically generated scripts and
# later higher-level analysis
glmdir=${studydir}/batch/glm
modeldir=${glmdir}/${model}
fsfdir=${modeldir}/fsf
mkdir -p ${fsfdir}

fsftemplate=${modeldir}/${model}_level1.fsf
cp ${template} ${fsftemplate}

for subjid in ${subjids}; do
    for runid in ${runids}; do
	# path to customized FSF file
	customfsf=${fsfdir}/${model}_${subjid}_${runid}.fsf

	# use sed to create the customized file
	sed -e "s|STUDYDIR|${studydir}|g" \
	    -e "s|SUBJID|${subjid}|g" \
	    -e "s|RUNID|${runid}|g" \
	    <${fsftemplate} >${customfsf}
    done
done

