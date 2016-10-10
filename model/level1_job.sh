#!/bin/bash

model=$1
subjects=$2
runs=$3

if [ $# -lt 4 ]; then
    job_file=${model}_level1.sh
else
    job_file=$4
fi

cd $BATCHDIR
if [ -e $job_file ]; then
    rm $job_file
fi

subjnos=`echo $subjects | sed s/:/' '/g`
runids=`echo $runs | sed s/:/' '/g`
for s in $subjnos; do
    subjid=`printf ${STUDY}_%02d $s`
    for r in $runids; do
	dof_file=$STUDYDIR/$subjid/model/$model/${r}.feat/stats/dof
	if [ ! -e $dof_file ]; then
	    echo "run_level1.sh $model $subjid $r" >> $job_file
	fi
    done
done
