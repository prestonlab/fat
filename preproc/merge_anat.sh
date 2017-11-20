#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: merge_anat.sh [-cm] moving fixed output"
    echo
    echo "Register and average two anatomical images. Output will"
    echo "be in the space of the fixed image."
    echo
    echo 'will create a temporary directory called ${moving}_${fixed}'
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

mov=$1
fix=$2
out=$3

mdir=$(dirname $mov)

mov_name=$(basename $mov | cut -d . -f 1)
fix_name=$(basename $fix | cut -d . -f 1)
dname=$mdir/${mov_name}_${fix_name}

mkdir -p $dname
imcp $mov $dname/mov
imcp $fix $dname/fix

pd=$(pwd)
cd $dname

if [ $register = 1 ]; then
    # correct image intensity
    echo "Intensity normalization..."
    N4BiasFieldCorrection -i mov.nii.gz -o mov_cor.nii.gz
    N4BiasFieldCorrection -i fix.nii.gz -o fix_cor.nii.gz

    if [ $coronal = 1 ]; then
	# coronal
	echo "Rigid registration using brain only..."
	bet mov_cor mov_cor_brain -f 0.01
	bet fix_cor fix_cor_brain -f 0.01
	antsRegistrationSyN.sh -d 3 -m mov_cor_brain.nii.gz -f fix_cor_brain.nii.gz -o mov-fix_ -n $ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS -t r
	antsApplyTransforms -i mov_cor.nii.gz -o mov_cor_reg.nii.gz -r fix_cor.nii.gz -t mov-fix_0GenericAffine.mat -n BSpline
    else
	# mprage (took place between days; may be deformed)
	echo "Deformable registration using whole head..."
	antsRegistrationSyN.sh -d 3 -m mov_cor.nii.gz -f fix_cor.nii.gz -o mov-fix_ -n $ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS -t s
	antsApplyTransforms -i mov_cor.nii.gz -o mov_cor_reg.nii.gz -r fix_cor.nii.gz -t mov-fix_1Warp.nii.gz -t mov-fix_0GenericAffine.mat -n BSpline
    fi
    rm mov-fix_Warped.nii.gz
else
    imcp mov mov_cor_reg
    imcp fix fix_cor
fi

# calculate mask
for file in fix_cor mov_cor_reg; do
    int_2_98=$(fslstats $file -p 2 -p 98)
    int2=$(echo $int_2_98 | awk '{print $1}')
    int98=$(echo $int_2_98 | awk '{print $2}')
    thresh=$(python -c "print $int2 + 0.1 * ($int98 - $int2)")
    fslmaths $file -thr $thresh -bin ${file}_mask
done
fslmaths fix_cor_mask -mul mov_cor_reg_mask mask

# normalize global intensity between images so they are equally weighted
for file in fix_cor mov_cor_reg; do
    fslmaths $file -mas mask ${file}_thresh
    fslmaths ${file}_thresh -inm 1000 ${file}_norm
done

# average
fslmaths fix_cor_norm -add mov_cor_reg_norm -div 2 im_merge

# move merged image
cd $pd
immv $dname/im_merge $out
