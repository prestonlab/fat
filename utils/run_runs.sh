#!/bin/bash

if [ $# -lt 1 ]; then
    echo "run_runs.sh   Run a command on multiple subjects and runs."
    echo
    echo "Usage: run_runs.sh [OPTION] commands runs [subjects]"
    echo
    echo "Options:"
    echo "-q"
    echo "       do not print commands before executing"
    echo
    echo "-i"
    echo "       subject inputs are IDs (e.g. bender_01) instead of"
    echo "       numbers (e.g. 1). If subjects not specified, the"
    echo "       SUBJIDS environment variable will be used instead"
    echo "       of SUBJNOS."
    echo
    echo "'-n'"
    echo "       do not execute commands"
    echo
    echo "-p"
    echo "       run commands in parallel (run as background processes)"
    echo
    echo "Like run_subjs.sh, but any '{r}' will be replaced"
    echo "with run identifier. If subjects are specified (optional),"
    echo "{s} will be replaced with the subject ID."
    exit 1
fi

verbose=1
ids=0
noexec=0
runpar=0
runifexist=false
runifmissing=false
while getopts ":qinpf:m:" opt; do
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
	f)
	    runifexist=true
	    file="$OPTARG"
	    ;;
	m)
	    runifmissing=true
	    file="$OPTARG"
	    ;;
    esac
done
shift $((OPTIND-1))    

command="$1"
shift 1

runs=`echo $1 | sed "s/:/ /g"`

if [ $# -lt 2 ]; then
    nos=""
else
    nos="$2"
fi

if [ -z "$nos" ]; then
    for run in $runs; do
	run_command=`echo $command | sed s/{r}/$run/g | sed s/{}/$run/g`
	if [ $runifexist = true -o $runifmissing = true ]; then
	    run_file=$(echo "$file" | sed s/{r}/$run/g | sed s/{}/$run/g)
	    if [ $runifexist = true -a ! -f "$run_file" ]; then
		continue
	    elif [ $runifmissing = true -a -f "$run_file" ]; then
		continue
	    fi
	fi
	
	if [ $verbose -eq 1 ]; then
	    echo "$run_command"
	fi
	if [ $noexec -ne 1 ]; then
	    if [ $runpar -eq 1 ]; then
		$run_command &
	    else
		$run_command
	    fi
	fi
    done
else
    nos=`echo $nos | sed "s/:/ /g"`
    for no in $nos; do
	if [ $ids -eq 1 ]; then
	    subject=$no
	else
	    subject=${STUDY}_`printf "%02d" $no`
	fi
	subj_command=`echo $command | sed s/{s}/$subject/g`
	for run in $runs; do
	    run_command=`echo $subj_command | sed s/{r}/$run/g`
	    if [ $runifexist = true -o $runifmissing = true ]; then
		run_file=$(echo "$file" | sed s/{s}/$subject/g | sed s/{r}/$run/g)
		if [ $runifexist = true -a ! -f "$run_file" ]; then
		    continue
		elif [ $runifmissing = true -a -f "$run_file" ]; then
		    continue
		fi
	    fi
	    
	    if [ $verbose -eq 1 ]; then
		echo "$run_command"
	    fi
	    if [ $noexec -ne 1 ]; then
		if [ $runpar -eq 1 ]; then
		    $run_command &
		else
		    $run_command
		fi
	    fi
	done
    done
fi
