#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Create mtl rois from jackson's mtl atlas"
    echo
    echo "Usage:"
    echo "roi_jackson_mtl.sh [parcfile] [outdir]"
    echo
    echo "Inputs:"
    echo "parcfile   path to transformed parcel file"
    echo "outdir     directory in which to save ROI files"
    echo
    exit 1
fi

parcfile=$1
outdir=$2

if [ ! -f ${parcfile} ]
then
    echo "Input parcel file does not exist: ${parcfile}" 1>&2
    exit 1
fi

if [ ! -d ${outdir} ]
then
    echo "Output directory does not exist: ${outdir}" 1>&2
    exit 1
fi

cp ${parcfile} ${outdir}/parcels.nii.gz
cd ${outdir}

fslmaths parcels.nii.gz -thr 1 -uthr 1 -bin r_prc.nii.gz
fslmaths parcels.nii.gz -thr 2 -uthr 2 -bin l_prc.nii.gz
fslmaths parcels.nii.gz -thr 3 -uthr 3 -bin r_erc.nii.gz
fslmaths parcels.nii.gz -thr 4 -uthr 4 -bin l_erc.nii.gz
fslmaths parcels.nii.gz -thr 5 -uthr 5 -bin r_hip.nii.gz
fslmaths parcels.nii.gz -thr 6 -uthr 6 -bin l_hip.nii.gz
fslmaths parcels.nii.gz -thr 7 -uthr 7 -bin r_phc.nii.gz
fslmaths parcels.nii.gz -thr 8 -uthr 8 -bin l_phc.nii.gz

fslmaths r_prc.nii.gz -add r_erc.nii.gz -add r_phc.nii.gz -bin r_mtlctx.nii.gz
fslmaths l_prc.nii.gz -add l_erc.nii.gz -add l_phc.nii.gz -bin l_mtlctx.nii.gz

fslmaths r_prc.nii.gz -add r_phc.nii.gz -bin r_prcphc.nii.gz
fslmaths l_prc.nii.gz -add l_phc.nii.gz -bin l_prcphc.nii.gz

chmod 775 *.nii.gz

for roi in prc phc erc hip mtlctx prcphc
do
   fslmaths r_${roi}.nii.gz -add l_${roi}.nii.gz -bin b_${roi}.nii.gz
done

chmod 775 *.nii.gz