#!/bin/bash

featdir=$1

if cd $featdir; then
    rm -f filtered_func_data.nii.gz
    rm -f stats/res4d.nii.gz
    rm -f stats/pe*.nii.gz
    rm -f stats/tstat*.nii.gz
    rm -f stats/zstat*.nii.gz
fi
