#!/bin/bash

job_dir=${BATCHDIR}
running=`squeue -u $USER -h -o "%j"`
for f in $running; do
    file=`ls -1 ${job_dir}/${f}.o*`
    echo "$f output:"
    while read line; do
	echo $line
    done < $file
done
