#!/bin/bash
#
# reg_slice_check.sh
#
# Create an image with slices to check the quality of registration of
# two images.
#
# usage: reg_slice_check.sh image1 image2 pngdir pngout
# e.g.:  reg_slice_check.sh anatomy/antsreg/data/funcspace/orig.nii.gz BOLD/pre_1/bold_mcf_brain_vol1.nii.gz anatomy/antsreg/checks orig2func1.png

DIST=".35 .45 .55 .65"
AXIS="x y z"

N=0
FILES=""
for a in $AXIS
do
    for d in $DIST
    do
	N=$((N+1))
	slicer $1 $2 -s 2 -$a $d $3/tempslice$N.png
	FILES="$FILES $3/tempslice$N.png"
    done
done

C=""
for f in $FILES
do
    C="$C + $f"
done

C=`echo $C | cut -c 3-`
pngappend $C $3/$4
rm $FILES
