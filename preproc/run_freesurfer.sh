#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: run_freesurfer.sh subject"
    exit 1
fi

subject=$1
subjdir=$STUDYDIR/$subject

cmd=". ${FREESURFER_HOME}/SetUpFreeSurfer.sh; recon-all -s ${subject} -sd ${subjdir}/anatomy/ -i ${subjdir}/anatomy/highres.nii.gz -all"

name=fs_$subject
file=${name}.sh
prep_job.sh "$cmd" $file

cd $BATCHDIR
launch -s $file -r 20:00:00 -c gcc -n $name -e 1way -j ANTS -q normal

