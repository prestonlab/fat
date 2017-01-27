#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 [-bc] image1 image2 output"
    echo
    echo "Register and average two anatomical images."
    echo
    echo "will create a temporary directory called ${image1}_${image2}"
    echo "with intermediate images."
    echo "-b"
    echo "    run brain extraction on each image before registration."
    echo "    Final merged image will include the full head, but only"
    echo "    the brain is used for registration."
    echo "-n"
    echo "    number of threads to use for registration (default 1)."
    exit 1
fi

coronal=0
while getopts ':c:' opt; do
    case $opt in
	c)
	    coronal=1
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
echo "Intensity normalization..."
N4BiasFieldCorrection -i ${im1}.nii.gz -o ${im1}_cor.nii.gz
N4BiasFieldCorrection -i ${im2}.nii.gz -o ${im2}_cor.nii.gz
im1=${im1}_cor
im2=${im2}_cor

# extract the brain
echo "Brain extraction..."
if [ $coronal = 1 ]; then
    bet $im1 ${im1}_brain -f 0.01
    bet $im2 ${im2}_brain -f 0.01
else
    bet $im1 ${im1}_brain
    bet $im2 ${im2}_brain
fi
im1=${im1}_brain
im2=${im2}_brain

# calculate transform
echo "Registration..."
antsRegistration -d 3 -r [${im1}.nii.gz,${im2}.nii.gz,1] -t Rigid[0.1] -m MI[${im1}.nii.gz,${im2}.nii.gz,1,32,Regular,0.25] -c [1000x500x250x100,1e-6,10] -f 8x4x2x1 -s 3x2x1x0vox -n BSpline -w [0.005,0.995] -o im2-im1_

# apply transform to corrected, non-skull-stripped image
echo "Applying transformation..."
antsApplyTransforms -i im2_cor.nii.gz -o im2_cor_reg.nii.gz -r im1_cor.nii.gz -t im2-im1_0GenericAffine.mat -n BSpline

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
