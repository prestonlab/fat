#!/bin/bash

job_dir=${BATCHDIR}
running=`squeue -u $USER -h -o "%j" -S i`
for f in $running; do
    status=`squeue -u $USER -n $f -h -o %T`
    elapsed=`squeue -u $USER -n $f -h -o %M`
    limit=`squeue -u $USER -n $f -h -o %l`
    file=${job_dir}/${f}
    if [ -e ${file}.sh ]; then
	ext=.sh
    else
	ext=.txt
    fi
	
    if [ -e ${file}${ext} ]; then
	echo "$f ($status $elapsed/$limit):"
	while read line; do
	    echo $line
	done < ${file}${ext}
    else
	echo "$f ($status $elapsed/$limit)"
    fi
done
