#!/bin/bash

# Backs up dicoms in raw directory created by setup_subject.py. First
# creates compressed tar archive of the dicoms, then copies this tar
# files to the user's ranch archive directory. The user should then
# delete the raw files to conserve space.
#
# Usage:   backup_raw.sh subject_id
# Example: backup_raw.sh bender_01
#
# MLM 2/2014
# NWM 8/2015

if [ $# -eq 0 ]
then
    echo "Usage:   backup_raw.sh raw_dir study subject"
    echo "Example: backup_raw.sh /corral-repl/utexas/prestonlab/bender/bender_01/raw/bender_01 bender bender_01"
    exit 1
fi

raw_dir=$1
study=$2
subject=$3

if [ ! -d ${raw_dir} ]; then
    echo "Raw directory does not exist: ${raw_dir}. Quitting..."
    exit 2
fi

# determine directories
parent_dir=`dirname ${raw_dir}`
src=${parent_dir}/raw_${subject}.tar.gz
dest=${ARCHIVE}/${study}/raw/raw_${subject}.tar.gz

# check if the file for this session already exists
if (ssh $ARCHIVER "test -f ${dest}"); then
    echo "Archive file ${dest} already exists on $ARCHIVER. Quitting..."
    exit 3
fi

# compress raw files
if [ ! -f ${src} ]; then
    echo "Compressing raw files in ${raw_dir}..."
    tar czf ${src} ${raw_dir}
fi

# create archive folder for session
ssh ${ARCHIVER} "mkdir -p ${ARCHIVE}/${study}/raw"

# archive the raw tar file
echo "Sending raw files to archive..."
scp ${src} ${ARCHIVER}:${dest}

# if scp successful, remove tar file and raw files
if [ $? -eq 0 ]; then
    echo "Deleting local tar file..."
    rm ${src}

    echo "Changing file permissions to make group accessible..."
    ssh ${ARCHIVER} "chmod -R g+rwx ${ARCHIVE}/${study}/raw"
    echo "Archive successful!"
else
    echo "*** ERROR: ARCHIVE FAILED ***"
fi
