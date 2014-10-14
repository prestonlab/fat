#!/bin/bash

basedir=$1
subject=$2

subjdir=${basedir}/${subject}
epiregdir=${subjdir}/BOLD/fm
anatdir=${basedir}/${subject}/anatomy
mkdir -p ${epiregdir}
mkdir -p ${subjdir}/logs
mkdir -p ${subjdir}/anatomy/antsreg/data/unwarp
now=$(date +"%m%d%Y")
log=${basedir}/${subject}/logs/reg_unwarped_${now}.log

# calculate orig to func transform
ANTS 3 -m MI[${epiregdir}/refvol_unwarp.nii.gz,${anatdir}/orig.nii.gz,1,32] \
    -o ${epiregdir}/orig2unwarp_ --rigid-affine true -i 0 >> $log

# apply transformations to functional space
WarpImageMultiTransform 3 $anatdir/orig.nii.gz \
    $anatdir/antsreg/data/unwarp/orig.nii.gz \
    -R ${epiregdir}/refvol_unwarp.nii.gz ${epiregdir}/orig2unwarp_Affine.txt >> $log

WarpImageMultiTransform 3 $anatdir/aparc+aseg.nii.gz \
    $anatdir/antsreg/data/unwarp/aparc+aseg.nii.gz \
    -R ${epiregdir}/refvol_unwarp.nii.gz ${epiregdir}/orig2unwarp_Affine.txt >> $log

