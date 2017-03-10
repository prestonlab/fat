#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: submit_job.sh commands [launch options]"
    echo "Run launch -h for explanation of options."
    echo
    echo "Must define environment variable BATCHDIR. For example:"
    echo "export BATCHDIR=$WORK/batch"
    echo
    echo "Jobs will be saved in BATCHDIR under Job1, Job2, etc."
    echo "The command is placed in JobXXX.sh, output in JobXXX.out,"
    echo "and slurm commands in JobXXX.slurm."
    echo
    echo "After submission, running_jobs.sh will show commands for"
    echo "all jobs."
    echo
    echo "To look up how you ran a job to run some command before,"
    echo 'run grep -l [command] $BATCHDIR/*.sh to find the job number.'
    echo 'Then look at ${job}.out for duration, number of nodes, etc.'
    echo
    exit 1
fi

if [ -z $BATCHDIR ]; then
    echo "Error: Must define BATCHDIR to indicate directory to save jobs in."
    exit 1
fi

commands="$1"
shift

jobfile=$(get_auto_jobfile.sh)
prep_job.sh "$commands" $jobfile

file=$(basename $jobfile)
name=$(echo $file | cut -d . -f 1)
outfile=$BATCHDIR/${name}.out
batchfile=$BATCHDIR/${name}.slurm
launch -s $jobfile -J $name -o $outfile -f $batchfile -k -N 1 -n 1 "$@"
