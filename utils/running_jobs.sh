#!/bin/bash
#
# Print status about running jobs submitted through launch.

while getopts ":n:" opt; do
    case $opt in
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

job_dir=${BATCHDIR}
running=$(squeue -u $USER -h -o "%j" -S i -t RUNNING,PENDING)
for f in $running; do
    status=$(squeue -u $USER -n $f -h -o %T)
    elapsed=$(squeue -u $USER -n $f -h -o %M)
    limit=$(squeue -u $USER -n $f -h -o %l)
    file=${job_dir}/${f}
    if [ -e ${file}.sh ]; then
	ext=.sh
    else
	ext=.txt
    fi
	
    if [ -e ${file}${ext} ]; then
	echo "$f ($status $elapsed/$limit):"
	if [ -n "$lines" ]; then
	    head -n $lines ${file}${ext}
	else
	    while read line; do
		echo $line
	    done < ${file}${ext}
	fi
    else
	echo "$f ($status $elapsed/$limit)"
    fi
done
