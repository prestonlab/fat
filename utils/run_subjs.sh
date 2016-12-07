#!/bin/bash

if [ $# -lt 1 ]; then
    echo "run_subjs.sh   Run a command on multiple subjects."
    echo
    echo "Usage: run_subjs.sh [OPTION] commands [SUBJNOS]"
    echo
    echo "Options:"
    echo "-q"
    echo "       do not print commands before executing"
    echo
    echo "-i"
    echo "       use the SUBJIDS environment variable"
    echo "       (a colon-separated list of full"
    echo "       subject identifiers like mystudy_001) instead of"
    echo "       SUBJNOS (just subject numbers like 1)"
    echo
    echo "In the commands string, any '{}' will be replaced with"
    echo "subject identifier. Takes subject numbers (e.g. 1, 2)"
    echo "and constructs them in the format \$STUDY_DD, e.g. mystudy_01."
    echo "If subject numbers aren't specified, but the environment"
    echo "variable SUBJNOS is set, that will be used to set the"
    echo "subjects list."
    echo
    echo "Does the same thing as a for loop over subjects, but saves"
    echo "some typing and makes it easy to specify which subset of"
    echo "subjects to run. Assumes that subjects have two zero-padded"
    echo "digits in their identifier. If not, can set the SUBJIDS"
    echo "environment variable and use the -i option."
    echo
    echo "Example"
    echo "To print the ID for the first four subjects in a study"
    echo "called mystudy:"
    echo "export STUDY=mystudy # only have to run this once"
    echo "run_subjs.sh 'echo {}' 1:2:3:4"
    echo
    exit 1
fi

verbose=1
ids=0
noexec=0
runpar=0
while getopts ":qinp" opt; do
    case $opt in
	q)
	    verbose=0
	    ;;
	i)
	    ids=1
	    ;;
	n)
	    noexec=1
	    ;;
	p)
	    runpar=1
	    ;;
    esac
done
shift $((OPTIND-1))    

command="$1"
shift 1

if [ $# -lt 1 ]; then
    if [ $ids == 1 ]; then
	nos="$SUBJIDS"
    else
	nos="$SUBJNOS"
    fi
else
    nos="$@"
fi

if [ -z "$nos" ]; then
    echo "Error: must indicate subject numbers to include."
    exit 1
fi

nos=$(echo $nos | sed "s/:/ /g")
for no in $nos; do
    if [ $ids == 1 ]; then
	subject=$no
    else
	subject=${STUDY}_$(printf "%02d" $no)
    fi
    subj_command=$(echo $command | sed s/{}/$subject/g)
    if [ $verbose -eq 1 ]; then
	echo "$subj_command"
    fi
    if [ $noexec -ne 1 ]; then
	if [ $runpar -eq 1 ]; then
	    $subj_command &
	else
	    $subj_command
	fi
    fi
done
