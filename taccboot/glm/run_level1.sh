#!/bin/bash

expname=taccboot
bdir=$CORRALDIR/$expname/batch/glm

mkdir -p $bdir/launchscripts

for sbj in $1
do
    echo "feat ${bdir}/fsf/lev1_${sbj}_run1.fsf" > $bdir/launchscripts/sacfix_${sbj}.txt
    echo "feat ${bdir}/fsf/lev1_${sbj}_run2.fsf" >> $bdir/launchscripts/sacfix_${sbj}.txt
    cd $bdir/launchscripts
    launch -s ${bdir}/launchscripts/sacfix_${sbj}.txt -r 01:00:00 -n sacfix_${sbj}
done
    