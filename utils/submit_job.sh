#!/bin/bash

projname=ANTS
queue=normal
compiler=gcc
parenv=1way
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
    echo "Usage: submit_job.sh [-jqcr] commands"
    echo "See launch for explanation of options."
    exit 1
fi

jobfile=`get_auto_jobfile.sh`
prep_job.sh "$1" $jobfile

cd `dirname $jobfile`
file=`basename $jobfile`
name=`echo $file | cut -d . -f 1`
launch -s $file -j $projname -q $queue -c $compiler -n $name \
       -e $parenv -r $runtime -p $ncores
