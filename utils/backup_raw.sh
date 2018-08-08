#!/bin/bash

if [ $# -eq 0 ]; then
    cat <<EOF
Usage:   backup_raw.sh subject_dicom_dir studytype study subject
Example: backup_raw.sh remind_202a fmri remind remind_202a
EOF
    exit 1
fi

DATADIR=/corral-repl/utexas/prestonlab

raw_dir="$1"
studytype="$2"
study="$3"
subject="$4"

if [ ! -d $raw_dir ]; then
    echo "Raw directory does not exist: ${raw_dir}. Quitting..."
    exit 2
fi

# determine directories
parent_dir=$(dirname $raw_dir)
src=$parent_dir/raw_${subject}.tar.gz
destdir=$DATADIR/raw/$studytype/$study

mkdir -p $destdir
dest=$DATADIR/raw/$studytype/$study/raw_${subject}.tar.gz

# sanity checks
isvalid=false
for file in $raw_dir/*; do
    if [ -d $file ]; then
	# this is a directory
	# check for any dicoms
	# if good, set isvalid to true and break
    fi
done

# is this a valid directory with dicom subdirectories?
#this is a test please disregard

# compress raw files
if [ ! -f $src ]; then
    echo "Compressing raw files in $src..."
fi

# archive the raw tar file
if [ -f $src ] || tar czf $src $raw_dir; then
    echo "Sending raw data to corral raw directory..."
    mv $src $dest
else
    echo "Error: problem compressing data."
    exit 1
fi

# set permissions for raw tar file
chmod 775 $dest
