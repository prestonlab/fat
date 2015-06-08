#!/bin/bash

# Usage: >./check_volumecounts.sh <experiment directory> <subject directory>

if [ $# -lt 2 ]
then
    echo "Usage: check_volumentcounts.sh <experiment directory> <subject directory>"
    echo "    e.g., check_volumentcounts.sh $CORRALDIR/coupling coupling_01"
    exit 1
fi

# subject directory
sbjdir=${1}/${2}

echo "Volume counts for $2 in `basename $1`"

# anatomies
for volname in highres inplane coronal coronal_mean
do
    vol=`ls ${sbjdir}/anatomy/*${volname}*.nii.gz 2>/dev/null`
    if [ $? -eq 0 ]
    then
        dim1=`fslval $vol dim1`
        dim2=`fslval $vol dim2`
        dim3=`fslval $vol dim3`
        dim4=`fslval $vol dim4`
        dim5=`fslval $vol pixdim1`
        dim6=`fslval $vol pixdim2`
        dim7=`fslval $vol pixdim3`
        printf "%s - size: %i x %i x %i, voxel dim (mm): %.2f x %.2f x %.2f, volumes: %i \n" $volname $dim1 $dim2 $dim3 $dim5 $dim6 $dim7 $dim4
    fi
done
    
# functional
for fdir in `ls -d ${sbjdir}/BOLD/*`
do
    vol=`ls ${fdir}/bold.nii.gz 2>/dev/null`
    if [ $? -eq 0 ]
    then
        dim1=`fslval $vol dim1`
        dim2=`fslval $vol dim2`
        dim3=`fslval $vol dim3`
        dim4=`fslval $vol dim4`
        dim5=`fslval $vol pixdim1`
        dim6=`fslval $vol pixdim2`
        dim7=`fslval $vol pixdim3`
        funcname=`basename $fdir`
        printf "%s - size: %i x %i x %i, voxel dim (mm): %.2f x %.2f x %.2f, volumes: %i \n" $funcname $dim1 $dim2 $dim3 $dim5 $dim6 $dim7 $dim4
    fi
done

# DTI
vol=`ls ${sbjdir}/DTI/DTI_1.nii.gz 2>/dev/null`
if [ $? -eq 0 ]
then
    dim1=`fslval $vol dim1`
    dim2=`fslval $vol dim2`
    dim3=`fslval $vol dim3`
    dim4=`fslval $vol dim4`
    dim5=`fslval $vol pixdim1`
    dim6=`fslval $vol pixdim2`
    dim7=`fslval $vol pixdim3`
    printf "DTI - size: %i x %i x %i, voxel dim (mm): %.2f x %.2f x %.2f, volumes: %i \n" $dim1 $dim2 $dim3 $dim5 $dim6 $dim7 $dim4
fi
