#!/bin/bash

job_dir=${BATCHDIR}
running=`squeue -u $USER | grep Job | awk '{print $3}'`
for f in $running; do
    file=${job_dir}/${f}.sh
    echo "$f:"
    while read line; do
	echo $line
    done < $file
done

