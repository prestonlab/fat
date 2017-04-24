#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Print commands to run a level 1 model for all scans."
    echo "Usage:   commands_level1.sh model subjids runids"
    echo "Example: commands_level1.sh loc_subcat bender_02:bender_02 loc_1:loc_2:loc_3:loc_4"
    echo "A run will be skipped (no command printed) if:"
    echo " - a dof file exists for the model, indicating it has run already"
    echo " - an fsf file does not exist in the standard filename"
    echo " - any onset files in the fsf file are empty"
    exit 1
fi

model=$1
subjids=$2
runids=$3

sids="$(echo $subjids | sed "s/:/ /g")"
rids="$(echo $runids | sed "s/:/ /g")"
for subjid in $sids; do
    for runid in $rids; do
	dof_file=$STUDYDIR/$subjid/model/$model/${runid}.feat/stats/dof
	if [ -e $dof_file ]; then
	    continue
	fi

	# get the FSF file for this subject and run
	fsf=${STUDYDIR}/batch/glm/${model}/fsf/${model}_${subjid}_${runid}.fsf
	if [ ! -e $fsf ]; then
	    continue
	fi

	# determine whether any of the onset files are empty
	onset_files=`grep 'set fmri(custom[0-9]*) \".*.txt\"' $fsf | cut -d \" -f 2`
	missing=0
	for file in $onset_files; do
	    if [ ! -s $file ]; then
		missing=1
		continue
	    fi
	done
	if [ $missing = 1 ]; then
	    continue
	fi
	
	echo "run_level1.sh $model $subjid $runid"
    done
done
