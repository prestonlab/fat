#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: run_level1.sh model subjid runid"
    echo "Example: run_level1.sh prex_cond bender_01 loc_1"
    exit 1
fi

model=$1
subjid=$2
runid=$3

glmdir=${STUDYDIR}/batch/glm
modeldir=${glmdir}/${model}

fsf=${STUDYDIR}/batch/glm/${model}/fsf/${model}_${subjid}_${runid}.fsf
if [ ! -e $fsf ]; then
    echo "FSF file not found: ${fsf}. Exiting."
    exit 1
fi

subjmodeldir=${STUDYDIR}/${subjid}/model/${model}
mkdir -p $subjmodeldir
rm -rf $subjmodeldir/${runid}*.feat

cd ${STUDYDIR}

# unset the SGE_ROOT variable. This indicates to FSL that it should
# not attempt to submit jobs
export SGE_ROOT=""
feat ${fsf}
