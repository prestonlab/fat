#!/bin/bash

if [ $# -lt 3 ]; then
    cat <<EOF
Usage:   transform_mni2anat.sh [-n interp] [-a anat] [-p postmask] input output subject
Example: transform_mni2anat.sh -n NearestNeighbor contrast_group_mask.nii.gz bender_01_contrast_mask.nii.gz bender_01

After running reg_anat2mni.py, can use this to transform any image in
template space (MNI or custom) to anatomical space.

input
    Path to an image in the space of the template. May be a single volume
    or a timeseries.

output
    Path to an image to be written, in anatomical space.

subject
    Subject code. Used to look up existing transforms. Must also set the
    STUDYDIR environment variable as the base directory for the study
    before calling.

OPTIONS
-a
    Suffix of anatomical image series that was used as a reference when
    registration was done to the template. If not specified, no suffix 
    will be used.

-n
    Type of interpolation to use. May be: BSpline (default), Linear,
    NearestNeighbor, or any other types supported by antsApplyTransforms.

-p
    Post-mask to apply to the transformed image. This is useful
    to remove very small values outside the brain that occur when
    using B-spline interpolation.

EOF
    exit 1
fi

interp=BSpline
refanat=""
postmask=""
while getopts ":a:n:p:" opt; do
    case $opt in
	a)
	    refanat=$OPTARG
	    ;;
	n)
	    interp=$OPTARG
	    ;;
	p)
	    postmask=$OPTARG
	    ;;
    esac
done
shift $((OPTIND-1))

input=$1
output=$2
subject=$3

if [ ! -f $input ]; then
    echo "Error: input volume missing."
    exit 1
fi

sdir=${STUDYDIR}/${subject}
ref=$sdir/anatomy/orig_brain${refanat}.nii.gz

# check anat to template transform files
temp2orig_warp=$sdir/anatomy/antsreg/transforms/orig-template_InverseWarp.nii.gz
orig2temp=$sdir/anatomy/antsreg/transforms/orig-template_Affine.txt
if [ ! -f $temp2orig_warp ]; then
    echo "Error: Warp file missing."
    exit 1
fi
if [ ! -f $orig2temp ]; then
    echo "Error: Affine file missing."
    exit 1
fi

# run transformation
ntp=$(fslval $input dim4)
if [ $ntp -gt 1 ]; then
    antsApplyTransforms -d 3 -e 3 -i $input -o $output -r $ref -n $interp -t [${orig2temp},1] -t $temp2orig_warp
else
    antsApplyTransforms -d 3 -i $input -o $output -r $ref -n $interp -t [${orig2temp},1] -t $temp2orig_warp
fi
