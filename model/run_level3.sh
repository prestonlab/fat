#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage:   run_level3.sh model copeno"
    echo "Example: run_level3.sh loc_cond 1"
    exit 1
fi

model=$1
copeno=$2

if [ -z $STUDYDIR ]; then
    echo "Error: study directory is undefined: $STUDYDIR" 1>&2
    exit 1
fi

fsf=${STUDYDIR}/batch/glm/${model}/fsf/${model}_cope${copeno}.fsf
if [ ! -e $fsf ]; then
    echo "FSF file not found: ${fsf}. Exiting." 1>&2
    exit 1
fi

# get the output directory from the fsf file
output_dir=$(grep outputdir $fsf | awk -F '"' '{ print $2 }')
parent_dir=$(dirname $output_dir)
output_name=$(basename $output_dir)

mkdir -p $parent_dir
if cd $parent_dir; then
    rm -rf $output_name*.gfeat
else
    echo "Error: problem creating parent directory: $parent_dir" 1>&2
    exit 1
fi

# unset the SGE_ROOT variable. This indicates to FSL that it should
# not attempt to submit jobs
export SGE_ROOT=""
feat ${fsf}
