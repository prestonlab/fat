#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Create parietal rois from the Juelich atlas"
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

# Inferior Parietal Lobule
fslmaths parcels.nii.gz -thr 27 -uthr 27 -bin PF_L.nii.gz
fslmaths parcels.nii.gz -thr 28 -uthr 28 -bin PF_R.nii.gz
fslmaths parcels.nii.gz -thr 29 -uthr 29 -bin PFcm_L.nii.gz
fslmaths parcels.nii.gz -thr 30 -uthr 30 -bin PFcm_R.nii.gz
fslmaths parcels.nii.gz -thr 31 -uthr 31 -bin PFm_L.nii.gz
fslmaths parcels.nii.gz -thr 32 -uthr 32 -bin PFm_R.nii.gz
fslmaths parcels.nii.gz -thr 33 -uthr 33 -bin PFop_L.nii.gz
fslmaths parcels.nii.gz -thr 34 -uthr 34 -bin PFop_R.nii.gz
fslmaths parcels.nii.gz -thr 35 -uthr 35 -bin PFt_L.nii.gz
fslmaths parcels.nii.gz -thr 36 -uthr 36 -bin PFt_R.nii.gz
fslmaths parcels.nii.gz -thr 37 -uthr 37 -bin Pga_L.nii.gz
fslmaths parcels.nii.gz -thr 38 -uthr 38 -bin Pga_R.nii.gz
fslmaths parcels.nii.gz -thr 39 -uthr 39 -bin PGp_L.nii.gz
fslmaths parcels.nii.gz -thr 40 -uthr 40 -bin PGp_R.nii.gz

# Anterior Intra-parietal sulcus
fslmaths parcels.nii.gz -thr 1 -uthr 1 -bin hIP1_L.nii.gz    
fslmaths parcels.nii.gz -thr 2 -uthr 2 -bin hIP1_R.nii.gz
fslmaths parcels.nii.gz -thr 3 -uthr 3 -bin hIP2_L.nii.gz
fslmaths parcels.nii.gz -thr 4 -uthr 4 -bin hIP2_R.nii.gz
fslmaths parcels.nii.gz -thr 5 -uthr 5 -bin hIP3_L.nii.gz
fslmaths parcels.nii.gz -thr 6 -uthr 6 -bin hIP3_R.nii.gz        

# Parietal operculum
fslmaths parcels.nii.gz -thr 59 -uthr 59 -bin OP1_L.nii.gz
fslmaths parcels.nii.gz -thr 60 -uthr 60 -bin OP1_R.nii.gz
fslmaths parcels.nii.gz -thr 61 -uthr 61 -bin OP2_L.nii.gz
fslmaths parcels.nii.gz -thr 62 -uthr 62 -bin OP2_R.nii.gz
fslmaths parcels.nii.gz -thr 63 -uthr 63 -bin OP3_L.nii.gz
fslmaths parcels.nii.gz -thr 64 -uthr 64 -bin OP3_R.nii.gz
fslmaths parcels.nii.gz -thr 65 -uthr 65 -bin OP4_L.nii.gz
fslmaths parcels.nii.gz -thr 66 -uthr 66 -bin OP4_R.nii.gz

# Superior Parietal Lobule
fslmaths parcels.nii.gz -thr 67 -uthr 67 -bin 5Ci_L.nii.gz
fslmaths parcels.nii.gz -thr 68 -uthr 68 -bin 5Ci_R.nii.gz
fslmaths parcels.nii.gz -thr 69 -uthr 69 -bin 5L_L.nii.gz
fslmaths parcels.nii.gz -thr 70 -uthr 70 -bin 5L_R.nii.gz
fslmaths parcels.nii.gz -thr 71 -uthr 71 -bin 5M_L.nii.gz
fslmaths parcels.nii.gz -thr 72 -uthr 72 -bin 5M_R.nii.gz
fslmaths parcels.nii.gz -thr 73 -uthr 73 -bin 7A_L.nii.gz
fslmaths parcels.nii.gz -thr 74 -uthr 74 -bin 7A_R.nii.gz
fslmaths parcels.nii.gz -thr 75 -uthr 75 -bin 7M_L.nii.gz
fslmaths parcels.nii.gz -thr 76 -uthr 76 -bin 7M_R.nii.gz
fslmaths parcels.nii.gz -thr 77 -uthr 77 -bin 7PC_L.nii.gz
fslmaths parcels.nii.gz -thr 78 -uthr 78 -bin 7PC_R.nii.gz
fslmaths parcels.nii.gz -thr 79 -uthr 79 -bin 7P_L.nii.gz
fslmaths parcels.nii.gz -thr 80 -uthr 80 -bin 7P_R.nii.gz

chmod 775 *.nii.gz

# Combo ROIs
fslmaths PF_L.nii.gz -add PF_R.nii.gz -add PFcm_L.nii.gz -add PFcm_R.nii.gz PFm_L.nii.gz -add PFm_R.nii.gz -add PFop_L.nii.gz -add PFop_R.nii.gz -add PFt_L.nii.gz -add PFt_R.nii.gz -add Pga_L.nii.gz -add Pga_R.nii.gz -add PGp_L.nii.gz -add PGp_R.nii.gz IPL.nii.gz
fslmaths hIP1_L.nii.gz -add hIP1_R.nii.gz -add hIP2_L -add hIP2_R -add hIP3_L -add hIP3_R aIPS.nii.gz
fslmaths OP1_L.nii.gz -add OP1_R.nii.gz -add OP2_L.nii.gz -add OP2_R.nii.gz -add OP3_L.nii.gz -add OP3_R.nii.gz -add OP4_L.nii.gz -add OP4_R.nii.gz ParOper.nii.gz
fslmaths 5Ci_L.nii.gz -add 5Ci_R.nii.gz -add 5L_L.nii.gz -add 5L_R.nii.gz -add 5M_L.nii.gz -add 5M_R.nii.gz -add 7A_L.nii.gz -add 7A_R.nii.gz -add 7M_L.nii.gz -add 7M_R.nii.gz -add 7PC_L.nii.gz -add 7PC_R.nii.gz -add 7P_L.nii.gz -add 7P_R.nii.gz SPL.nii.gz 

chmod 775 *.nii.gz