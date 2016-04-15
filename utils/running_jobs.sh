#!/bin/bash

job_dir=${BATCHDIR}
running=`squeue -u $USER -h -o "%j"`
for f in $running; do
    file=${job_dir}/${f}.sh
    echo "$f:"
    while read line; do
	echo $line
    done < $file
done
