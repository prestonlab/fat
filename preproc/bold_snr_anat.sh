#!/bin/bash

bold_dir=$1

cd $bold_dir
fslmaths bold -Tmean bold_avg
fslmaths bold -Tstd bold_std
fslmaths bold_avg -div bold_std bold_snr

antsApplyTransforms -d 3 -i bold_snr.nii.gz -r ../../anatomy/orig.nii.gz -o bold_snr_anat.nii.gz -t bold_cor_mcf_avg_anat_0GenericAffine.mat -n BSpline
