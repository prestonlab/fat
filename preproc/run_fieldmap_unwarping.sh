#!/bin/bash

basedir=$1
subject=$2
runcode=$3
runs=$4
fugueopt=$5

subjdir=${basedir}/${subject}
epiregdir=${subjdir}/BOLD/fm

if [ ! -d ${epiregdir} ]; then
    echo "epi_reg directory ${epiregdir} does not exist. Run epi_reg first." >&2
    exit 1
fi

mkdir -p ${subjdir}/logs
now=$(date +"%m%d%Y")
log=${basedir}/${subject}/logs/unwarp_${now}.log

# fieldmap registered to the functional scans
fmapepi=${epiregdir}/epireg_fieldmaprads2epi.nii.gz
fmapepi_mask=${epiregdir}/epireg_fieldmaprads2epi_mask.nii.gz

# create mask for the fieldmap
fslmaths ${fmapepi} -abs -bin ${fmapepi_mask}

for r in $runs
do
    echo "Starting run $r." >> $log
    # 4D motion-corrected functional scan file for this run
    infile=${subjdir}/BOLD/antsreg/data/${runcode}_${r}_bold_mcf_brain.nii.gz

    # output to an unwarped 4D file
    outfile=${epiregdir}/${runcode}_${r}_bold_mcf_brain_unwarp.nii.gz

    # unwarp the functional data
    fugue --in=${infile} --loadfmap=${fmapepi} --mask=${fmapepi_mask} \
	--unwarp=${outfile} $fugueopt >> $log

    if [ $r == 1 ]
    then
	fslroi $outfile ${epiregdir}/refvol_unwarp.nii.gz 0 1
    fi
done

