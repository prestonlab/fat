#!/bin/bash

basedir=$1
subject=$2

subjdir=${basedir}/${subject}
fmdir=${subjdir}/fieldmap
epiregdir=${subjdir}/BOLD/fm
mkdir -p ${epiregdir}
mkdir -p ${subjdir}/logs
now=$(date +"%m%d%Y")
log=${basedir}/${subject}/logs/reg_fieldmap_${now}.log

# calculate transform from fieldmap to functional space
epiref=${subjdir}/BOLD/antsreg/data/refvol.nii.gz
fmap=${fmdir}/fieldmap1_rads1.nii.gz
fmap2epi_base=${epiregdir}/rad2epi_
echo "Transforming fieldmap to functional space..." >> $log
echo "Calculating affine transformation..." >> $log
ANTS 3 -m MI[$epiref,$fmap,1,32] -o ${fmap2epi_base} --rigid-affine true -i 0 >> ${log}

# apply transform
echo "Applying transformation..." >> $log
fmapepi=${epiregdir}/epi_unwarp_fieldmaprads2epi.nii.gz
WarpImageMultiTransform 3 ${fmap} ${fmapepi} -R ${epiref} ${fmap2epi_base}Affine.txt >> ${log}

# create mask for fieldmap
echo "Creating mask for fieldmap..." >> $log
fmapepi_mask=${epiregdir}/epi_unwarp_fieldmaprads2epi_mask.nii.gz
fslmaths ${fmapepi} -abs -bin ${fmapepi_mask} >> $log
