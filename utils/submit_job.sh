#!/bin/bash

if [ $# -lt 1 ]; then
    cat <<EOF
Usage: submit_job.sh [-x] [-J jobname] -s script [launch options]
Usage: submit_job.sh [-x] [-J jobname] commands [launch options]

Use either -s script to indicate a file with commands to run,
where different lines should be run in parallel, or specify
commands to run.

-x
    Run remora on the command (only works with one command)
    to monitor resource usage (e.g. memory) periodically.
    Results will be saved in \$BATCHDIR/JobXXX.remora.

-J
    Job name. Information about the job will be saved in
    \$BATCHDIR/\${jobname}XX.{sh,slurm,out}, where XX is a
    serial number. Default is 'Job'.

-s script
    Run commands in \$script. Commands on different lines will
    be run in parallel. If this option is used, it must come
    last before any launch options.

Run launch -h for explanation of other options.

Must define environment variable BATCHDIR. For example:
export BATCHDIR=\$WORK/batch

After submission, running_jobs.sh will show commands for
all jobs.

To look up how you ran a job to run some command before,
run grep -l [command] \$BATCHDIR/*.sh to find the job name.
Then look at \${job}.out for duration, number of nodes, etc.

Examples:
# Submit a job to display hello world:
submit_job.sh 'echo "hello world"' -N 1 -n 1 -r 00:01:00 -p development

# Display hello world twice, executing in parallel on different
# cores of one node:
echo 'echo "hello world 1"' > myscript.sh
echo 'echo "hello world 2"' >> myscript.sh
submit_job.sh -s myscript.sh -N 1 -n 2 -r 00:01:00 -p development

EOF
    exit 1
fi

script=""
remora=false
jobname=Job
while getopts ":s:xJ:" opt; do
    case $opt in
        s)
	    # read script file and stop reading options (prevents
	    # confusion between submit_job options and launch options)
            script="$OPTARG"
	    break
            ;;
	x)
	    remora=true
	    ;;
	J)
	    jobname="$OPTARG"
	    ;;
    esac
done

shift $((OPTIND-1))

# get the next job file for this basename, in the BATCHDIR
jobfile=$(get_auto_jobfile.sh "$jobname")

if [ -n "$script" ]; then
    # script with one or more commands
    echo "Script: $script"
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
