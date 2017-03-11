#!/bin/bash

subject=$1
if [ $# -lt 2 ]; then
    study_dir=$STUDYDIR
else
    study_dir=$2
fi

subj_dir=$STUDYDIR/$subject
checks_dir=$subj_dir/BOLD/checks
mkdir -p $checks_dir

filenames="bold_cor_mcf_avg_brain bold_cor_mcf_avg_unwarp_brain bold_reg_init_avg bold_reg_avg bold_reg_cor_brain_avg"

for filename in $filenames; do
    list=""
    for dir in $subj_dir/BOLD/*; do
	if [ $(basename $dir) = checks ]; then
	    continue
	fi
	
	if [ -f $dir/${filename}.nii.gz ]; then
	    if [ -z "$list" ]; then
		list=$dir/$filename
	    else
		list="$list $dir/$filename"
	    fi
	fi
    done
    output=$checks_dir/$filename

    # merge, ignoring warnings about inconsistent orientations
    echo "merging $filename images..."
    fslmerge -t $output $list 2>/dev/null
    fslmaths $output -inm 10000 $output
done
