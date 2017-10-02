#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: submit_job.sh [-x] [-s script] [commands] [launch options]"
    echo
    echo "Use either -s script to indicate a file with commands to run,"
    echo "where different lines should be run in parallel, or specify"
    echo "commands to run."
    echo
    echo "-s script"
    echo "    Run commands in $script. Commands on different lines will"
    echo "    be run in parallel."
    echo
    echo "-x"
    echo "    Run remora on the command (only works with one command)"
    echo "    to monitor resource usage (e.g. memory) periodically."
    echo "    Results will be saved in $BATCHDIR/JobXXX.remora."
    echo
    echo "Run launch -h for explanation of other options."
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
    echo "Examples:"
    echo "# Submit a job to display hello world:"
    echo "submit_job.sh 'echo \"hello world\"' -N 1 -n 1 -r 00:01:00 -p development"
    echo
    echo "# Display hello world twice, executing in parallel on different"
    echo "# cores of one node:"
    echo "echo 'echo \"hello world 1\"' > myscript.sh"
    echo "echo 'echo \"hello world 2\"' >> myscript.sh"
    echo 'submit_job.sh -s myscript.sh -N 1 -n 2 -r 00:01:00 -p development'
    echo
    exit 1
fi

if [ -z $BATCHDIR ]; then
    echo "Error: Must define BATCHDIR to indicate directory to save jobs in."
    exit 1
fi

script=""
remora=false
script_arg=0
remora_arg=0
while getopts ":s:x" opt; do
    case $opt in
        s)
            script=$OPTARG
	    script_arg=2
            ;;
	x)
	    remora=true
	    remora_arg=1
	    ;;
    esac
done

# -s and -x may also occur in launch options, so account manually
shift $((script_arg + remora_arg))

# get the next job file name that doesn't exist yet
jobfile=$(get_auto_jobfile.sh)

if [ -n "$script" ]; then
    # script with one or more commands
    cp $script $jobfile
    chmod +x $jobfile
else
    # command string input; make a script
    commands="$1"
    shift
    prep_job.sh "$commands" $jobfile
fi

file=$(basename $jobfile)
name=$(echo $file | cut -d . -f 1)
outfile=$BATCHDIR/${name}.out
batchfile=$BATCHDIR/${name}.slurm

args=""
if [ $remora = true ]; then
    args="${args} -x $BATCHDIR/${name}.remora"
fi

launch -s $jobfile -J $name -o $outfile -f $batchfile -k$args "$@"
