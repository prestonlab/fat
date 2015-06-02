#!/bin/bash

export bdir=$CORRALDIR/taccboot

for sbj in 103
do
    for r in 1 2
    do
        sdir=$bdir/iceman_${sbj}
        cp -r $CORRALDIR/taccboot/batch/glm/reg ${sdir}/model/sacfix_run${r}.feat/.
        cp ${sdir}/BOLD/functional_saccade_6/bold_mcf_brain_vol1.nii.gz ${sdir}/model/sacfix_run${r}.feat/reg/standard.nii.gz
        updatefeatreg ${sdir}/model/sacfix_run${r}.feat/ -pngs
    done
done