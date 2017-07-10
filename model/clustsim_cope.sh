#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 gfeatdir mask outname [subjids]"
    exit 1
fi

gfeatdir=$1
mask=$2
outname=$3
if [ $# -lt 4 ]; then
    subjids=$SUBJIDS
else
    subjids=$4
fi

sids=$(echo $subjids | tr ':' ' ')
copedir=$gfeatdir/cope1.feat

# directory for randomise results and related
if [ ! -d $copedir ]; then
    echo "Input cope directory does not exist: $copedir"
    exit 1
fi
if [ ! -f $mask ]; then
    echo "Mask file does not exist: $mask"
    exit 1
fi

rdir=$gfeatdir/${outname}.sim
while [ -d $rdir ]; do
    rdir=${rdir}+
done

mkdir -p $rdir
cd $rdir

# concatenate all subject COPEs
imcp $mask mask

#echo "Determining voxelwise p-values using randomise..."
#randomise -i cope1_allsubj -o cope1 -m mask -1 -n 10000 -x --uncorrp > /dev/null

# make z-stat image with higher=more significant
#fslmaths cope1_vox_p_tstat1 -ptoz -mul -1 zstat1

# just copy over z-stat image from feat
echo "Copying voxelwise p-values from FEAT..."
imcp $copedir/stats/zstat1 .

if [ $(hostname | cut -c 1-3) = nid ]; then
    # assume running on a compute node on LS5; take advantage of all
    # threads (multithreading allows twice the number of cores)
    export OMP_NUM_THREADS=48
fi

echo "Estimating smoothness within mask using 3dFWHMx on residuals..."
imln $copedir/stats/res4d res4d
rm -f acf*
3dFWHMx -mask mask.nii.gz -acf acf -input res4d.nii.gz -out acf_vol > acf_smoothness

echo "Estimating null max cluster size within mask using 3dClustSim..."
acfpar=$(tail -n 1 < acf_smoothness | awk '{ print $1,$2,$3 }')
3dClustSim -mask mask.nii.gz -acf $acfpar -iter 2000 -nodec -prefix clustsim
#fwhm=$(head -n 1 < acf_smoothness | awk '{ print $4 }')
#3dClustSim -mask mask.nii.gz -fwhm $fwhm -iter 2000 -nodec -prefix clustsim
cfile=clustsim.NN3_1sided.1D # NN3 corresponds to connectivity 26
clust_extent=$(grep '^ 0.01' < $cfile | awk '{ print $3 }')
echo "Minimum cluster extent: $clust_extent"
echo $clust_extent > clust_thresh

echo "Calculating significant clusters..."
imcp $copedir/stats/cope1 cope1
fslmaths zstat1 -mas mask thresh_zstat1
imcp $copedir/example_func .
cp $FSLDIR/etc/luts/ramp.gif ramp.gif

# report corrected clusters
cluster -i thresh_zstat1 -c cope1 -t 2.3 --minextent=$clust_extent --othresh=thresh_zstat1 -o cluster_mask_zstat1 --connectivity=26 --mm --olmax=lmax_zstat1_std.txt --scalarname=Z > cluster_zstat1_std.txt

cluster2html . cluster_zstat1 -std
range=$(fslstats thresh_zstat1 -l 0.0001 -R 2>/dev/null)
low=$(echo $range | awk '{print $1}')
high=$(echo $range | awk '{print $2}')
echo "Rendering using zmin=$low zmax=$high"

overlay 1 0 example_func -a thresh_zstat1 $low $high rendered_thresh_zstat1
slicer rendered_thresh_zstat1 -S 2 750 rendered_thresh_zstat1.png

# report uncorrected clusters
fslmaths zstat1 -mas mask mask_zstat1
cluster -i mask_zstat1 -c cope1 -t 2.3 --othresh=thresh_uncorr_zstat1 -o cluster_mask_uncorr_zstat1 --olmax=lmax_uncorr_zstat1_std.txt --connectivity=26 --mm --scalarname=Z > cluster_uncorr_zstat1_std.txt

cluster2html . cluster_uncorr_zstat1 -std
range=$(fslstats thresh_uncorr_zstat1 -l 0.0001 -R 2>/dev/null)
low=$(echo $range | awk '{print $1}')
high=$(echo $range | awk '{print $2}')
echo "Rendering using zmin=$low zmax=$high"

overlay 1 0 example_func -a thresh_uncorr_zstat1 $low $high rendered_thresh_uncorr_zstat1
slicer rendered_thresh_uncorr_zstat1 -S 2 750 rendered_thresh_uncorr_zstat1.png
