#!/bin/bash

if [ $# -lt 1 ]; then
    cat <<EOF
run_subjs.sh   Run a command on multiple subjects.

Usage: run_subjs.sh [OPTION] commands [SUBJNOS]

Options:
-q
       do not print commands before executing

-i
       subject inputs are IDs (e.g. bender_01) instead of
       numbers (e.g. 1). If subjects not specified, the
       SUBJIDS environment variable will be used instead
       of SUBJNOS.

-n
       do not execute commands

-p nproc
       run commands in parallel (requires GNU parallel).
       Will run  commands at once until all are finished.

In the commands string, any '{}' will be replaced with
subject identifier. Takes subject numbers (e.g. 1, 2)
and constructs them in the format $STUDY_DD, e.g. mystudy_01.
If subject numbers aren't specified, but the environment
variable SUBJNOS is set, that will be used to set the
subjects list. Subject numbers in SUBJNOS should be colon-
separated, e.g. 1:2:3.

Does the same thing as a for loop over subjects, but saves
some typing and makes it easy to specify which subset of
subjects to run. Assumes that subjects have two zero-padded
digits in their identifier. If not, can set the SUBJIDS
environment variable and use the -i option.

Example
To print the ID for the first four subjects in a study
called mystudy:
export STUDY=mystudy # only have to run this once
run_subjs.sh 'echo {}' 1:2:3:4

Using the SUBJIDS environment variable:
export SUBJIDS=No_003:No_004:No_005
run_subjs.sh -i 'echo {}'

EOF
    exit 1
fi

verbose=1
ids=0
noexec=0
runpar=0
while getopts ":qinp:" opt; do
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
	    nproc=$OPTARG
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
subjects=""
for no in $nos; do
    # get subject id
    if [ $ids == 1 ]; then
	subject=$no
    else
	subject=$(subjids $no)
    fi

    # create command
    subj_command=$(echo $command | sed s/{}/$subject/g)
    if [ $verbose -eq 1 -a $runpar -ne 1 ]; then
	echo "$subj_command"
    fi

    # get list of subjects for use with parallel
    if [ $runpar -eq 1 ]; then
	if [ -z "$subjects" ]; then
	    subjects="$subject"
	else
	    subjects="$subjects $subject"
	fi
    fi

    # if running in serial, execute command
    if [ $noexec -ne 1 ]; then
	$subj_command
    fi
done

if [ $runpar -eq 1 ]; then
    # run collected commands using gnu parallel
    if [ $verbose -eq 1 ]; then
	echo "parallel -j $nproc $command ::: $subjects"
    fi
    if [ $noexec -ne 1 ]; then
	if hash parallel 2>/dev/null; then
	    parallel -q -j $nproc "$command" ::: $subjects
	else
	    echo "Error: Cannot find GNU parallel."
	    exit 1
	fi
    fi
fi
