#!/bin/bash

# Usage: >./taccboot_setup_subject.sh 101
#
# taccboot_setup_subject.sh performs two setup_subject.py calls for the specified subject number
#    1. pulls raw dicoms from xnat and sets up directory structure for the subject
#    2. performs several preprocessing steps on the dicoms including:
#           - converting to nifti images
#           - motion correction            
#           - quality reports
#           - brain extraction on the function and inplane scans
#           - converting fieldmaps into usable format
#           - melodic ICA
#
# Two calls of setup_subject.py are required because pulling data from xnat
# requires interactively entering your username and password, something that
# can't be performed if this was run on the cluster. So, the first call just
# grabs the data. The second call is all of the preprocessing, thus it is 
# submitted to the cluster through a launch call.
#

# subject number ($1 is the first input from the command line call)
SUBNO=$1

# base directory where experiments are located on corral
BASEDIR='/corral-repl/utexas/prestonlab'

# name of the experiment
STUDYNAME='taccboot'

# code used for subjects when scanning (look on xnat website to check)
#    this defines the name of the subjects' directories e.g., in this case, 
#    subject 1's data will be placed in $BASEDIR/$STUDYNAME/iceman_01. 
#    If you don't like this, we will run a cleanup script later where 
#    subject directories can be renamed. 
SUBCODE=iceman_$SUBNO

# since we are using launch, we have to create launch scripts.
# I don't like random scripts cluttering up my batch folder,
# so this defines a directory where we can put the launch scripts
SCRIPTDIR=${BASEDIR}/$STUDYNAME/batch/launchscripts
mkdir -p $SCRIPTDIR

# path to setup_subject.py
SETUP_SUBJECT='/corral-repl/utexas/poldracklab/software_lonestar/local/bin/setup_subject.py'

# first call to grab the data from xnat (will ask for UT id/password)
$SETUP_SUBJECT --getdata --keepdata -o --studyname $STUDYNAME -s $SUBCODE -b $BASEDIR --xnat-project preston

# second call is put in a script file saved in $SCRIPTDIR
echo "$SETUP_SUBJECT -o --dcm2nii --motcorr --qa --betfunc --fm --melodic --keepdata --bet-inplane --studyname $STUDYNAME -b $BASEDIR -s $SUBCODE --mricrondir /corral-repl/utexas/prestonlab/software/" > $SCRIPTDIR/setup_${SUBNO}.sh

# the launch script needs to be executable
chmod +x $SCRIPTDIR/setup_${SUBNO}.sh

# change into the script directory (so the launch log output is also in the script directory) 
cd $SCRIPTDIR

# launch it (once running, this takes about 11 hours to finish)
launch -s setup_${SUBNO}.sh -r 12:00:00 -c gcc -n ${STUDYNAME}_setup_subject_${SUBNO} -j ANTS -m mack.michael@gmail.com
