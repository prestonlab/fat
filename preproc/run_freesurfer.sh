#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: run_freesurfer.sh subject"
    exit 1
fi

if [ -u $STUDYDIR ]; then
    echo "STUDYDIR unset; quitting."
    exit 1
fi

subject=$1
subjdir=$STUDYDIR/$subject

if [ ! -f ${subjdir}/anatomy/highres.nii.gz ]; then
    echo "ERROR: Highres file not found."
    exit 1
fi

# delete existing freesurfer results
fsdir=${subjdir}/anatomy/${subject}
if [ -d $fsdir ]; then
    rm -rf $fsdir
fi

source $FREESURFER_HOME/SetUpFreeSurfer.sh
recon-all -s ${subject} -sd ${subjdir}/anatomy/ \
	  -i ${subjdir}/anatomy/highres.nii.gz -all
