#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Print the latest status message for a processing step."
    echo "Usage:   preproc_status.sh part [log]"
    echo "  Default log is 'preproc'."
    echo "Example: preproc_status.sh prepbold"
    exit 1
fi

part=$1

if [ $# -eq 2 ]; then
    log_name=$2
else
    log_name=preproc.log
fi

grep -h "Finished $part" ${STUDYDIR}/${STUDY}_*/logs/${log_name}
