#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Prepare level 2 analysis from an FSL template"
    echo
    echo "Usage:"
    echo "`basename $0` [-ds] template model"
    echo
    echo "Optional inputs:"
    echo "-d"
    echo "      path to base study directory. If not specified,"
    echo "      STUDYDIR environment variable will be used."
    echo
    echo "-s"
    echo "      list of subject ids, separated by ':'. If not"
    echo "      specified, SUBJIDS environment variable will be used."
    echo
    echo "Required inputs:"
    echo "template   path to FSF template"
    echo "model      name of statistical model"
    echo
    echo "These strings will be replaced in the FSF template:"
    echo "STUDYDIR   path to directory with study data"
    echo "SUBJID     full subject identifier, e.g. prex_01"
    echo
    exit 1
fi

while getopts ":d:s:" opt; do
    case $opt in
	d)
	    STUDYDIR=$OPTARG
	    ;;
	s)
	    SUBJIDS=$OPTARG
	    ;;
    esac
done
shift $((OPTIND-1))

if [ -z $STUDYDIR ]; then
    echo "Error: Study directory undefined."
fi
if [ -z $SUBJIDS ]; then
    echo "Error: Subject identifiers undefined."
fi

template=$1
model=$2

modeldir=${STUDYDIR}/batch/glm/${model}
fsfdir=${modeldir}/fsf
mkdir -p ${fsfdir}

# copy template to standard file
fsftemplate=${modeldir}/${model}_level2.fsf
cp ${template} ${fsftemplate}

sids="`echo $SUBJIDS | sed "s/:/ /g"`"
for subjid in ${sids}; do
    customfsf=${fsfdir}/${model}_${subjid}.fsf

    # create the customized file
    sed -e "s|STUDYDIR|${STUDYDIR}|g" \
	-e "s|SUBJID|${subjid}|g" \
	<${fsftemplate} >${customfsf}
done
