#!/bin/bash

BASEDIR='/corral-repl/utexas/prestonlab'
STUDYNAME="taccboot"
SUBNUM=$1
SUBCODE=iceman_${SUBNUM}
SUBDIR=$BASEDIR/$STUDYNAME/$SUBCODE

BATCHDIR=$BASEDIR/$STUDYNAME/batch
SCRIPTDIR=$BATCHDIR/launchscripts

# cleanup subject directory
echo "cleanup..."
$BATCHDIR/cleanup_subject.sh $SUBNUM
wait

# launch freesurfer cluster
echo "freesurfer..."
$BATCHDIR/run_freesurfer.sh $SUBNUM
wait

# register functionals
echo "register functionals..."
launch $BATCHDIR/reg_bold.sh $SUBNUM -r 04:00:00 -n reg_bold_$SUBNUM
wait

