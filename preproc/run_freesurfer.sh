#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: run_freesurfer.sh [-f] [-o outname] subject nthreads"
    echo
    echo "Use highres anatomical image to run FreeSurfer standard"
    echo "reconstruction. Highres is expected to be in:"
    echo '$STUDYDIR/$subject/anatomy/highres.nii.gz'
    echo
    echo "nthreads is the number of parallel threads to use per"
    echo "hemisphere during processing."
    echo
    echo 'Results are saved in: $STUDYDIR/$subject/anatomy/$outname'
    echo
    echo "-f"
    echo "    Use a FLAIR image to refine the pial surface. Expected to"
    echo '    be in: $STUDYDIR/$subject/anatomy/flair.nii.gz'
    echo
    echo "-o outname"
    echo '    Set the name of the output directory. Default is $subject.'
    echo
    exit 1
fi

if [ -u $STUDYDIR ]; then
    echo "STUDYDIR unset; quitting."
    exit 1
fi

if [ ! -d $STUDYDIR ]; then
    echo "STUDYDIR does not exist; quitting."
    exit 1
fi

flair=false
while getopts ":o:f" opt; do
    case $opt in
	o)
	    outname=$OPTARG
	    ;;
	f)
	    flair=true
	    ;;
    esac
done
shift $((OPTIND-1))

subject=$1
nthreads=$2
subjdir=$STUDYDIR/$subject

if [ -z $outname ]; then
    outname=$subject
fi

if [ ! -f ${subjdir}/anatomy/highres.nii.gz ]; then
    echo "ERROR: Highres file not found."
    exit 1
fi

# delete existing freesurfer results
if [ -d ${subjdir}/anatomy/$outname ]; then
    cd ${subjdir}/anatomy
    rm -rf $outname
fi

source $FREESURFER_HOME/SetUpFreeSurfer.sh
if [ $flair = true ]; then
    if [ ! -e $subjdir/anatomy/flair.nii.gz ]; then
	echo "Error: flair image not found."
	exit 1
    fi
    recon-all -s ${outname} -sd ${subjdir}/anatomy/ \
	      -i ${subjdir}/anatomy/highres.nii.gz -all \
	      -FLAIR $subjdir/anatomy/flair.nii.gz -FLAIRpial \
	      -parallel -openmp $nthreads -itkthreads $nthreads
else
    recon-all -s ${outname} -sd ${subjdir}/anatomy/ \
	      -i ${subjdir}/anatomy/highres.nii.gz -all \
	      -parallel -openmp $nthreads -itkthreads $nthreads
fi
