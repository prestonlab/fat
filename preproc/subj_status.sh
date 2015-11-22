#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Print all processing status messages for a subject."
    echo "Usage:   subj_status.sh subject [log]"
    echo "  Default log is 'preproc.log'."
    echo "Example: subj_status.sh bender_17"
    exit 1
fi

subject=$1

if [ $# -eq 2 ]; then
    log_name=$2
else
    log_name=preproc.log
fi

grep -h "^Finished" ${STUDYDIR}/${subject}/logs/${log_name}
