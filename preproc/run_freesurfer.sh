#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: run_freesurfer.sh subject nthreads"
    exit 1
fi

if [ -u $STUDYDIR ]; then
    echo "STUDYDIR unset; quitting."
    exit 1
fi

if [ ! -d $STUDYDIR ]; then
    echo "STUDYDIR does not exist; quitting."
    exit 1
fi

subject=$1
nthreads=$2
subjdir=$STUDYDIR/$subject

if [ ! -f ${subjdir}/anatomy/highres.nii.gz ]; then
    echo "ERROR: Highres file not found."
    exit 1
fi

# delete existing freesurfer results
if [ -d ${subjdir}/anatomy/${subject} ]; then
    cd ${subjdir}/anatomy
    rm -rf ${subject}
fi

source $FREESURFER_HOME/SetUpFreeSurfer.sh
recon-all -s ${subject} -sd ${subjdir}/anatomy/ \
	  -i ${subjdir}/anatomy/highres.nii.gz -all \
	  -parallel -openmp $nthreads -itkthreads $nthreads 
