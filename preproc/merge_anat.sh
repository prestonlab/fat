#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 [-bc] image1 image2 output"
    echo
    echo "Register and average two anatomical images."
    echo
    echo "will create a temporary directory called ${image1}_${image2}"
    echo "with intermediate images."
    echo "-c"
    echo "    run bias field correction on each image before registration"
    echo "-b"
    echo "    run brain extraction on each image before registration."
    echo "    Final merged image will include the full head, but only"
    echo "    the brain is used for registration."
    exit 1
fi

bet=0
cor=0
while getopts ':bc' opt; do
    case $opt in
	b)
	    bet=1
	    ;;
	c)
	    cor=1
	    ;;
    esac
done

shift $((OPTIND-1))

im1=$1
im2=$2
out=$3

name1=$(basename $im1 | cut -d . -f 1)
name2=$(basename $im2 | cut -d . -f 1)
dname=${name1}_${name2}

mkdir -p $dname
imcp $im1 $dname/im1
imcp $im2 $dname/im2

pd=$(pwd)
cd $dname

im1=im1
im2=im2

# correct image intensity
if [ $cor = 1 ]; then
    echo "Intensity normalization..."
    N4BiasFieldCorrection -i ${im1}.nii.gz -o ${im1}_cor.nii.gz
    N4BiasFieldCorrection -i ${im2}.nii.gz -o ${im2}_cor.nii.gz
    im1=${im1}_cor
    im2=${im2}_cor
fi

# extract the brain
if [ $bet = 1 ]; then
    echo "Brain extraction..."
    bet $im1 ${im1}_brain
    bet $im2 ${im2}_brain
    im1=${im1}_brain
    im2=${im2}_brain
fi

# calculate transform
echo "Registration..."
antsRegistration -d 3 -r [${im1}.nii.gz,${im2}.nii.gz,1] -t Rigid[0.1] -m MI[${im1}.nii.gz,${im2}.nii.gz,1,32,Regular,0.25] -c [1000x500x250x100,1e-6,10] -f 8x4x2x1 -s 3x2x1x0vox -n BSpline -w [0.005,0.995] -o im2-im1_

# apply transform to corrected, non-skull-stripped image
echo "Applying transformation..."
if [ $cor = 1 ]; then
    antsApplyTransforms -i im2_cor.nii.gz -o im2_cor_reg.nii.gz -r im1_cor.nii.gz -t im2-im1_0GenericAffine.mat -n BSpline
    fslmaths im1_cor -add im2_cor_reg -div 2 im_merge
else
    antsApplyTransforms -i im2.nii.gz -o im2_reg.nii.gz -r im1.nii.gz -t im2-im1_0GenericAffine.mat -n BSpline
    fslmaths im1 -add im2_reg -div 2 im_merge
fi

# move merged image
cd $pd
immv $dname/im_merge $out
