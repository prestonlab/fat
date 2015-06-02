#!/bin/bash

bdir=$CORRALDIR/taccboot/batch/glm

for sbj in $1
do
    sed -e "s|RUNNUM|1|g" -e "s|SERIESNUM|6|g" -e "s|SUBNUM|$sbj|g" <$bdir/lev1_sacfix.fsf >$bdir/fsf/lev1_${sbj}_run1.fsf
    sed -e "s|RUNNUM|2|g" -e "s|SERIESNUM|13|g" -e "s|SUBNUM|$sbj|g" <$bdir/lev1_sacfix.fsf >$bdir/fsf/lev1_${sbj}_run2.fsf
done