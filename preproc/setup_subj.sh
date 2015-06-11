#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: setup_subj.sh subjectID [options]"
    echo "May include any additional options for setup_subject.py."
    echo "Uses environment variables:"
    echo "  STUDY    study name"
    echo "  DATADIR  main data directory for all experiments"
    echo "  BATCHDIR directory where batch scripts are stored"
    exit 1
fi

SUBJID=$1

FSDIR=${STUDYDIR}/${SUBJID}/anatomy
MRICRONDIR=/corral-repl/utexas/prestonlab/software/
command="setup_subject.py -o --dcm2nii --motcorr --qa --betfunc --fm --keepdata --bet-inplane --studyname $STUDY -b $DATADIR -s $SUBJID --mricrondir $MRICRONDIR $2"

name=setup_$SUBJID
file=${name}.sh
prep_job.sh "$command" $file

cd $BATCHDIR
launch -s $file -r 14:00:00 -c gcc -n $name -e 1way -j ANTS -q normal
