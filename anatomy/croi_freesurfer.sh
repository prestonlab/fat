#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Create files for standard cortical ROIs based on Freesurfer"
    echo
    echo "Usage:"
    echo "croi_freesurfer.sh [parcfile] [outdir]"
    echo
    echo "Inputs:"
    echo "parcfile   path to Freesurfer aparc+aseg.nii.gz file"
    echo "outdir     directory in which to save ROI files"
    echo
    echo "See $FREESURFER_HOME/FreeSurferColorLUT.txt for all ROI"
    echo "codes and full ROI names. Cortical ROIs are 1XXX (left)"
    echo "and 2XXX (right)."
    echo
    exit 1
fi

parcfile=$1
outdir=$2

if [ ! -f ${parcfile} ]
then
    echo "Input parcel file does not exist: ${parcfile}" 1>&2
    exit 1
fi

if [ ! -d ${outdir} ]
then
    echo "Output directory does not exist: ${outdir}" 1>&2
    exit 1
fi

if [ ! -e ${outdir}/parcels.nii.gz ]; then
    cp ${parcfile} ${outdir}/parcels.nii.gz
fi

fscroi $parcfile $outdir 2 cac
fscroi $parcfile $outdir 3 cmf
fscroi $parcfile $outdir 5 cun
fscroi $parcfile $outdir 6 erc
fscroi $parcfile $outdir 7 fus
fscroi $parcfile $outdir 8 ip
fscroi $parcfile $outdir 9 it
fscroi $parcfile $outdir 10 imc
fscroi $parcfile $outdir 11 lo
fscroi $parcfile $outdir 12 lofc
fscroi $parcfile $outdir 13 ling
fscroi $parcfile $outdir 14 mofc
fscroi $parcfile $outdir 15 mt
fscroi $parcfile $outdir 16 phc
fscroi $parcfile $outdir 17 paracent
fscroi $parcfile $outdir 18 oper
fscroi $parcfile $outdir 19 orbi
fscroi $parcfile $outdir 20 tria
fscroi $parcfile $outdir 21 peric
fscroi $parcfile $outdir 22 postcent
fscroi $parcfile $outdir 23 pc
fscroi $parcfile $outdir 24 precent
fscroi $parcfile $outdir 25 precun
fscroi $parcfile $outdir 26 rac
fscroi $parcfile $outdir 27 rmf
fscroi $parcfile $outdir 28 sf
fscroi $parcfile $outdir 29 sp
fscroi $parcfile $outdir 30 st
fscroi $parcfile $outdir 31 supram
fscroi $parcfile $outdir 32 fpo
fscroi $parcfile $outdir 33 tpo
fscroi $parcfile $outdir 34 tt
fscroi $parcfile $outdir 35 insula
