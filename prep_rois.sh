#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Prepare standard Freesurfer ROIs for analysis"
    echo
    echo "Usage:"
    echo "prep_rois.sh [basedir] [subject]"
    echo
    echo "Inputs:"
    echo "basedir   path to directory with experiment data"
    echo "subject   full subject identifier"
    echo
    exit 1
fi

basedir=$1
subject=$2

subjdir=${basedir}/${subject}
parcfile=${subjdir}/anatomy/antsreg/data/unwarp/aparc+aseg.nii.gz

if [ ! -d ${subjdir} ]; then
    echo "Subject directory does not exist: ${basedir}/${subject}" >&2
    exit 1
fi

if [ ! -f ${parcfile} ]; then
    echo "Parcels file does not exist: ${parcfile}" >&2
    exit 1
fi

roidir=${subjdir}/fsroi

mkdir -p ${roidir}

# make ROI files
roi_freesurfer.sh ${parcfile} ${roidir}

# make functional brainmask
fslmaths ${subjdir}/BOLD/fm/refvol_unwarp.nii.gz -bin ${roidir}/brainmask.nii.gz
