#!/bin/bash

# Usage: >./cleanup_subject.sh 101
#
# This script cleans up a subject directory. Some of what setup_subject.py creates is
# not needed for every study (e.g., DTI directories) or the naming convention used is
# not what we (ok, I) want. This makes it how I want it. Also, it finishes up some other
# random preprocessing including prepping the fieldmaps and creating directories for 
# GLM and MVPA analyses.

# subject number from input (e.g., 101)
SUBNO=$1

# the base directory on corral-repl
BASEDIR=$CORRALDIR

# name of the experiment
EXPNAME=taccboot

# subject code used by XNAT and directory where subject data is stored
SUBCODE=iceman_$SUBNO
SUBDIR=$BASEDIR/$EXPNAME/$SUBCODE

# redirect script output to log file in subject directory
#mkdir -p logs
#exec > $SUBDIR/logs/cleanup_subject.log 2>&1
#set -x

# remove DTI directory (no DTI collected this experiment)
rm -r $SUBDIR/DTI

# add onset directory to model directory
mkdir -p $SUBDIR/model/onsets

# create mvpa directory
mkdir -p $SUBDIR/mvpa

# move inplane
inplane=`ls $SUBDIR/anatomy/other/T2*inplane*`
mv $inplane $SUBDIR/anatomy/inplane.nii.gz

# move highres
highres=`ls $SUBDIR/anatomy/highres*.nii.gz`
mv $highres $SUBDIR/anatomy/highres.nii.gz
comprage=`ls $SUBDIR/anatomy/comprage*`
mv $comprage $SUBDIR/anatomy/other/.

# rename and bet fieldmap magnitude image
fmmag=$SUBDIR/fieldmap/fieldmaps004a2001.nii.gz
cp $fmmag $SUBDIR/fieldmap/fieldmap_mag.nii.gz
bet $SUBDIR/fieldmap/fieldmap_mag $SUBDIR/fieldmap/fieldmap_mag_brain -R -m

# rename and bet fieldmap phase image
fmphase=$SUBDIR/fieldmap/fieldmaps005a2001.nii.gz
cp $fmphase $SUBDIR/fieldmap/fieldmap_phase.nii.gz

# move original mag and phase fieldmap images to orig directory
mkdir -p $SUBDIR/fieldmap/orig
mv $SUBDIR/fieldmap/*001.nii.gz $SUBDIR/fieldmap/orig/.

# prepare fieldmap for FEAT GLM analyses
fsl_prepare_fieldmap SIEMENS $SUBDIR/fieldmap/fieldmap_phase $SUBDIR/fieldmap/fieldmap_mag_brain $SUBDIR/fieldmap/fieldmap_rads 2.46
