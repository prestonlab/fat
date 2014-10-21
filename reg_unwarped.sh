#!/bin/bash

basedir=$1
subject=$2

subjdir=${basedir}/${subject}
epiregdir=${subjdir}/BOLD/fm
anatdir=${basedir}/${subject}/anatomy
unwarpdir=${anatdir}/bbreg/data/unwarp

if [ ! -d ${epiregdir} ]; then
    echo "epi_reg directory ${epiregdir} does not exist. Run epi_reg first." >&2
    exit 1
fi

mkdir -p ${subjdir}/logs
mkdir -p ${unwarpdir}
now=$(date +"%m%d%Y")
log=${basedir}/${subject}/logs/reg_unwarped_${now}.log

if [ -e $log ]; then
    rm $log
fi

# map structurals to unwarped functional space
echo "Tranforming structural images to unwarped functional space..." >> $log
flirt -v -ref ${epiregdir}/refvol_unwarp.nii.gz -in ${anatdir}/orig.nii.gz \
    -applyxfm -init ${epiregdir}/epireg_inv.mat -out ${unwarpdir}/orig.nii.gz >> $log

flirt -v -ref ${epiregdir}/refvol_unwarp.nii.gz -in ${anatdir}/orig_brain.nii.gz \
    -applyxfm -init ${epiregdir}/epireg_inv.mat -out ${unwarpdir}/orig_brain.nii.gz >> $log

# use nearest-neighbor interpolation for anatomical labels
flirt -v -ref ${epiregdir}/refvol_unwarp.nii.gz -in ${anatdir}/aparc+aseg.nii.gz \
    -applyxfm -init ${epiregdir}/epireg_inv.mat -interp nearestneighbour \
    -out ${unwarpdir}/aparc+aseg.nii.gz >> $log

flirt -v -ref ${epiregdir}/refvol_unwarp.nii.gz -in ${anatdir}/brainmask.nii.gz \
    -applyxfm -init ${epiregdir}/epireg_inv.mat -interp nearestneighbour \
    -out ${unwarpdir}/brainmask.nii.gz >> $log

