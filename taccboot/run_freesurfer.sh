#!/bin/bash

BASEDIR=$CORRALDIR
STUDYNAME='taccboot'
SCRIPTDIR=${BASEDIR}/$STUDYNAME/batch/launchscripts

sbj=$1
SUBCODE=iceman_${sbj}
SUBDIR=${BASEDIR}/${STUDYNAME}/${SUBCODE}

echo ". $FREESURFER_HOME/SetUpFreeSurfer.sh" > $SCRIPTDIR/freesurfer_${SUBCODE}.sh
echo "recon-all -s $SUBCODE -sd ${SUBDIR}/anatomy/ -i ${SUBDIR}/anatomy/highres.nii.gz -all" >> $SCRIPTDIR/freesurfer_${SUBCODE}.sh

chmod +x $SCRIPTDIR/freesurfer_${SUBCODE}.sh

cd $SCRIPTDIR
launch -s freesurfer_${SUBCODE}.sh -r 12:00:00 -n freesurfer_${SUBCODE} -c gcc -e 6way
