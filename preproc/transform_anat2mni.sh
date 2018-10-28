#!/bin/bash

if [ $# -lt 3 ]; then
    cat <<EOF
Usage:   transform_anat2mni.sh [-n interp] [-p postmask] input output subject
Example: transform_anat2mni.sh -n Linear bender_01_mat_item_w2v_faces.nii.gz bender_01_mat_item_w2v_faces_mni.nii.gz bender_01

After running reg_anat2mni.py, can use this to transform any image
in the reference anatomical space to template space (MNI or custom).

input
    Path to an image in the space of the reference anatomical scan.
    May be a single volume or a timeseries.

output
    Filename for image to be written in template space.

subject
    Subject code. Used to look up existing transforms. Must also
    set the STUDYDIR environment variable as the base directory
    for the study before calling.

OPTIONS
-n interp
    Type of interpolation to use. May be: Linear, BSpline,
    NearestNeighbor, MultiLabel, or any other types supported by
    antsApplyTransforms.  Default is Linear.

-p postmask
    Post-mask to apply to the transformed image. This is useful
    to remove very small values outside the brain that occur when
    using B-spline interpolation.

EOF
    exit 1
fi

interp="Linear"
postmask=""
while getopts ":n:p:" opt; do
    case $opt in
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
    echo "Error: input volume missing: $input"
    exit 1
fi

sdir=${STUDYDIR}/${subject}

# after reg_anat2mni.py, images in this directory will be the in the
# space of the template, regardless of the template used
reference=$sdir/anatomy/antsreg/data/orig.nii.gz
if [ ! -f $reference ]; then
    echo "Error: anatomical reference image missing: $reference"
    exit 1
fi

orig2temp_warp=$sdir/anatomy/antsreg/transforms/orig-template_Warp.nii.gz
orig2temp=$sdir/anatomy/antsreg/transforms/orig-template_Affine.txt
if [ ! -f $orig2temp_warp ]; then
    echo "Error: warp file missing: $orig2temp_warp"
    exit 1
fi
if [ ! -f $orig2temp ]; then
    echo "Error: affine file missing: $orig2temp"
    exit 1
fi

ntp=$(fslval $input dim4)
if [ $ntp -gt 1 ]; then
    antsApplyTransforms -d 3 -e 3 -i $input -o $output -r $reference -n $interp -t $orig2temp_warp -t $orig2temp
else
    antsApplyTransforms -d 3 -i $input -o $output -r $reference -n $interp -t $orig2temp_warp -t $orig2temp
fi

# mask voxels outside the template
if [ -n "$postmask" ]; then
    if [ ! -f $postmask ]; then
	echo "Error: mask not found: $postmask"
	exit 1
    fi
    fslmaths $output -mas $postmask $output
fi
