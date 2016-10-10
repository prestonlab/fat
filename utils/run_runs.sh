#!/bin/bash

if [ $# -lt 1 ]; then
    echo "run_runs.sh   Run a command on multiple subjects and runs."
    echo
    echo "Usage: run_runs.sh commands [subjects] [runs]"
    echo
    echo "In the commands string, any '{s}' will be replaced with"
    echo "subject identifier. Takes subject numbers (e.g. 1, 2)"
    echo "and constructs them in the format [study]_DD, e.g. bender_01."
    echo "If the environment variable SUBJNOS is set, that will"
    echo "be used to set the subjects list. Any '{r}' will be replaced"
    echo "with run identifier."
    exit 1
fi

verbose=1
ids=0
while getopts ":qi" opt; do
    case $opt in
	q)
	    verbose=0
	    ;;
	i)
	    ids=1
	    ;;
    esac
done
shift $((OPTIND-1))    

command="$1"
shift 1

if [ $# -lt 2 ]; then
    nos=1
else
    nos="$2"
fi

if [ -z "$nos" ]; then
    echo "Error: must indicate subject numbers to include."
    exit 1
fi

nos=`echo $nos | sed "s/:/ /g"`
runs=`echo $1 | sed "s/:/ /g"`
for no in $nos; do
    if [ $ids == 1 ]; then
	subject=$no
    else
	subject=${STUDY}_`printf "%02d" $no`
    fi
    subj_command=`echo $command | sed s/{s}/$subject/g`
    for run in $runs; do
	run_command=`echo $subj_command | sed s/{r}/$run/g`
	if [ $verbose -eq 1 ]; then
	    echo "$run_command"
	fi
	eval $run_command
    done
done
