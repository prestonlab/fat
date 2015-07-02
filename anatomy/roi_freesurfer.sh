#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Create files for standard ROIs based on Freesurfer"
    echo
    echo "Usage:"
    echo "roi_freesurfer.sh [parcfile] [outdir]"
    echo
    echo "Inputs:"
    echo "parcfile   path to Freesurfer aparc+aseg.nii.gz file"
    echo "outdir     directory in which to save ROI files"
    echo
    exit 1
fi

parcfile=$1
outdir=$2

if [ ! -f ${parcfile} ]
then
    echo "Input parcel file does not exist: ${parcfile}" 1>&2
    exit 1
fi

if [ ! -d ${outdir} ]
then
    echo "Output directory does not exist: ${outdir}" 1>&2
    exit 1
fi

cp ${parcfile} ${outdir}/parcels.nii.gz
cd ${outdir}

# erc   entorhinal cortex
# fus   fusiform gyrus
# it    inferior temporal cortex
# phc   parahippocampal cortex
# hip   hippocampus
# lofc  lateral orbitofrontal cortex
# lo    lateral occipital
# oper  pars opercularis
# tria  pars triangularis
# orbi  pars orbitalis
# mofc  medial orbitofrontal cortex
# fropo frontal pole
# sfg   superior frontal gyrus
# rmfg  rostral middle frontal gyrus
# cmfg  caudal middle frontal gyrus
# vidc  ventral diencephalon

fslmaths parcels.nii.gz -thr 1006 -uthr 1006 -bin l_erc.nii.gz
fslmaths parcels.nii.gz -thr 2006 -uthr 2006 -bin r_erc.nii.gz
fslmaths parcels.nii.gz -thr 1007 -uthr 1007 -bin l_fus.nii.gz
fslmaths parcels.nii.gz -thr 2007 -uthr 2007 -bin r_fus.nii.gz
fslmaths parcels.nii.gz -thr 1009 -uthr 1009 -bin l_it.nii.gz
fslmaths parcels.nii.gz -thr 2009 -uthr 2009 -bin r_it.nii.gz
fslmaths parcels.nii.gz -thr 1016 -uthr 1016 -bin l_phc.nii.gz
fslmaths parcels.nii.gz -thr 2016 -uthr 2016 -bin r_phc.nii.gz
fslmaths parcels.nii.gz -thr 17 -uthr 17 -bin l_hip.nii.gz
fslmaths parcels.nii.gz -thr 53 -uthr 53 -bin r_hip.nii.gz
fslmaths parcels.nii.gz -thr 1012 -uthr 1012 -bin l_lofc.nii.gz
fslmaths parcels.nii.gz -thr 2012 -uthr 2012 -bin r_lofc.nii.gz
fslmaths parcels.nii.gz -thr 1011 -uthr 1011 -bin l_lo.nii.gz
fslmaths parcels.nii.gz -thr 2011 -uthr 2011 -bin r_lo.nii.gz
fslmaths parcels.nii.gz -thr 1018 -uthr 1018 -bin l_oper.nii.gz
fslmaths parcels.nii.gz -thr 2018 -uthr 2018 -bin r_oper.nii.gz
fslmaths parcels.nii.gz -thr 1019 -uthr 1019 -bin l_orbi.nii.gz
fslmaths parcels.nii.gz -thr 2019 -uthr 2019 -bin r_orbi.nii.gz
fslmaths parcels.nii.gz -thr 1020 -uthr 1020 -bin l_tria.nii.gz
fslmaths parcels.nii.gz -thr 2020 -uthr 2020 -bin r_tria.nii.gz
fslmaths parcels.nii.gz -thr 1014 -uthr 1014 -bin l_mofc.nii.gz
fslmaths parcels.nii.gz -thr 2014 -uthr 2014 -bin r_mofc.nii.gz
fslmaths parcels.nii.gz -thr 1032 -uthr 1032 -bin l_fropo.nii.gz
fslmaths parcels.nii.gz -thr 2032 -uthr 2032 -bin r_fropo.nii.gz
fslmaths parcels.nii.gz -thr 1028 -uthr 1028 -bin l_sfg.nii.gz
fslmaths parcels.nii.gz -thr 2028 -uthr 2028 -bin r_sfg.nii.gz
fslmaths parcels.nii.gz -thr 1027 -uthr 1027 -bin l_rmfg.nii.gz
fslmaths parcels.nii.gz -thr 2027 -uthr 2027 -bin r_rmfg.nii.gz
fslmaths parcels.nii.gz -thr 1003 -uthr 1003 -bin l_cmfg.nii.gz
fslmaths parcels.nii.gz -thr 2003 -uthr 2003 -bin r_cmfg.nii.gz
fslmaths parcels.nii.gz -thr 28 -uthr 28 -bin l_vidc.nii.gz
fslmaths parcels.nii.gz -thr 60 -uthr 60 -bin r_vidc.nii.gz

# ctx   all cortical regions
# subco all subcortical regions

fslmaths parcels.nii.gz -thr 1000 -uthr 1035 -bin l_ctx.nii.gz
fslmaths parcels.nii.gz -thr 2000 -uthr 2035 -bin r_ctx.nii.gz

fslmaths parcels.nii.gz -thr 9 -uthr 13 -bin l_subco.nii.gz
fslmaths parcels.nii.gz -thr 18 -uthr 18 -add l_subco -add l_hip -bin l_subco.nii.gz
fslmaths parcels.nii.gz -thr 48 -uthr 54 -bin r_subco.nii.gz

# bilateral ROIs

fslmaths l_lofc.nii.gz -add r_lofc.nii.gz b_lofc.nii.gz
fslmaths l_mofc.nii.gz -add r_mofc.nii.gz b_mofc.nii.gz
fslmaths l_lo.nii.gz -add r_lo.nii.gz b_lo.nii.gz
fslmaths l_oper.nii.gz -add r_oper.nii.gz b_oper.nii.gz
fslmaths l_orbi.nii.gz -add r_orbi.nii.gz b_orbi.nii.gz
fslmaths l_tria.nii.gz -add r_tria.nii.gz b_tria.nii.gz

# ifg   inferior frontal gyrus

fslmaths b_oper.nii.gz -add b_orbi.nii.gz -add b_tria.nii.gz b_ifg.nii.gz
fslmaths l_oper.nii.gz -add l_orbi.nii.gz -add l_tria.nii.gz l_ifg.nii.gz
fslmaths r_oper.nii.gz -add r_orbi.nii.gz -add r_tria.nii.gz r_ifg.nii.gz

fslmaths l_erc.nii.gz -add r_erc.nii.gz b_erc.nii.gz
fslmaths l_fus.nii.gz -add r_fus.nii.gz b_fus.nii.gz
fslmaths l_it.nii.gz -add r_it.nii.gz b_it.nii.gz
fslmaths l_phc.nii.gz -add r_phc.nii.gz b_phc.nii.gz
fslmaths l_hip.nii.gz -add r_hip.nii.gz b_hip.nii.gz
fslmaths l_vidc.nii.gz -add r_vidc.nii.gz b_vidc.nii.gz

fslmaths l_fropo.nii.gz -add r_fropo.nii.gz b_fropo.nii.gz
fslmaths l_sfg.nii.gz -add r_sfg.nii.gz b_sfg.nii.gz
fslmaths l_rmfg.nii.gz -add r_rmfg.nii.gz b_rmfg.nii.gz
fslmaths l_cmfg.nii.gz -add r_cmfg.nii.gz b_cmfg.nii.gz

# gray  cortical and subcortical gray matter

fslmaths l_ctx.nii.gz -add r_ctx.nii.gz b_ctx.nii.gz
fslmaths l_subco.nii.gz -add r_subco.nii.gz b_subco.nii.gz
fslmaths b_subco -add b_ctx b_gray

# ostemporal    temporal regions
# ostemporal_lo temporal and lateral occipital regions

fslmaths b_erc.nii.gz -add b_fus.nii.gz -add b_it.nii.gz -add b_phc ostemporal.nii.gz
fslmaths b_erc.nii.gz -add b_fus.nii.gz -add b_it.nii.gz -add b_phc -add b_lo.nii.gz ostemporal_lo.nii.gz

