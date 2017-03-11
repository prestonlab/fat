#!/bin/bash

cd $1

# motion correction applied to original volumes
if [ ! -f bold_cor_mcf.cat ]; then
    cat bold_cor_mcf.mat/MAT* > bold_cor_mcf.cat
fi

if [ ! -f bold_mcf.nii.gz ]; then
    applywarp -i bold -o bold_mcf -r bold_cor_mcf_avg --premat=bold_cor_mcf.cat --interp=spline --paddingsize=1
fi

# mean image of originals motion corrected
if [ ! -f bold_mcf_avg.nii.gz ]; then
    fslmaths bold_mcf -Tmean bold_mcf_avg
fi

# N4 bias field correction based on motion-corrected full head images
if [ ! -f bold_mcf_avg_cor.nii.gz ]; then
    N4BiasFieldCorrection -d 3 -i bold_mcf_avg.nii.gz -o bold_mcf_avg_cor.nii.gz
fi

# smaller brain mask for DVARS calculation
if [ ! -f bold_mcf_brain ]; then
    bet bold_mcf_avg_cor bold_mcf_brain -m
fi

# QA/identify volumes to scrub
tr=$(fslval bold pixdim4)
cp bold_cor_mcf.par bold_mcf.par
fmriqa.py bold_mcf.nii.gz $tr
