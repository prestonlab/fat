#!/bin/bash

rdir=$1

cd $rdir

# get cluster extent from 3dClustSim
cfile=clustsim.NN3_2sided.1D # NN3 corresponds to connectivity 26
clust_extent=$(grep '^ 0.01' < $cfile | awk '{ print $3 }')

# get clusters using correct per-voxel threshold (p=0.01: 2.3, p=0.001: 3.09)
cluster -i thresh_zstat1 -c cope1 -t 2.3 --minextent=$clust_extent --othresh=thresh_zstat1 -o cluster_mask_zstat1 --connectivity=26 --mm --olmax=lmax_zstat1_std.txt --scalarname=Z > cluster_zstat1_std.txt
cluster2html . cluster_zstat1 -std

# redo overlay image
range=$(fslstats thresh_zstat1 -l 0.0001 -R 2>/dev/null)
low=$(echo $range | awk '{print $1}')
high=$(echo $range | awk '{print $2}')
echo "Rendering using zmin=$low zmax=$high"

overlay 1 0 example_func -a thresh_zstat1 $low $high rendered_thresh_zstat1
slicer rendered_thresh_zstat1 -S 2 750 rendered_thresh_zstat1.png
