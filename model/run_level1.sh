#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage:   run_level1.sh model subjid runid"
    echo "Example: run_level1.sh prex_cond bender_01 loc_1"
    exit 1
fi

model=$1
subjid=$2
runid=$3

glmdir=${STUDYDIR}/batch/glm
modeldir=${glmdir}/${model}

# get the FSF file for this subject and run
fsf=${STUDYDIR}/batch/glm/${model}/fsf/${model}_${subjid}_${runid}.fsf
if [ ! -e $fsf ]; then
    echo "FSF file not found: ${fsf}. Exiting."
    exit 1
fi

# determine whether any of the onset files are empty; if they are,
# then Feat won't be able to run, so just exit
onset_files=`cat $fsf | grep 'set fmri(custom[0-9]*) \".*.txt\"' | cut -d \" -f 2`
for file in $onset_files; do
    if [ ! -s $file ]; then
	echo "Onset file is empty: $file. Cannot run Feat. Exiting."
	exit 1
    fi
done

# prepare the subject's model directory
subjmodeldir=${STUDYDIR}/${subjid}/model/${model}
mkdir -p $subjmodeldir

if [ ! -d $subjmodeldir ]; then
    echo "Problem creating subject model dir $subjmodeldir. Exiting."
    exit 1
fi

cd $subjmodeldir
rm -rf ${runid}*.feat

cd ${STUDYDIR}

# unset the SGE_ROOT variable. This indicates to FSL that it should
# not attempt to submit jobs
export SGE_ROOT=""

# run Feat
featdir=${subjmodeldir}/{$runid}.feat
if [ -d $featdir ]; then
    echo "The FEAT directory $featdir already exists. Quitting."
    exit 1
fi

feat ${fsf}
