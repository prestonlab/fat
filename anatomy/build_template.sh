#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage:   build_template.sh template_dir image_prefix"
    echo "Example: build_template.sh $WORK/bender/gptemplate/highres_brain_all highres_brain_bender"
    echo
    echo "template_dir"
    echo "    path to directory with source images. Template will be made"
    echo "    in this directory."
    echo
    echo "image_prefix"
    echo "    files in the template_dir that start with this will be"
    echo "    included in making the template."
    echo
    echo "Images will first be rigidly aligned to make an initial target."
    echo "Then affine registration will be used to refine the template."
    echo "Finally, nonlinear registration will be used to make the final"
    echo "template."
    echo
    echo "Will attempt to distribute processes over 24 cores locally."
    echo
    exit 1
fi

template_dir=$1
image_prefix=$2

if [ ! -d $template_dir ]; then
    echo "Template directory does not exist."
    exit 1
fi
cd $template_dir

files=$(ls ${image_prefix}*.nii.gz | tr '\n' ' ')

nj=$(echo $files | wc -w)
if [ $nj -gt 8 ]; then
    nj=8
fi

init=${template_dir}/init_template.nii.gz

echo "running buildtemplateparallel.sh"
pd=$(pwd -P)
echo "pwd: $pd" 
echo "threads: $nj"
echo "init: $init"
echo "files: $files"

# make sure the parallel processes don't step on one another
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=3

if [ ! -f $init ]; then
    # build an initial template using rigid, then affine, alignment
    buildtemplateparallel.sh -d 3 -o init_ -c 2 -i 3 -j $nj -r 1 -m 1x0x0 $files
fi

# use full deformable registration
buildtemplateparallel.sh -d 3 -o gp_ -c 2 -i 10 -j $nj -z $init $files
