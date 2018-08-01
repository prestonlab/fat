#!/bin/bash

if [ $# -lt 2 ]; then
    cat <<EOF
Run group-level analysis of searchlight results.

Usage: zstat_randomise.sh [-s studydir] [-n nperm] [-m mask] [-a anat] [-i interp] [-f filename] filepath subjids

filepath
    Relative path to searchlight results. For example, if a participant's 
    results are in e.g. \$STUDYDIR/mistr_02/rsa/my_searchlight, then the
    relative path is rsa/my_searchlight.

subjids
    List of subject identifiers, separated by colons. For example:
    mistr_02:mistr_04:mistr_05

OPTIONS
-s STUDYDIR
    Path to main directory for the study to process.

-n NPERM
    Number of permutations to use for randomise (default 2000).

-m MASK
    Path to a mask to use for the group-level analysis.

-a ANAT
    Suffix for anatomical image used for template registration for
    each subject.

-i INTERP
    Type of interpolation to use (default is Linear).

-f FILENAME
    Searchlight results for each subjects are expected to be in:
    \$STUDYDIR/\$subject/\$filepath/FILENAME.nii.gz. Default is: zstat.

EOF
    exit 1
fi

interp=Linear
mask=""
n_perm=2000
studydir=$STUDYDIR
anat=""
filename="zstat"
overwrite=false
while getopts ":s:a:i:n:m:f:o" opt; do
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
	f)
	    filename=$OPTARG
	    ;;
	o)
	    overwrite=true
	    ;;
    esac
done
shift $((OPTIND-1))

filepath=$1
subjects=$2

echo "Options:"
echo "filepath: $filepath"
echo "filename: $filename"
echo "nperm:    $n_perm"
echo "interp:   $interp"
echo "mask:     $mask"

outdir=$studydir/batch/$filepath
mkdir -p $outdir

echo "Transforming z-statistic images to template space..."
files=""
for subject in $(echo $subjects | tr ':' ' '); do
    zstat_subj=$studydir/$subject/$filepath/${filename}.nii.gz
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
    if [ -n "$interp" ]; then
	flags+=("-n $interp")
    fi
    zstat_std=$studydir/$subject/$filepath/zstat_std.nii.gz
    if [ ! -f $zstat_std -o $overwrite = true ]; then
	echo "transform_func2mni.sh ${flags[@]} $zstat_subj $zstat_std $subject"
	transform_func2mni.sh "${flags[@]}" $zstat_subj $zstat_std $subject
    else
	echo "$zstat_std exists."
    fi

    if [ -z "$files" ]; then
	files=$zstat_std
    else
	files="$files $zstat_std"
    fi
done

echo "Concatenating files..."
zstat_cat=$outdir/zstat_all.nii.gz
if [ ! -f $zstat_cat -o $overwrite = true ]; then
    fslmerge -t $zstat_cat $files
fi

echo "Running randomise..."
flags=()
if [ -n "$mask" ]; then
    flags+=("-m $mask")
fi
randomise -i $zstat_cat ${flags[@]} -o $outdir/zstat -1 -n $n_perm -x --uncorrp
