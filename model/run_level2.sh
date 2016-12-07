#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage:   run_level2.sh model subjid"
    echo "Example: run_level2.sh loc_cond bender_01"
    exit 1
fi

model=$1
subjid=$2

if [ -z $STUDYDIR ]; then
    echo "Error: study directory is undefined: $STUDYDIR" 1>&2
    exit 1
fi

fsf=${STUDYDIR}/batch/glm/${model}/fsf/${model}_${subjid}.fsf
if [ ! -e $fsf ]; then
    echo "FSF file not found: ${fsf}. Exiting." 1>&2
    exit 1
fi

model_dir=${STUDYDIR}/${subjid}/model/${model}
if cd ${model_dir}; then
    rm -rf *.gfeat
else
    echo "Error: model directory does not exist: $model_dir" 1>&2
    exit 1
fi

# unset the SGE_ROOT variable. This indicates to FSL that it should
# not attempt to submit jobs
export SGE_ROOT=""
feat ${fsf}
