#!/bin/bash

# Backs up dicoms in raw directory created by setup_subject.py. First
# creates compressed tar archive of the dicoms, then copies this tar
# files to the user's ranch archive directory. The user should then
# delete the raw files to conserve space.
#
# MLM 2/2014
# NWM 8/2015

if [ $# -eq 0 ]
then
    echo "Usage:   backup_raw.sh raw_dir study subject"
    echo "Example: backup_raw.sh /corral-repl/utexas/prestonlab/bender/raw/bender_26 bender bender_26"
    exit 1
fi

if [ -u $ARCHIVER ]; then
    ARCHIVER=ranch.tacc.utexas.edu
fi
if [ -u $ARCHIVE ]; then
    ARCHIVE=$HOME
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

# if scp successful, remove tar file
if [ $? -eq 0 ]; then
    echo "Deleting local tar file..."
    rm ${src}

    echo "Changing file permissions to make group accessible..."
    ssh ${ARCHIVER} "chmod -R g+rwx ${ARCHIVE}/${study}/raw"
    echo "Archive appears to have been successful."
    echo "Please check the transfer and delete the local copy of raw files."
else
    echo "*** ERROR: ARCHIVE FAILED ***"
fi
