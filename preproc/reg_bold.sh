#!/bin/bash
#
# reg_bold.sh
#
# After each run has been motion corrected using setup_subject.py,
# this will align each run.
#
# usage: reg_bold.sh bolddir runcode runs refrun
# e.g.:  reg_bold.sh /corral-repl/utexas/prestonlab/prex/prex_01/BOLD pre "1 2 3 4 5 6 7 8" 1

export FSLOUTPUTTYPE=NIFTI_GZ

BOLDDIR=$1
RUNCODE=$2
RUNS=$3
REFRUN=$4

if [ ! -d $BOLDDIR ]
then
    echo "BOLD directory does not exist: $BOLDDIR"
    exit 1
fi

mkdir -p ${BOLDDIR}/antsreg
mkdir -p ${BOLDDIR}/antsreg/data
mkdir -p ${BOLDDIR}/antsreg/transforms

# log file
NOW=$(date +"%m%d%Y")
ANTSFILE=${BOLDDIR}/antsreg/log_reg_bold_${NOW}_ants.txt

if [ -e $ANTSFILE ]
then
    rm $ANTSFILE
fi

# reference volume
REFTS=${BOLDDIR}/${RUNCODE}_${REFRUN}/bold_mcf_brain.nii.gz
REFVOL=${BOLDDIR}/${RUNCODE}_${REFRUN}/bold_mcf_brain_vol1.nii.gz
fslroi $REFTS $REFVOL 0 1
cp $REFVOL ${BOLDDIR}/antsreg/data/refvol.nii.gz

# append info to the lab log file
echo "Performing coregistration of all BOLD runs using reg_bold.sh." >> $ANTSFILE
echo "Each run should already be aligned to the first image in that run." >> $ANTSFILE
echo "Aligning each run to reference volume ($RUNCODE $REFRUN first image)." >> $ANTSFILE
echo "Image directory: $BOLDDIR" >> $ANTSFILE
echo "Implementation: ANTS, affine transformations" >> $ANTSFILE

# align each run
for r in $RUNS
do
    # extract the first image from this run
    RUNTS=${BOLDDIR}/${RUNCODE}_${r}/bold_mcf_brain.nii.gz
    RUNVOL1=${BOLDDIR}/${RUNCODE}_${r}/bold_mcf_brain_vol1.nii.gz
    fslroi $RUNTS $RUNVOL1 0 1

    # set the output files of transformation info and transformed data
    RUNPARBASE=${BOLDDIR}/antsreg/transforms/${RUNCODE}_${r}_to_${RUNCODE}_1_
    RUNOUT=${BOLDDIR}/antsreg/data/${RUNCODE}_${r}_bold_mcf_brain.nii.gz

    if [ $r == 1 ]
    then
	# this is the reference; no need to transform
	cp $REFTS $RUNOUT
    else
	# calculate the affine transformation
	echo "ANTS 3 -m MI[$REFVOL,$RUNVOL1,1,32] -o $RUNPARBASE --rigid-affine true -i 0" >> $ANTSFILE
	ANTS 3 -m MI[$REFVOL,$RUNVOL1,1,32] -o $RUNPARBASE \
	    --rigid-affine true -i 0 >> $ANTSFILE
	
	# apply the transformation to the whole time series
	echo "WarpTimeSeriesImageMultiTransform 4 $RUNTS $RUNOUT -R $RUNVOL1 ${RUNPARBASE}Affine.txt" >> $ANTSFILE
	WarpTimeSeriesImageMultiTransform 4 $RUNTS $RUNOUT \
	    -R $RUNVOL1 ${RUNPARBASE}Affine.txt >> $ANTSFILE
    fi
done

