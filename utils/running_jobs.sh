#!/bin/bash

job_dir=${BATCHDIR}/auto
running=`qstat | grep Job | cut -d " " -f 3`
for f in $running; do
    file=${job_dir}/${f}.sh
    script=`cat $file`
    echo "$f:"
    echo $script
done

