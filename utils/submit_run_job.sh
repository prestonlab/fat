#!/bin/bash

if [ $# -lt 1 ]; then
    echo "submit_run_job.sh   Submits a job to process multiple runs."
    echo
    echo "Usage: submit_run_job.sh [-xy] commands runids [launch options]"
    echo "Run launch -h for explanation of launch options."
    echo
    echo "In the commands string, any '{}' will be replaced with"
    echo "run identifier. Can also use for replacing other"
    echo "variables in a command, such as COPE number. Run IDs"
    echo "must be a list separated by colons."
    echo
    echo "Example:"
    echo 'submit_run_job.sh "run_level3.sh loc_cond {}" 1:2:3:4 [launch options]'
    echo "to run run_level3.sh loc_cond 1, run_level3.sh loc_cond 2, ..."
    echo
    echo "May also run all combinations of runs and subjects using the"
    echo "-x or -y flag. If using those options, in the command string,"
    echo "any {s} will be replaced with the subject ID. Any {r} will be"
    echo "replaced with the run ID."
    echo
    echo "-x"
    echo "    colon-separated list of subject numbers. Full subject IDs"
    echo "    will be created as STUDY_DD, where STUDY is an environment"
    echo "    variable, and DD is the number zero-padded to two digits."
    echo "-y"
    echo "    colon-separated list of full subject IDs."
    echo
    echo "Example:"
    echo "export STUDY=bender"
    echo "export LOCRUNS=loc_1:loc_2:loc_3:loc_4"
    echo 'submit_run_job.sh -x 1:2:3 "run_level1.sh loc_cond {s} {r}" $LOCRUNS [launch options]'
    echo "will run run_level1.sh for all localizer runs for bender_01,"
    echo "bender_02, and bender_03."
    echo
    echo "See also run_runs.sh for a version that runs locally."
    echo
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

outfile=$BATCHDIR/${name}.out
batchfile=$BATCHDIR/${name}.slurm

launch -s $jobfile -J $name -o $outfile -f $batchfile -k "$@"
