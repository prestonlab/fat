#!/bin/bash

model=$1
betaname=$2
run=$3
subjects=$4

if [ $# -lt 4 ]; then
    echo "Usage: group_average_hrf.sh model betaname run subjects"
    exit 1
fi

pd=$(pwd -P)

betadir=$STUDYDIR/batch/glm/$model/$betaname
for subject in $(echo $subjects | tr ':' ' '); do
    subjdir=$betadir/$subject
    cd $subjdir

    # normalize so first volume is zero and the peak is one
    hrf_name=${model}_${subject}_${run}_hrfs
    fslroi $hrf_name ${hrf_name}_vol1 0 1
    fslmaths $hrf_name -sub ${hrf_name}_vol1 ${hrf_name}_bc
    fslmaths ${hrf_name}_bc -Tmax ${hrf_name}_max
    fslmaths ${hrf_name}_bc -div ${hrf_name}_max ${hrf_name}_norm

    # transform to standard space
    transform_func2mni.sh -n Linear -p $STUDYDIR/gptemplate/highres_brain_all/gp_template_mni_affine_mask.nii.gz ${hrf_name}_norm.nii.gz ${hrf_name}_std.nii.gz $subject

    # split volumes
    fslsplit ${hrf_name}_std $hrf_name -t
done

# get average across subjects for each volume
nvol=$(fslval $hrf_name dim4)
slice_files=""
for i in $(seq 0 $((nvol-1))); do
    # get file with this volume for each subject
    slice=$(printf '%04d' $i)
    files=""
    for subject in $(echo $subjects | tr ':' ' '); do
	hrf_slice=$betadir/$subject/${model}_${subject}_${run}_hrfs${slice}.nii.gz
	files="$files $hrf_slice"
    done

    # concatenate
    slice_cat=$betadir/${model}_${run}_hrfs${slice}.nii.gz
    if fslmerge -t $slice_cat $files; then
    	rm $files
    else
    	echo "Slice image merging failed."
    	exit 1
    fi

    # average over subjects
    slice_mean=$betadir/${model}_${run}_hrfs${slice}_mean.nii.gz
    if fslmaths $slice_cat -Tmean $slice_mean; then
	rm $slice_cat
    fi
    slice_files="$slice_files $slice_mean"
done

# merge averaged volumes into one image
time_cat=$betadir/${model}_${run}_hrfs.nii.gz
if fslmerge -t $time_cat $slice_files; then
    rm $slice_files
fi

cd $pd
