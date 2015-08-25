#!/bin/bash

# Archives dicoms in raw directory created by setup_subject.py. First creates
# compressed tar archive of the dicoms, then copies this tar files to the user's
# ranch archive directory. If the copy is successful, the raw directory and tar
# file are removed.
#
# Usage:   archive_raw.sh subject_id
# Example: archive_raw.sh bender_01
#
# MLM 2/2014
# NWM 8/2015

if [ $# -eq 0 ]
then
    echo "Usage:   archive_raw.sh subject_id"
    echo "Example: archive_raw.sh bender_01"
    echo "The STUDYDIR environment variable must be set."
    exit 1
fi

# subject id from input
sbjcode=$1

# subject code used by XNAT and directory where subject data is stored
sbjdir=${STUDYDIR}/${sbjcode}

# compress raw files
echo "Compressing raw files..."
tar czf ${sbjdir}/raw_${sbjcode}.tar.gz ${sbjdir}/raw

# create archive folder for experiment
ssh ${ARCHIVER} "mkdir -p ${expname}/raw"

# archive raw tar file
echo "Sending raw files to archive..."
scp ${sbjdir}/raw_${sbj}.tar.gz ${ARCHIVER}:${ARCHIVE}/${expname}/raw/.

# if scp successful, remove tar file and raw files
if [ $? -eq 0 ];
then
    echo "Deleting raw files..."
    rm ${sbjdir}/raw_${sbj}.tar.gz
    rm -rf ${sbjdir}/raw/
    ssh ${ARCHIVER} "chmod -R g+rwx ${ARCHIVE}/${expname}/raw"
    echo "Archive successful!"
else
    echo "*** ERROR: ARCHIVE FAILED ***"
fi
