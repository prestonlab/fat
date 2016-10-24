#!/bin/bash

if [ $# -lt 4 ]; then
    echo "Usage:   run_ica_aroma.sh subject runid model regs"
    echo "Example: run_ica_aroma.sh bender_01 loc_1 loc_subcat '1,3,5,7,9,11'"
    exit 1
fi

subject=$1
runid=$2
model=$3
regs="$4"

sdir=$STUDYDIR/$subject
if [ ! -d $sdir ]; then
    echo "subject directory does not exist: $sdir"
    exit 1
fi

infile=$sdir/BOLD/antsreg/data/${runid}.nii.gz
outfile=$sdir/BOLD/antsreg/data/${runid}_den.nii.gz
if [ ! -e $infile ]; then
    echo "input file does not exist: $infile"
    exit 1
fi

# temp directory for ICA-AROMA
ardir=$sdir/BOLD/antsreg/data/${runid}_aroma

# delete old directory if necessary
cd $sdir/BOLD/antsreg/data
if [ -d ${runid}_aroma ]; then
    rm -rf ${runid}_aroma
fi
mkdir -p $ardir

# smooth with 6 mm FWHM kernel (6 / 2.35482004503 ~ 2.548)
echo "smoothing input functional data at: $(date)"
boldfile=$ardir/smoothed_func_data.nii.gz
#fslmaths $infile -s 2.548 $boldfile
smooth_susan $infile 4 $boldfile

# use the brain mask created from freesurfer output
echo "creating mask at: $(date)"
maskfile=$ardir/brain_mask.nii.gz
fslmaths $sdir/anatomy/bbreg/data/orig_brain.nii.gz -thr 1 -bin $maskfile

# gray matter
#gray=$ardir/gray.nii.gz
#fslmaths $sdir/anatomy/bbreg/data/aparc+aseg.nii.gz -thr 1000 -bin $gray

# run ICA AROMA, without regfilt
echo "running ICA-AROMA at: $(date)"
ICA_AROMA.py -o $ardir -i $boldfile \
	     -mc $sdir/BOLD/$runid/bold_mcf.par \
	     -a $sdir/anatomy/antsreg/transforms/orig-template_Affine.txt \
	     -b $sdir/anatomy/bbreg/transforms/refvol-orig_Affine.txt \
	     -w $sdir/anatomy/antsreg/transforms/orig-template_Warp.nii.gz \
	     -m $maskfile \
	     -p ants -den no

# remove temp smoothed functional data (only major contribution to
# disk usage)
#rm $boldfile

# smooth with smaller kernel (used larger kernal for ICA-AROMA to
# match their training data)
#fslmaths $infile -s 1.4438 $outfile
#smooth_susan $infile 4 $outfile

# create a new regressor matrix from the ICA components and the task
# model (task regressors put on end so IC numbers still work). Task
# model should be set to have no high-pass filter, since it will be
# used before high-pass filtering is done on the data
model_root=$STUDYDIR/batch/glm/$model/fsf/${model}_${subject}_${runid}
if [ ! -e ${model_root}.fsf ]; then
    echo "Task model not found. Quitting."
    exit 1
fi
if [ ! -e ${model_root}.mat ]; then
    feat_model $model_root
fi
regsfile=$ardir/regs.txt
cat_ica_model_regs.py $ardir/melodic.ica/melodic_mix \
		      ${model_root}.mat $regsfile "$regs"

# regress out bad components (partial regression; remove variance that
# is unique to those components and does not share variance with the
# hopefully good remaining components)
echo "running fsl_regfilt at: $(date)"
ics=$(<$ardir/classified_motion_ICs.txt)
fsl_regfilt -i $boldfile -d $regsfile -f "$ics" -o $outfile

# temporal filtering of denoised data
echo "running high-pass filtering at: $(date)"
fslmaths $outfile -bptf 32 -1 $outfile
