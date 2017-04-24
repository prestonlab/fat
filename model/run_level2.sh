#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage:   run_level2.sh model subjid"
    echo "Example: run_level2.sh loc_cond bender_01"
    echo
    echo "Assumes that the fsf file is in:"
    echo '$STUDYDIR/batch/glm/$model/fsf/${model}_${subjid}.fsf'
    echo
    echo "Any existing gfeat directories at the outputdir path will"
    echo "be overwritten."
    exit 1
fi

model=$1
subjid=$2

if [ -z $STUDYDIR ]; then
    echo "Error: STUDYDIR is undefined." 1>&2
    exit 1
fi

fsf=${STUDYDIR}/batch/glm/${model}/fsf/${model}_${subjid}.fsf
if [ ! -e $fsf ]; then
    echo "FSF file not found: ${fsf}. Exiting." 1>&2
    exit 1
fi

# get the output directory from the fsf file
output_dir=$(grep outputdir $fsf | awk -F '"' '{ print $2 }')
parent_dir=$(dirname $output_dir)
output_name=$(basename $output_dir)

# remove existing output directories
if cd $parent_dir; then
    rm -rf $output_name*.gfeat
else
    echo "Error: parent directory does not exist: $parent_dir" 1>&2
    exit 1
fi

# unset the SGE_ROOT variable. This indicates to FSL that it should
# not attempt to submit jobs
export SGE_ROOT=""
feat ${fsf}
