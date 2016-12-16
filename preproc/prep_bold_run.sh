#!/bin/bash

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

rm -rf QA bold_mcf.mat
rm -f bold_mcf* *.png

# run standard mcflirt (based on FEAT in fsl 5.0.9)
mcflirt -in bold -mats -plots -rmsrel -rmsabs -spline_final

fsl_tsplot -i bold_mcf.par -t 'MCFLIRT estimated rotations (radians)' -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 144 -o rot.png
fsl_tsplot -i bold_mcf.par -t 'MCFLIRT estimated translations (mm)' -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 144 -o trans.png
fsl_tsplot -i bold_mcf_abs.rms,bold_mcf_rel.rms -t 'MCFLIRT estimated mean displacement (mm)' -u 1 -w 640 -h 144 -a absolute,relative -o disp.png

pngvstack {rot,trans,disp,mcf}.png

# brain extraction (liberal settings)
bet bold_mcf bold_mcf_brain -F

# mean image
fslmaths bold_mcf_brain -Tmean bold_mcf_brain_avg

# N4 bias field correction
N4BiasFieldCorrection -d 3 -i bold_mcf_brain_avg.nii.gz -o [bold_mcf_brain_avg_cor.nii.gz,bold_mcf_brain_avg_bias.nii.gz]

# QA/identify volumes to scrub
tr=$(fslval bold pixdim4)
fmriqa.py bold_mcf.nii.gz $tr

# remove intermediate files. bold_mcf could be used later, but
# assuming that all functional to structural registration will be done
# with the average image, and that motion correction, unwarping, and
# inter-run registration will all be done in one step later on
imrm bold_mcf bold_mcf_brain
