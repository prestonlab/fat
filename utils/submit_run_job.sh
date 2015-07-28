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
    echo "submit_run_job.sh   Submits a job to process multiple runs."
    echo
    echo "Usage: submit_run_job.sh [-jqcrep] commands runids"
    echo "See launch for explanation of options."
    echo
    echo "In the commands string, any '{}' will be replaced with"
    echo "run identifier. Can also use for replacing other simple"
    echo "variables in a command, such as COPE number."
    echo
    echo "Example (export commands can be placed in your .bashrc):"
    echo "export STUDY=bender"
    echo 'submit_run_job.sh -r 01:00:00 "run_level3.sh loc_cond {}" "1 2 3 4"'
    exit 1
fi

#echo "project=$projname queue=$queue compiler=$compiler parenv=$parenv runtime=$runtime ncores=$ncores"

runids="$2"

jobfile=`get_auto_jobfile.sh`
command="$1"

echo "Creating file: $jobfile"
for runid in $runids; do
    run_command=`echo $command | sed s/{}/$runid/g`
    echo $run_command >> $jobfile
    echo "$run_command"
done

chmod +x $jobfile

cd `dirname $jobfile`
file=`basename $jobfile`
name=`echo $file | cut -d . -f 1`
launch -s $file -j $projname -q $queue -c $compiler -n $name \
       -e $parenv -r $runtime -p $ncores

