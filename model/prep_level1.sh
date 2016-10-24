#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Prepare level 1 analysis from an FSL template"
    echo
    echo "Usage:"
    echo "`basename $0` template model runids [subjids]"
    echo
    echo "Inputs:"
    echo "template   path to FSF template"
    echo "model      name of statistical model"
    echo "runids     list of run IDs (separated by :)"
    echo "subjids    list of subject IDs. If not specified,"
    echo "           SUBJIDS environment variable will be used."
    echo
    echo "Level 1 Template variables:"
    echo "STUDYDIR   path to directory with study data"
    echo "SUBJID     full subject identifier, e.g. prex_01"
    echo "RUNID      full identifier for each run, e.g. pre_1"
    echo
    echo "Environment variables used:"
    echo "STUDYDIR   path to directory with subject directories"
    echo "SUBJIDS    (optional) list of subject identifiers"
    echo
    exit 1
fi

template=$1
model=$2
runids="$3"
if [ $# -lt 4 ]; then
    if [ -u $SUBJIDS ]; then
	echo "ERROR: Must specify subject identifiers."
	exit 1
    fi
    sids="`echo $SUBJIDS | sed "s/:/ /g"`"
else
    sids="`echo $4 | sed "s/:/ /g"`"
fi

# study-level directory for automatically generated scripts and
# later higher-level analysis
glmdir=${STUDYDIR}/batch/glm
modeldir=${glmdir}/${model}
fsfdir=${modeldir}/fsf
mkdir -p ${fsfdir}

fsftemplate=${modeldir}/${model}_level1.fsf
cp ${template} ${fsftemplate}

rids="`echo $runids | sed "s/:/ /g"`"
for subjid in $sids; do
    for runid in $rids; do
	# path to customized FSF file
	customfsf=${fsfdir}/${model}_${subjid}_${runid}.fsf

	# use sed to create the customized file
	sed -e "s|STUDYDIR|${STUDYDIR}|g" \
	    -e "s|SUBJID|${subjid}|g" \
	    -e "s|RUNID|${runid}|g" \
	    <${fsftemplate} >${customfsf}
    done
done

