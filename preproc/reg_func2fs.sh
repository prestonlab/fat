#!/bin/bash

subject=$1
refanat=$2

sd=$STUDYDIR/$subject/anatomy

# reference functional volume to nifti orig file, in FS format
tkregister2 --s $subject --sd $sd --mov $sd/orig${refanat}.nii.gz --targ $sd/$subject/mri/orig.mgz --fsl $sd/bbreg/transfroms/refvol-highres.mat --noedit --reg $sd/refvol-orig.dat

# nifti orig file to FS orig file
tkregister2 --s $subject --sd $sd --mov $sd/orig${refanat}.nii.gz --targ $sd/$subject/mri/orig.mgz --regheader --noedit --reg $sd/orig-fsorig.dat

# combine
mri_matrix_multiply -s $subject -im $sd/orig-fsorig.dat -im $sd/refvol-orig.dat -om refvol-fsorig.dat
