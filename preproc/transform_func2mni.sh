#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage:   transform_func2mni.sh [-m] [-a anat] [-p postmask] input output subject"
    echo "Example: transform_func2mni.sh bender_01_mat_item_w2v_faces.nii.gz bender_01_mat_item_w2v_faces_mni.nii.gz bender_01"
    echo
    echo "After running reg_anat2mni.py, can use this to transform any image"
    echo "in functional space to template space (MNI or custom)."
    echo
    echo "input"
    echo "    Path to an image in the space of the reference functional scan."
    echo "    May be a single volume or a timeseries."
    echo
    echo "output"
    echo "    Filename for image to be written in template space."
    echo
    echo "subject"
    echo "    Subject code. Used to look up existing transforms. Must also"
    echo "    set the STUDYDIR environment variable as the base directory"
    echo "    for the study before calling."
    echo
    echo "OPTIONS"
    echo "-a"
    echo "    Suffix of anatomical image series that was used as reference"
    echo "    When registration was done to the template. Should also be the"
    echo "    image used as a target for registering the reference functional"
    echo "    scan to the anatomical. If not specified, no suffix will be"
    echo "    used."
    echo
    echo "-m"
    echo "    Input image is a mask. If set, will use nearest neighbor"
    echo "    interpolation. Otherwise, B-spline interpolation will be used."
    echo
    echo "-p"
    echo "    Post-mask to apply to the transformed image. This is useful"
    echo "    to remove very small values outside the brain that occur when"
    echo "    using B-spline interpolation."
    echo
    exit 1
fi

mask=0
refanat=""
postmask=""
while getopts ":a:mp:" opt; do
    case $opt in
	a)
	    refanat=$OPTARG
	    ;;
	m)
	    mask=1
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
anat2func=$sdir/anatomy/bbreg/transforms/highres-refvol
refvol=$sdir/BOLD/antsreg/data/refvol.nii.gz
if [ ! -f $refvol ]; then
    echo "Error: reference volume missing."
    exit 1
fi

# after reg_anat2mni.py, images in this directory will be the in the
# space of the template, regardless of the template used
reference=$sdir/anatomy/antsreg/data/orig.nii.gz
if [ ! -f $reference ]; then
    echo "Error: anatomical reference image missing."
    exit 1
fi

# make sure anat to func transformation is available in old ants format
if [ ! -f ${anat2func}.txt ]; then
    if [ ! -f ${anat2func}.mat ]; then
	echo "Error: anatomical to functional registration missing."
	exit 1
    fi

    c3d_affine_tool -ref $refvol -src $sdir/anatomy/orig${refanat}.nii.gz ${anat2func}.mat -fsl2ras -oitk ${anat2func}.txt
fi

# transform input from functional to template space
if [ $mask = 1 ]; then
    interp=NearestNeighbor
else
    interp=BSpline
fi

orig2temp_warp=$sdir/anatomy/antsreg/transforms/orig-template_Warp.nii.gz
orig2temp=$sdir/anatomy/antsreg/transforms/orig-template_Affine.txt
if [ ! -f $orig2temp_warp ]; then
    echo "Error: Warp file missing."
    exit 1
fi
if [ ! -f $orig2temp ]; then
    echo "Error: Affine file missing."
    exit 1
fi

ntp=$(fslval $input dim4)
if [ $ntp -gt 1 ]; then
    antsApplyTransforms -d 3 -e 3 -i $input -o $output -r $reference -n $interp -t $orig2temp_warp -t $orig2temp -t [${anat2func}.txt,1]
else
    antsApplyTransforms -d 3 -i $input -o $output -r $reference -n $interp -t $orig2temp_warp -t $orig2temp -t [${anat2func}.txt,1]
fi

# mask voxels outside the template
if [ -n "$postmask" ]; then
    if [ ! -f $postmask ]; then
	echo "Error: mask not found: $postmask"
	exit 1
    fi
    fslmaths $output -mas $postmask $output
fi