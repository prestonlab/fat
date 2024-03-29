#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 model copeno mask outname [subjids]"
    echo "Assumes you are accessing cope1 within the .gfeat directory."
    exit 1
fi

model=$1
copeno=$2
mask=$3
outname=$4
if [ $# -lt 5 ]; then
    subjids=$SUBJIDS
else
    subjids=$5
fi

sids=$(echo $subjids | tr ':' ' ')

# directory for randomise results and related
lev3=$STUDYDIR/batch/glm/$model/level3/cope${copeno}.gfeat
rdir=$lev3/${outname}.rand
while [ -d $rdir ]; do
    rdir=${rdir}+
done

fdir=$lev3/cope1.feat
mkdir -p $rdir
cd $rdir

# concatenate all subject COPEs
if [ ! -e cope1_allsubj.nii.gz ]; then
    command="fslmerge -t cope1_allsubj"
    for id in $sids; do
	file=$STUDYDIR/$id/model/$model/level2.gfeat/cope${copeno}.feat/stats/cope1.nii.gz
	command="$command $file"
    done
    $command
fi
imcp $mask mask

echo "Determining voxelwise p-values using randomise..."
randomise -i cope1_allsubj -o cope1 -m mask -1 -n 10000 -x --uncorrp > /dev/null

# make z-stat image with higher=more significant
fslmaths cope1_vox_p_tstat1 -ptoz -mul -1 zstat1

if [ $(hostname | cut -c 1-3) = nid ]; then
    # assume running on a compute node on LS5; take advantage of all
    # threads (although logical cores is supposed to be 64, only 48
    # seem to actually get used)
    export OMP_NUM_THREADS=48
fi

echo "Estimating smoothness using 3dFWHMx..."
imln $fdir/stats/res4d res4d
rm -f acf*
3dFWHMx -mask mask.nii.gz -acf acf -input res4d.nii.gz -out acf_vol > acf_smoothness

echo "Estimating null max cluster size using 3dClustSim..."
acfpar=$(tail -n 1 < acf_smoothness | awk '{ print $1,$2,$3 }')
3dClustSim -mask mask.nii.gz -acf $acfpar -iter 2000 -nodec -prefix clustsim
#fwhm=$(head -n 1 < acf_smoothness | awk '{ print $4 }')
#3dClustSim -mask mask.nii.gz -fwhm $fwhm -iter 2000 -nodec -prefix clustsim
cfile=clustsim.NN3_2sided.1D # NN3 corresponds to connectivity 26
clust_extent=$(grep '^ 0.01' < $cfile | awk '{ print $3 }')
echo "Minimum cluster extent: $clust_extent"
echo $clust_extent > clust_thresh

echo "Calculating significant clusters..."
imcp $fdir/stats/cope1 cope1
fslmaths zstat1 -mas mask thresh_zstat1

cluster -i thresh_zstat1 -c cope1 -t 2.3 --connectivity=26 --mm --scalarname=Z > cluster_uncorr_zstat1_std.txt
cluster -i thresh_zstat1 -c cope1 -t 2.3 --minextent=$clust_extent --othresh=thresh_zstat1 -o cluster_mask_zstat1 --connectivity=26 --mm --olmax=lmax_zstat1_std.txt --scalarname=Z > cluster_zstat1_std.txt

cluster2html . cluster_zstat1 -std
range=$(fslstats thresh_zstat1 -l 0.0001 -R 2>/dev/null)
low=$(echo $range | awk '{print $1}')
high=$(echo $range | awk '{print $2}')
echo "Rendering using zmin=$low zmax=$high"

imcp $fdir/example_func .
overlay 1 0 example_func -a thresh_zstat1 $low $high rendered_thresh_zstat1
slicer rendered_thresh_zstat1 -S 2 750 rendered_thresh_zstat1.png
cp $FSLDIR/etc/luts/ramp.gif ramp.gif
