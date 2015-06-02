#!/bin/bash

# 12/14/2012: MLS updated to add in freesurfer orig.mgz to alignment
# 12/17/2012: MLM updated for iceman
# 6/06/2013: MLM updated for taccboot

BASEDIR=/corral-repl/utexas/prestonlab
EXPNAME=taccboot
EXPDIR=$BASEDIR/$EXPNAME

SUBNUM=$1
SERIESREF=6

SUBCODE=iceman_$SUBNUM
SUBDIR=${EXPDIR}/${SUBCODE}


# redirect logging into subject log directory
#exec > ${SUBDIR}/logs/reg_anats.log 2>&1
#cat /corral-repl/utexas/prestonlab/software/prestonlab_logo2.txt
#now=$(date +"%m%d%Y")
#echo "reg_bold.sh: ${now}"
set -x
antsfile="$SUBDIR/logs/reg_anats_ants.log"


## make directories
mkdir -p $SUBDIR/anatomy/antsreg
mkdir -p $SUBDIR/anatomy/antsreg/data/funcspace
mkdir -p $SUBDIR/anatomy/antsreg/data/inplanespace
mkdir -p $SUBDIR/anatomy/antsreg/transforms

## convert freesurfer volumes from mgz to nifti
# convert orig (from freesurfer, will be used for registering aparc+aseg)
mri_convert $SUBDIR/anatomy/$SUBCODE/mri/orig.mgz $SUBDIR/anatomy/$SUBCODE/mri/orig.nii.gz
# convert aparc+aseg
mri_convert $SUBDIR/anatomy/$SUBCODE/mri/aparc+aseg.mgz $SUBDIR/anatomy/$SUBCODE/mri/aparc+aseg.nii.gz

## Bet original space structurals (highres, inplane)
# bet inplane
bet $SUBDIR/anatomy/inplane $SUBDIR/anatomy/inplane_brain -R -m
# bet highres
bet $SUBDIR/anatomy/highres $SUBDIR/anatomy/highres_brain -R -m


## coregister with ANTS
# orig to MPRAGE
ANTS 3 -m MI[$SUBDIR/anatomy/highres.nii.gz,$SUBDIR/anatomy/$SUBCODE/mri/orig.nii.gz,1,32] -o $SUBDIR/anatomy/antsreg/transforms/orig2highres_ --rigid-affine true -i 0 >> "$antsfile"

# MPRAGE to inplane
ANTS 3 -m MI[$SUBDIR/anatomy/inplane.nii.gz,$SUBDIR/anatomy/highres.nii.gz,1,32] -o $SUBDIR/anatomy/antsreg/transforms/highres2inplane_ --rigid-affine true -i 0 >> "$antsfile"

# inplane to functional reference run
ANTS 3 -m MI[$SUBDIR/BOLD/functional_saccade_${SERIESREF}/bold_mcf_brain_vol1.nii.gz,$SUBDIR/anatomy/inplane.nii.gz,1,32] -o $SUBDIR/anatomy/antsreg/transforms/inplane2func${SERIESREF}_ --rigid-affine true -i 0 >> "$antsfile"


## Concatenate affine transformations
# orig to inplane
ComposeMultiTransform 3 $SUBDIR/anatomy/antsreg/transforms/orig2inplane_Affine.txt -R $SUBDIR/anatomy/antsreg/transforms/highres2inplane_Affine.txt $SUBDIR/anatomy/antsreg/transforms/highres2inplane_Affine.txt $SUBDIR/anatomy/antsreg/transforms/orig2highres_Affine.txt >> "$file"
# orig to func
ComposeMultiTransform 3 $SUBDIR/anatomy/antsreg/transforms/orig2func${SERIESREF}_Affine.txt -R $SUBDIR/anatomy/antsreg/transforms/inplane2func${SERIESREF}_Affine.txt $SUBDIR/anatomy/antsreg/transforms/inplane2func${SERIESREF}_Affine.txt $SUBDIR/anatomy/antsreg/transforms/orig2inplane_Affine.txt >> "$file"
# mprage to func
ComposeMultiTransform 3 $SUBDIR/anatomy/antsreg/transforms/highres2func${SERIESREF}_Affine.txt -R $SUBDIR/anatomy/antsreg/transforms/inplane2func${SERIESREF}_Affine.txt $SUBDIR/anatomy/antsreg/transforms/inplane2func${SERIESREF}_Affine.txt $SUBDIR/anatomy/antsreg/transforms/highres2inplane_Affine.txt >> "$file"


## Apply transformations to INPLANE space
# highres to inplane
WarpImageMultiTransform 3 $SUBDIR/anatomy/highres.nii.gz $SUBDIR/anatomy/antsreg/data/inplanespace/highres.nii.gz -R $SUBDIR/anatomy/inplane.nii.gz $SUBDIR/anatomy/antsreg/transforms/highres2inplane_Affine.txt >> "$antsfile"
# orig to inplane
WarpImageMultiTransform 3 $SUBDIR/anatomy/$SUBCODE/mri/orig.nii.gz $SUBDIR/anatomy/antsreg/data/inplanespace/orig.nii.gz -R $SUBDIR/anatomy/inplane.nii.gz $SUBDIR/anatomy/antsreg/transforms/orig2inplane_Affine.txt >> "$antsfile"


## Apply transformations to FUNCTIONAL space
# highres to func
WarpImageMultiTransform 3 $SUBDIR/anatomy/highres.nii.gz $SUBDIR/anatomy/antsreg/data/funcspace/highres.nii.gz -R $SUBDIR/BOLD/functional_saccade_${SERIESREF}/bold_mcf_brain_vol1.nii.gz $SUBDIR/anatomy/antsreg/transforms/highres2func${SERIESREF}_Affine.txt >> "$antsfile"
# orig to func
WarpImageMultiTransform 3 $SUBDIR/anatomy/$SUBCODE/mri/orig.nii.gz $SUBDIR/anatomy/antsreg/data/funcspace/orig.nii.gz -R $SUBDIR/BOLD/functional_saccade_${SERIESREF}/bold_mcf_brain_vol1.nii.gz $SUBDIR/anatomy/antsreg/transforms/orig2func${SERIESREF}_Affine.txt >> "$antsfile"
# inplane to func
WarpImageMultiTransform 3 $SUBDIR/anatomy/inplane.nii.gz $SUBDIR/anatomy/antsreg/data/funcspace/inplane.nii.gz -R $SUBDIR/BOLD/functional_saccade_${SERIESREF}/bold_mcf_brain_vol1.nii.gz $SUBDIR/anatomy/antsreg/transforms/inplane2func${SERIESREF}_Affine.txt >> "$antsfile"
