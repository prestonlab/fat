#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Print commands to run a level 1 model for all scans."
    echo "Usage:   commands_level1.sh model runids"
    echo "Example: commands_level1.sh loc_subcat loc_1:loc_2:loc_3:loc_4"
    exit 1
fi

model=$1
runids=$2

sids="$(echo $SUBJNOS | sed "s/:/ /g")"
rids="$(echo $runids | sed "s/:/ /g")"
for no in $sids; do
    subjid=$(subjids $no)
    for runid in $rids; do
	dof_file=$STUDYDIR/$subjid/model/$model/${runid}.feat/stats/dof
	if [ ! -e $dof_file ]; then
	    echo "run_level1.sh $model $subjid $runid"
	fi
    done
done
