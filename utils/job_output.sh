#!/bin/bash

job_dir=${BATCHDIR}

if [ $# -lt 1 ]; then
    running=`squeue -u $USER -h -o "%j"`
else
    running="$1"
fi
shopt -s nullglob
for f in $running; do
    for file in ${job_dir}/${f}.o*; do
	echo "$f output:"
	while read line; do
	    echo $line
	done < $file
    done
done
