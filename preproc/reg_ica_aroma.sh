#!/bin/bash

if [ $# -lt 4 ]; then
    echo "Restart ica aroma that errored out when reading in model."
    echo "Usage:   reg_ica_aroma.sh subject runid model regs"
    echo "Example: reg_ica_aroma.sh bender_01 loc_1 loc_subcat '1,3,5,7,9,11'"
    exit 1
fi

subject=$1
runid=$2
model=$3
regs="$4"

# temp directory for ICA-AROMA
sdir=$WORK/bender/$subject
ardir=$sdir/BOLD/antsreg/data/${runid}_aroma
boldfile=$ardir/smoothed_func_data.nii.gz
outfile=$sdir/BOLD/antsreg/data/${runid}_den.nii.gz

model_root=$WORK/bender/batch/glm/$model/fsf/${model}_${subject}_${runid}
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
