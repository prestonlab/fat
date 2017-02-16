#!/bin/bash

template_dir=$1
image_prefix=$2

if [ ! -d $template_dir ]; then
    echo "Template directory does not exist."
    exit 1
fi
cd $template_dir

files=$(ls ${image_prefix}*.nii.gz | tr '\n' ' ')

nj=$(echo $files | wc -w)
if [ $nj -gt 24 ]; then
    nj=24
fi
init=${template_dir}/init_template.nii.gz

echo "running buildtemplateparallel.sh"
pd=$(pwd -P)
echo "pwd: $pd" 
echo "threads: $nj"
echo "init: $init"
echo "files: $files"

if [ ! -f $init ]; then
    # build an initial template using rigid, then affine, alignment
    buildtemplateparallel.sh -d 3 -o init_ -c 2 -i 3 -j $nj -r 1 -m 1x0x0 $files
fi

# use full deformable registration
buildtemplateparallel.sh -d 3 -o gp_ -c 2 -i 10 -j $nj -z $init $files
