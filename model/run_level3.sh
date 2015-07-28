#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage:   run_level3.sh model copeno"
    echo "Example: run_level3.sh loc_cond 1"
    exit 1
fi

model=$1
copeno=$2

fsf=${STUDYDIR}/batch/glm/${model}/fsf/${model}_cope${copeno}.fsf
if [ ! -e $fsf ]; then
    echo "FSF file not found: ${fsf}. Exiting."
    exit 1
fi

lev3=${STUDYDIR}/batch/glm/${model}/level3
mkdir -p $lev3
rm -rf ${lev3}/cope${copeno}*.gfeat

# unset the SGE_ROOT variable. This indicates to FSL that it should
# not attempt to submit jobs
export SGE_ROOT=""
feat ${fsf}
