#!/bin/bash

if [ $# -lt 1 ]; then
    echo "run_subjs.sh   Run a command on multiple subjects."
    echo
    echo "Usage: run_subjs.sh commands [subjects]"
    echo
    echo "In the commands string, any '{}' will be replaced with"
    echo "subject identifier. Takes subject numbers (e.g. 1, 2)"
    echo "and constructs them in the format [study]_DD, e.g. bender_01."
    echo "If the environment variable SUBJNOS is set, that will"
    echo "be used to set the subjects list."
    exit 1
fi

verbose=1
while getopts ":q" opt; do
    case $opt in
	q)
	    verbose=0
	    ;;
    esac
done
shift $((OPTIND-1))    

command="$1"

ids=1
if [ $# -lt 2 ]; then
    if [ ! -z ${SUBJIDS+x} ]; then
	ids=0
	nos="$SUBJIDS"
    else
	nos="$SUBJNOS"
    fi
else
    nos="$2"
fi

if [ -z "$nos" ]; then
    echo "Error: must indicate subject numbers to include."
    exit 1
fi

nos=`echo $nos | sed "s/:/ /g"`
for no in $nos; do
    if [ $ids == 0 ]; then
	subject=$no
    else
	subject=${STUDY}_`printf "%02d" $no`
    fi
    subj_command=`echo $command | sed s/{}/$subject/g`
    if [ $verbose -eq 1 ]; then
	echo "$subj_command"
    fi
    eval $subj_command
done

