#!/bin/bash

if [ $# -lt 1 ]; then
    echo "submit_run_job.sh   Submits a job to process multiple runs."
    echo
    echo "Usage: submit_run_job.sh commands runids [options]"
    echo "See launch for explanation of options."
    echo
    echo "In the commands string, any '{}' will be replaced with"
    echo "run identifier. Can also use for replacing other simple"
    echo "variables in a command, such as COPE number. Run IDs"
    echo "must be a list separated by colons."
    echo
    echo "May include multiple commands to run in parallel for each"
    echo "run by separating commands with a colon; each of the"
    echo "commands will be run in parallel."
    echo
    echo "Example:"
    echo 'submit_run_job.sh "run_level3.sh loc_cond {}" 1:2:3:4 -r 01:00:00'
    exit 1
fi

subjids=""
ids=0
while getopts ":x:y:" opt; do
    case $opt in
	x)
	    subjids=$(subjids $OPTARG)
	    ;;
	y)
	    subjids=$opt
	    ;;
    esac
done
shift $((OPTIND-1))

command="$1"
runids="$2"
shift 2

jobfile=$(get_auto_jobfile.sh)
if [ -z "$subjids" ]; then
    run_runs.sh -ni "$command" "$runids" > $jobfile
else
    run_runs.sh -ni "$command" "$runids" "$subjids" > $jobfile
fi

cat $jobfile
chmod +x $jobfile

file=$(basename $jobfile)
name=$(echo $file | cut -d . -f 1)

outfile=$BATCHDIR/${name}.o%j
batchfile=$BATCHDIR/${name}.slurm

launch -s $jobfile -J $name -o $outfile -f $batchfile -k "$@"
