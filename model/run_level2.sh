#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage:   run_level2.sh model subjid"
    echo "Example: run_level2.sh loc_cond bender_01"
    exit 1
fi

model=$1
subjid=$2

fsf=${STUDYDIR}/batch/glm/${model}/fsf/${model}_${subjid}.fsf
if [ ! -e $fsf ]; then
    echo "FSF file not found: ${fsf}. Exiting."
    exit 1
fi

rm -rf ${STUDYDIR}/${subjid}/model/${model}/level2*.gfeat

# unset the SGE_ROOT variable. This indicates to FSL that it should
# not attempt to submit jobs
export SGE_ROOT=""
feat ${fsf}
