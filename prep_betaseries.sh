#!/bin/bash

studydir=$1
subjid=$2
runids="$3"
hpf=$4
smooth=$5

subjdir=${studydir}/${subjid}
fmdir=${subjdir}/BOLD/fm

if [ ! -d ${fmdir} ]; then
    echo "fieldmap unwarping directory ${fmdir} does not exist. Unwarp functional data first." >&2
    exit 1
fi

mkdir -p ${subjdir}/logs
now=$(date +"%m%d%Y")
log=${studydir}/${subjid}/logs/prep_betaseries_${now}.log
rm -f ${log}

for runid in $runids
do
    echo "Starting run $runid." >> $log

    # filter and smooth
    fslmaths ${fmdir}/${runid}_bold_mcf_brain_unwarp.nii.gz -bptf ${hpf} -1 -s ${smooth} ${fmdir}/${runid}_bold_mcf_brain_unwarp_filtsm.nii.gz >> $log
done

