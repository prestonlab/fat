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

command="$1"
runids="$2"
shift 2

runs=$(echo $runids | sed "s/:/ /g")
jobfile=$(get_auto_jobfile.sh)

echo "Creating file: $jobfile"
for runid in $runs; do
    run_command=$(echo $command | sed s/{}/$runid/g | tr ':' '\n')
    echo $run_command >> $jobfile
    echo "$run_command"
done

chmod +x $jobfile

cd $(dirname $jobfile)
file=$(basename $jobfile)
name=$(echo $file | cut -d . -f 1)

launch -s $jobfile -J $name "$@"
