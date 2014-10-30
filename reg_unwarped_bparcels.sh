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

# use nearest-neighbor interpolation for anatomical labels
flirt -v -ref ${epiregdir}/refvol_unwarp.nii.gz \
      -in ${anatdir}/aparc+aseg.nii.gz \
      -applyxfm -init ${epiregdir}/epireg_inv.mat -interp nearestneighbour \
      -out ${unwarpdir}/aparc+aseg.nii.gz >> $log

