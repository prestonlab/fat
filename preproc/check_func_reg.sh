#!/bin/bash
#
# check_func_reg.sh
#
# Create a visualization of image registration for quality control of
# alignment of functional scans.
#
# usage: check_func_reg.sh bolddir runcode runs refrun
# e.g.:  check_func_reg.sh prex/prex_01/BOLD pre "1 2 3 4 5 6 7 8" 1

BOLDDIR=$1
RUNCODE=$2
RUNS=$3
REFRUN=$4

CHECKDIR=$BOLDDIR/antsreg/checks
mkdir -p $CHECKDIR

# functional volume all others are aligned to
REFVOL=${BOLDDIR}/${RUNCODE}_${REFRUN}/bold_mcf_brain_vol1.nii.gz

FILES=""
for r in $RUNS
do
    if [ r != $REFRUN ]
    then
	# get first volume from the aligned time series
	RUNTS=${BOLDDIR}/antsreg/data/${RUNCODE}_${r}_bold_mcf_brain.nii.gz
	RUNVOL1=${BOLDDIR}/antsreg/data/${RUNCODE}_${r}_bold_mcf_brain_vol1.nii.gz
	if [ -e $RUNTS ]
	then
	    fslroi $RUNTS $RUNVOL1 0 1

	    # create slice images and concatenate them horizontally
	    OUT=func${r}2func${REFRUN}.png
	    reg_slice_check.sh $REFVOL $RUNVOL1 $CHECKDIR $OUT
	    FILES="$FILES $CHECKDIR/$OUT"
	fi
    fi
done

# create an image with all runs
C=""
for f in $FILES
do
    C="$C - $f"
done

C=`echo $C | cut -c 3-`
pngappend $C $CHECKDIR/func_reg.png
rm $FILES

