#!/bin/bash

model=$1
ntrial=$2

modeldir=${STUDYDIR}/batch/model/${model}
for subjid in $SUBJIDS; do
    echo "Processing ${subjid}..."
    # temporary subject directory for individual beta images
    outdir=${modeldir}/beta/${subjid}
    mkdir -p ${outdir}

    allrunfiles=""
    for runid in $RUNIDS; do
	echo ${runid}
	# check for fsf file for this run
	fsfbase=${modeldir}/fsf/${model}_${subjid}_${runid}
	if [ ! -e ${fsfbase}.fsf ]; then
	    echo "fsf file ${fsfbase}.fsf does not exist." >&2
	    exit 1
	fi

	# use a feat utility to create the design matrix
	feat_model ${fsfbase}
	if [ ! -e ${fsfbase}.mat ]; then
	    echo "Problem running feat_model." >&2
	    exit 2
	fi

	# obtain individual trial estimates
	betaseries_simple.py ${fsfbase} ${outdir} ${ntrial}
	if [ ! -e ${outdir}/ev000.nii.gz ]; then
	    echo "Problem creating beta series." >&2
	    exit 3
	fi

	# create a 4D file with estimates for every stimulus in the run
	runfile=${outdir}/${subjid}_${runid}.nii.gz
	fslmerge -t ${runfile} ${outdir}/ev*.nii.gz
	rm ${outdir}/ev*.nii.gz
	allrunfiles="${allrunfiles} ${runfile}"
    done

    # merge all runs into one file
    fslmerge -t ${modeldir}/beta/${subjid}_beta.nii.gz ${allrunfiles}

    rm ${allrunfiles}
    rmdir ${outdir}
done

