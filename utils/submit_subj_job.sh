#!/bin/bash

projname=ANTS
queue=normal
compiler=gcc
parenv=12way
ncores=12

OPTIND=1
while getopts ":j:q:c:r:e:p:" opt; do
    case "$opt" in
	j)  projname=$OPTARG
	    ;;
	q)  queue=$OPTARG
	    ;;
	c)  compiler=$OPTARG
	    ;;
	r)  runtime=$OPTARG
	    ;;
	e)  parenv=$OPTARG
	    ;;
	p)  ncores=$OPTARG
	    ;;
    esac
done

shift $((OPTIND-1))

if [ $# -lt 1 ]; then
    echo "submit_subj_job.sh   Submits jobs for multiple subjects."
    echo
    echo "Usage: submit_subj_job.sh [-jqcrep] commands [subjects]"
    echo "See launch for explanation of options."
    echo
    echo "In the commands string, any '{}' will be replaced with"
    echo "subject identifier. Takes subject numbers (e.g. 1, 2)"
    echo "and constructs them in the format [study]_DD, e.g. bender_01."
    echo "If the environment variable SUBJNOS is set, that will"
    echo "be used to set the subjects list."
    echo
    echo "Example (export commands can be placed in your .bashrc):"
    echo "export STUDY=bender"
    echo 'export SUBJNOS=`seq 1 6`'
    echo 'submit_subj_job.sh -r 01:00:00 "convert_dicom.py {}"'
    exit 1
fi

if [ $# -lt 2 ]; then
    nos="$SUBJNOS"
else
    nos="$2"
fi

if [ -z "$nos" ]; then
    echo "Error: must indicate subject numbers to include."
    exit 1
fi

jobfile=`get_auto_jobfile.sh`
command="$1"
for no in $nos; do
    subject=${STUDY}_`printf "%02d" $no`
    subj_command=`echo $command | sed s/{}/$subject/g`
    echo $subj_command >> $jobfile
    echo "$subj_command"
done
chmod +x $jobfile

cd `dirname $jobfile`
file=`basename $jobfile`
name=`echo $file | cut -d . -f 1`
launch -s $file -j $projname -q $queue -c $compiler -n $name \
       -e $parenv -r $runtime -p $ncores

