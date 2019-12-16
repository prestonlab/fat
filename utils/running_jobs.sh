#!/bin/bash
#
# Print status about running jobs submitted through launch.

show_cmds=false
while getopts ":sn:" opt; do
    case $opt in
        s)
            show_cmds=true
            ;;
        n)
            lines=$OPTARG
            ;;
        *)
            echo "Invalid option: $opt"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

job_dir="${BATCHDIR}"

# get a list of names for all running or pending jobs
running=$(squeue -u $USER -h -o "%j" -S i -t RUNNING,PENDING)
for f in $running; do
    # look up queue information about this job
    status=$(squeue -u $USER -n $f -h -o %T)
    elapsed=$(squeue -u $USER -n $f -h -o %M)
    limit=$(squeue -u $USER -n $f -h -o %l)

    # check for a command file with the same name
    file="${job_dir}/${f}"
    if [[ -e ${file}.sh ]]; then
        ext=.sh
    else
        ext=.txt
    fi

    # if there is an output file, check how many commands are finished
    if [[ -e ${file}.out ]]; then
        # assume standard naming as in ezlaunch, slaunch, rlaunch
        n_command=$(wc -l "${file}.sh" | cut -d ' ' -f 1)
        n_finished=$(grep -c 'Launcher: Job [[:digit:]]* completed in [[:digit:]]* seconds.' "${file}.out")
    fi

    # progress summary
    if [[ $n_finished ]]; then
        echo "$f ($status $n_finished/$n_command $elapsed/$limit)"
    else
        echo "$f ($status $elapsed/$limit)"
    fi

    # list all commands
    if [[ -e ${file}${ext} && $show_cmds = true ]]; then
        if [[ $lines ]]; then
            head -n $lines ${file}${ext}
        else
            while read line; do
                echo $line
            done < "${file}${ext}"
        fi
    fi
done
