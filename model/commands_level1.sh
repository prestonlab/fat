#!/bin/bash

model=$1
runids=$2

sids="`echo $SUBJNOS | sed "s/:/ /g"`"
rids="`echo $runids | sed "s/:/ /g"`"
for no in $sids; do
    subjid=`subjids $no`
    for runid in $rids; do
	dof_file=$STUDYDIR/$subjid/model/$model/${runid}.feat/stats/dof
	if [ ! -e $dof_file ]; then
	    echo "run_level1.sh $model $subjid $runid"
	fi
    done
done
