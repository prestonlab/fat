#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: submit_level1.sh [model] [run_ids] [launch arguments]"
    echo "Example: submit_level1.sh loc_cond 'loc_1 loc_2 loc_3 loc_4' -r 10:00:00 -e 4way -p 12"
    echo "This will create a job for each subject, to run "
    echo "level 1 Feat on each run."
    echo
    exit 1
fi

model=$1
run_ids=$2
shift 2
submit_opt="$@"

for subj in $SUBJIDS; do
    command="run_level1.sh $model $subj {}"
    submit_run_job.sh $submit_opt "$command" "$run_ids"
done
