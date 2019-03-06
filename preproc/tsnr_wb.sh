#!/bin/bash
if [ $# -lt 2 ]; then
echo "Usage: tsnr_wb.sh <input image> <subject>"
echo "Example: tsnr_wb.sh /absolute/path/rest_23_denoise No_001"
echo "Description: Calculates the temporal snr for whole brain "
echo "             and saves in corresponding bold dir."
exit 1
fi

input=$1
subject=$2

# check for existence
if [ ! -f $input ]; then
echo "ERROR: Input file not found."
exit 1
fi

# input and output directories
parentdir=$(dirname $input)
image=$(basename $input .nii.gz)

cd $parentdir
fslmaths $image -Tmean -mas mask tmp_avg
fslmaths $image -Tstd -mas mask tmp_std
fslmaths tmp_avg -div tmp_std ${image}_tsnr_wb
rm tmp_*
