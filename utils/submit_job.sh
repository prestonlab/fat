#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: submit_job.sh commands [launch options]"
    echo "See launch for explanation of options."
    exit 1
fi

commands="$1"
shift

jobfile=`get_auto_jobfile.sh`
prep_job.sh "$commands" $jobfile

file=`basename $jobfile`
name=`echo $file | cut -d . -f 1`
outfile=$BATCHDIR/${name}.out
batchfile=$BATCHDIR/${name}.slurm
launch -s $jobfile -J $name -o $outfile -f $batchfile -k -N 1 -n 1 "$@"
