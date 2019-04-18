#!/bin/bash

if [ $# -lt 1 ]; then
echo
echo "  Description: runs fmriqa on bold directory outputing a number of"
echo "               different files. See README.md in fmriqa directory "
echo "               for more information on each of the files.         "
echo 
echo "  Input:  full path to bold dir "
echo
exit 1
fi

bolddir=$1

# navigate
cd $bolddir

# get corrected
applywarp -i bold -o bold_mcf -r bold_cor_mcf_avg --premat=bold_cor_mcf.cat --interp=spline --paddingsize=1

# rerun
tr=$(fslval bold pixdim4)
fmriqa.py bold_mcf.nii.gz $tr

# remove bold_mcf
imrm bold_mcf
