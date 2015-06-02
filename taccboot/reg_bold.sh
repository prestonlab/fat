#!/bin/bash

export FSLOUTPUTTYPE=NIFTI_GZ

expname='taccboot'
sbj=$1

runs="6 13" # functional scan numbers
ref=6 # use first scan as reference image

subdir=$CORRALDIR/$expname/iceman_${sbj}

# redirect logging into subject log directory
#exec > ${subdir}/logs/reg_bold.log 2>&1
#cat /corral-repl/utexas/prestonlab/software/prestonlab_logo2.txt
#now=$(date +"%m%d%Y")
#echo "reg_bold.sh: ${now}"
set -x


# create registration directories
mkdir -p $subdir/BOLD/antsreg
mkdir -p $subdir/BOLD/antsreg/data
mkdir -p $subdir/BOLD/antsreg/transforms

# make log file for ants output
antsfile="$subdir/logs/reg_bold_ants.log"

# extract the first volume from each run to calculate the transformations
for r in $runs
do    
    funcdir=`ls -d $subdir/BOLD/functional_*${r}`
    dimx=`fslval $funcdir/bold_mcf_brain.nii.gz dim1`
    dimy=`fslval $funcdir/bold_mcf_brain.nii.gz dim2`
    dimz=`fslval $funcdir/bold_mcf_brain.nii.gz dim3`
    fslroi $funcdir/bold_mcf_brain.nii.gz $funcdir/bold_mcf_brain_vol1.nii.gz 0 $dimx 0 $dimy 0 $dimz 0 1
done


# Calculate and apply relevant transformations
refvol=`ls $subdir/BOLD/functional_*${ref}/*vol1.nii.gz`

for r in $runs # for each of the runs we input...
do
    funcdir=`ls -d $subdir/BOLD/functional_*${r}`
    
    # except the reference
    if [ $r != $ref ]
	then	
	    # calculate the affine transformation to the reference image
    	ANTS 3 -m MI[$refvol,$funcdir/bold_mcf_brain_vol1.nii.gz,1,32] -o $subdir/BOLD/antsreg/transforms/func${r}2func${ref}_ --rigid-affine true -i 0 >>"$antsfile"

    	# then apply it to the whole time series
	    WarpTimeSeriesImageMultiTransform 4 $funcdir/bold_mcf_brain.nii.gz $subdir/BOLD/antsreg/data/functional_${r}_bold_mcf_brain.nii.gz -R $refvol $subdir/BOLD/antsreg/transforms/func${r}2func${ref}_Affine.txt >> "$antsfile"
    fi

    if [ $r == $ref ] 
	then
    	cp $funcdir/bold_mcf_brain.nii.gz $subdir/BOLD/antsreg/data/functional_${r}_bold_mcf_brain.nii.gz
    fi

done
