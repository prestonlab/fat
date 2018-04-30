#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: zstat_randomise.sh [-s studydir] [-i interp] [-n nperm] [-m mask] [-a anat] filepath subjids"
    exit 1
fi

interp=BSpline
mask=""
n_perm=2000
studydir=$STUDYDIR
anat=""
while getopts ":s:a:i:n:m:" opt; do
    case $opt in
	s)
	    studydir=$OPTARG
	    ;;
	a)
	    anat=$OPTARG
	    ;;
	i)
	    interp=$OPTARG
	    ;;
	n)
	    n_perm=$OPTARG
	    ;;
	m)
	    mask=$OPTARG
	    ;;
    esac
done
shift $((OPTIND-1))

filepath=$1
subjects=$2

echo "Options:"
echo "filepath: $filepath"
echo "nperm:    $n_perm"
echo "interp:   $interp"
echo "mask:     $mask"

outdir=$studydir/batch/$filepath
mkdir -p $outdir

echo "Transforming z-statistic images to template space..."
files=""
for subject in $(echo $subjects | tr ':' ' '); do
    zstat_subj=$studydir/$subject/$filepath/zstat.nii.gz
    if [ ! -f $zstat_subj ]; then
	echo "Error: file not found: $zstat_subj"
	exit 1
    fi

    flags=()
    if [ -n "$mask" ]; then
	flags+=("-p $mask")
    fi
    if [ -n "$anat" ]; then
	flags+=("-a $anat")
    fi
    zstat_std=$studydir/$subject/$filepath/zstat_std.nii.gz
    if [ ! -f $zstat_std ]; then
	echo "transform_func2mni.sh ${flags[@]} $zstat_subj $zstat_std $subject"
	transform_func2mni.sh "${flags[@]}" $zstat_subj $zstat_std $subject
    fi

    if [ -z "$files" ]; then
	files=$zstat_std
    else
	files="$files $zstat_std"
    fi
done

echo "Concatenating files..."
zstat_cat=$outdir/zstat_all.nii.gz
if [ ! -f $zstat_cat ]; then
    fslmerge -t $zstat_cat $files
fi

echo "Running randomise..."
flags=()
if [ -n "$mask" ]; then
    flags+=("-m $mask")
fi
randomise -i $zstat_cat ${flags[@]} -o $outdir/zstat -1 -n $n_perm -x --uncorrp
