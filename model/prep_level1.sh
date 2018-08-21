#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Prepare level 1 analysis from an example FEAT FSF file."
    echo
    echo "Usage:"
    echo "`basename $0` example outdir model orig_subj orig_run all_subj all_run"
    echo
    echo "Example:"
    echo 'prep_level1.sh disp_stim_mistr_02_disp_1.fsf $WORK/mistr/batch/glm/disp_stim/fsf disp_stim mistr_02 disp_1 $SUBJIDS $RUNS'
    echo
    echo "Inputs:"
    echo "example    path to example FSF file"
    echo "outdir     path to directory in which to save customized FSF files"
    echo "model      name of statistical model (any model name you want to use)"
    echo "orig_subj  ID of the subject used in the example FSF file"
    echo "orig_run   ID of the run used in the example FSF file"
    echo "all_subj   list of all subject IDs (separated by :)"
    echo "all_run    list of all run IDs (separated by :)"
    echo
    exit 1
fi

example="$1"
outdir="$2"
model="$3"
orig_subj="$4"
orig_run="$5"
all_subj="$6"
all_run="$7"

mkdir -p "$outdir"

for subj in $(echo $all_subj | tr ':' ' '); do
    for run in  $(echo $all_run | tr ':' ' '); do
	customfsf="$outdir"/${model}_${subj}_${run}.fsf
	sed -e "s|${orig_subj}|${subj}|g" \
	    -e "s|${orig_run}|${run}|g" \
	    <$example >$customfsf
    done
done
