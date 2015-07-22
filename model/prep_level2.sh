#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Prepare level 2 analysis from an FSL template"
    echo
    echo "Usage:"
    echo "`basename $0` [template] [model]"
    echo
    echo "Inputs:"
    echo "template   path to FSF template"
    echo "model      name of statistical model"
    echo
    echo "Level 2 Template variables:"
    echo "STUDYDIR   path to directory with study data"
    echo "SUBJID     full subject identifier, e.g. prex_01"
    echo
    echo "Environment variables used:"
    echo "STUDYDIR   path to directory with subject directories"
    echo "SUBJIDS    list of subject identifiers"
    echo
    exit 1
fi

template=$1
model=$2

modeldir=${STUDYDIR}/batch/glm/${model}
fsfdir=${modeldir}/fsf
mkdir -p ${fsfdir}

# copy template to standard file
fsftemplate=${modeldir}/${model}_level2.fsf
cp ${template} ${fsftemplate}

for subjid in ${SUBJIDS}; do
    customfsf=${fsfdir}/${model}_${subjid}.fsf

    # create the customized file
    sed -e "s|STUDYDIR|${STUDYDIR}|g" \
	-e "s|SUBJID|${subjid}|g" \
	<${fsftemplate} >${customfsf}
done
