#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: prep_bold_run.sh [-k] bold_dir"
    echo
    echo "Required:"
    echo "bold_dir"
    echo "    Path to directory with a raw functional timeseries image named"
    echo "    bold.nii.gz. Outputs will be placed in this directory."
    echo
    echo "Options:"
    echo "-k"
    echo "    Keep intermediate files."
    exit 1
fi

keep=0
while getopts ':k' opt; do
    case $opt in
	k)
	    keep=1
	    ;;
    esac
done
shift $((OPTIND-1))

bolddir=$1
if [ ! -d $bolddir ]; then
    echo "Error: directory does not exist: $bolddir."
    exit 1
fi

cd $bolddir

if [ ! $(imtest bold) ]; then
    echo "Error: bold image file not found in $bolddir."
    exit 1
fi

rm -rf QA bold_cor_mcf*.mat
rm -f bold_* *.png

## anatomy-based preprocessing

# N4 bias field correction on each volume, so motion correction will
# be focused on anatomical features rather than motion relative to
# bias fields
N4BiasFieldCorrection -d 4 -i bold.nii.gz -o bold_cor.nii.gz

# run standard mcflirt (based on FEAT in fsl 5.0.9)
mcflirt -in bold_cor -mats -plots -rmsrel -rmsabs -spline_final

# summary plots (will be more in the QA report, but make a quick
# summary here)
fsl_tsplot -i bold_cor_mcf.par -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o rot.png
fsl_tsplot -i bold_cor_mcf.par -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o trans.png
fsl_tsplot -i bold_cor_mcf_abs.rms,bold_cor_mcf_rel.rms -t 'MCFLIRT estimated mean displacement (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o disp.png

pngvstack {rot,trans,disp,mcf}.png

# average of bias corrected, motion corrected volumes. Will use this
# for registration and unwarping
fslmaths bold_cor_mcf -Tmean bold_cor_mcf_avg

if [ $keep = 0 ]; then
    imrm bold_cor bold_cor_mcf
fi

## time series preprocessing

# motion correction applied to original volumes
cat bold_cor_mcf.mat/MAT* > bold_cor_mcf.cat
applywarp -i bold -o bold_mcf -r bold_cor_mcf_avg --premat=bold_cor_mcf.cat --interp=spline --paddingsize=1

# mean image of originals motion corrected
fslmaths bold_mcf -Tmean bold_mcf_avg

# N4 bias field correction based on motion-corrected full head images
N4BiasFieldCorrection -d 3 -i bold_mcf_avg.nii.gz -o bold_mcf_avg_cor.nii.gz

# smaller brain mask for DVARS calculation
bet bold_mcf_avg_cor bold_mcf_brain -m

# QA/identify volumes to scrub
tr=$(fslval bold pixdim4)
cp bold_cor_mcf.par bold_mcf.par
fmriqa.py bold_mcf.nii.gz $tr

# remove intermediate files. Just need motion correction parameters, a
# good average image for registration, and the estimated bias field
if [ $keep = 0 ]; then
    imrm bold_mcf bold_mcf_brain bold_mcf_avg bold_mcf_avg_cor
fi
