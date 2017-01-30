#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 [-cm] image1 image2 output"
    echo
    echo "Register and average two anatomical images."
    echo
    echo "will create a temporary directory called ${image1}_${image2}"
    echo "with intermediate images."
    echo "-c"
    echo "    images are highres coronal partial images. Will use"
    echo "    modified brain extraction when creating images for"
    echo "    registration."
    echo "-m"
    echo "    merge only; do not co-register the images."
    exit 1
fi

coronal=0
register=1
while getopts ':cm' opt; do
    case $opt in
	c)
	    coronal=1
	    ;;
	m)
	    register=0
	    ;;
    esac
done

shift $((OPTIND-1))

im1=$1
im2=$2
out=$3

mdir=$(dirname $im1)

name1=$(basename $im1 | cut -d . -f 1)
name2=$(basename $im2 | cut -d . -f 1)
dname=$mdir/${name1}_${name2}

mkdir -p $dname
imcp $im1 $dname/im1
imcp $im2 $dname/im2

pd=$(pwd)
cd $dname

if [ $register = 1 ]; then
    # correct image intensity
    echo "Intensity normalization..."
    N4BiasFieldCorrection -i im1.nii.gz -o im1_cor.nii.gz
    N4BiasFieldCorrection -i im2.nii.gz -o im2_cor.nii.gz

    # extract the brain
    echo "Brain extraction..."
    if [ $coronal = 1 ]; then
	bet im1_cor im1_cor_brain -f 0.01
	bet im2_cor im2_cor_brain -f 0.01
    else
	bet im1_cor im1_cor_brain
	bet im2_cor im2_cor_brain
    fi

    # calculate transform
    echo "Registration..."
    antsRegistration -d 3 -r [im1_cor_brain.nii.gz,im2_cor_brain.nii.gz,1] -t Rigid[0.1] -m MI[im1_cor_brain.nii.gz,im2_cor_brain.nii.gz,1,32,Regular,0.25] -c [1000x500x250x100,1e-6,10] -f 8x4x2x1 -s 3x2x1x0vox -n BSpline -w [0.005,0.995] -o im2-im1_

    # apply transform to corrected, non-skull-stripped image
    echo "Applying transformation..."
    antsApplyTransforms -i im2_cor.nii.gz -o im2_cor_reg.nii.gz -r im1_cor.nii.gz -t im2-im1_0GenericAffine.mat -n BSpline
else
    imcp im1 im1_cor
    imcp im2 im2_cor_reg
fi

# calculate mask
for file in im1_cor im2_cor_reg; do
    int_2_98=$(fslstats $file -p 2 -p 98)
    int2=$(echo $int_2_98 | awk '{print $1}')
    int98=$(echo $int_2_98 | awk '{print $2}')
    thresh=$(python -c "print $int2 + 0.1 * ($int98 - $int2)")
    fslmaths $file -thr $thresh -bin ${file}_mask
done
fslmaths im1_cor_mask -mul im2_cor_reg_mask mask

# normalize global intensity between images so they are equally weighted
for file in im1_cor im2_cor_reg; do
    fslmaths $file -mas mask ${file}_thresh
    fslmaths ${file}_thresh -inm 1000 ${file}_norm
done

# average
fslmaths im1_cor_norm -add im2_cor_reg_norm -div 2 im_merge

# move merged image
cd $pd
immv $dname/im_merge $out
