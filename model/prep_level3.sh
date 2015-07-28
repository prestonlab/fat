#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Prepare level 3 analysis from an FSL template"
    echo
    echo "Usage:"
    echo "`basename $0` template model ncopes"
    echo
    echo "Inputs:"
    echo "template   path to FSF template"
    echo "model      name of statistical model"
    echo "ncopes     number of copes to process"
    echo
    echo "Level 2 Template variables:"
    echo "STUDYDIR   path to directory with study data"
    echo "COPEID     full name of cope, e.g. cope1"
    echo
    echo "Environment variables used:"
    echo "STUDYDIR   path to directory with subject directories"
    echo
    exit 1
fi

template=$1
model=$2
ncopes=$3

modeldir=${STUDYDIR}/batch/glm/${model}
fsfdir=${modeldir}/fsf
mkdir -p ${fsfdir}

# copy template to standard file
fsftemplate=${modeldir}/${model}_level3.fsf
cp ${template} ${fsftemplate}

copes=`seq $ncopes`
for cope_no in ${copes}; do
    copeid=cope${cope_no}
    customfsf=${fsfdir}/${model}_${copeid}.fsf

    # create the customized file
    sed -e "s|STUDYDIR|${STUDYDIR}|g" \
	-e "s|COPEID|${copeid}|g" \
	<${fsftemplate} >${customfsf}
done
