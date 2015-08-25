#!/bin/bash

job_dir=${BATCHDIR}
running=`qstat | grep Job | cut -d " " -f 3`
for f in $running; do
    file=${job_dir}/${f}.sh
    echo "$f:"
    while read line; do
	echo $line
    done < $file
done

