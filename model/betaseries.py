#!/usr/bin/env python
"""betaseries: script for computing beta-series regression on fMRI data
"""

from argparse import ArgumentParser
parser = ArgumentParser(description="Estimate betaseries using LS-S regression (Mumford et al. 2014).")
parser.add_argument('modelbase', type=str,
                    help="path to model files, without file extension")
parser.add_argument('betadir', type=str,
                    help="path to directory in which to save betaseries image")
parser.add_argument('ntrials', type=int,
                    help="number of trials to be estimated")
parser.add_argument('-m', '--mask', type=str,
                    help="(optional) path to mask image, indicating included voxels")
args = parser.parse_args()

from mvpa2.misc.fsl.base import FslGLMDesign, read_fsl_design
from mvpa2.datasets.mri import fmri_dataset

import numpy as N
import nibabel
import scipy.stats
from scipy.stats.mstats import zscore
from scipy.ndimage import convolve1d
from scipy.sparse import spdiags
from scipy.linalg import toeplitz
from mvpa2.datasets.mri import *
import os
from copy import copy

fsffile = args.modelbase + '.fsf'
matfile = args.modelbase + '.mat'
betadir = args.betadir
ntrials = args.ntrials

time_res = 0.1
ntrials_total = ntrials
good_evs = range(0,ntrials)

print("Loading design...")
design = read_fsl_design(fsffile)
desmat = FslGLMDesign(matfile)

nevs = desmat.mat.shape[1]
ntp = desmat.mat.shape[0]

# find input bold data
print("Loading data...")
bold = design['feat_files']
if not bold.endswith('.nii.gz'):
    bold += '.nii.gz'
if not os.path.exists(bold):
    raise IOError('BOLD file not found: {}'.format(bold))

if args.mask is not None:
    # user specified a mask
    mask = args.mask
    if not mask.endswith('.nii.gz'):
        mask += '.nii.gz'
    if not os.path.exists(mask):
        raise IOError('Mask file not found: {}'.format(mask))
    data = fmri_dataset(bold, mask=mask)
else:
    # load all voxels
    data = fmri_dataset(bold)
nvox = data.nfeatures

# design matrix
print("Creating design matrices...")
if design.has_key('confoundev_files'):
    conf_file = design['confoundev_files']
    print("Loading confound file {}...".format(conf_file))
    dm_nuisance = N.loadtxt(conf_file)
else:
    print("No confound file indicated. Including no confound regressors...")
    dm_nuisance = None
dm_extra = desmat.mat[:,ntrials:]
trial_ctr = 0
all_conds = []
beta_maker = N.zeros((ntrials_total,ntp))
for e in range(len(good_evs)):
    ev = good_evs[e]

    dm_toi = desmat.mat[:,ev]

    other_good_evs = [x for x in good_evs if x != ev]
    dm_otherevs = desmat.mat[:,other_good_evs]
    dm_otherevs = N.sum(dm_otherevs[:,:,N.newaxis],axis=1)

    # Put together the design matrix
    if dm_nuisance is not None:
        dm_full = N.hstack((dm_toi[:,N.newaxis],dm_otherevs,dm_nuisance,dm_extra))
    else:
        dm_full = N.hstack((dm_toi[:,N.newaxis],dm_otherevs,dm_extra))

    # making betas
    dm_full = dm_full - N.kron(N.ones((dm_full.shape[0],dm_full.shape[1])), \
                N.mean(dm_full,0))[0:dm_full.shape[0],0:dm_full.shape[1]]
    dm_full=N.hstack((dm_full,N.ones((ntp,1))))
    beta_maker_loop=N.linalg.pinv(dm_full)
    beta_maker[trial_ctr,:]=beta_maker_loop[0,:]
    trial_ctr+=1

print("Estimating model...")
# this uses Jeanette's trick of extracting the beta-forming vector for each
# trial and putting them together, which allows estimation for all trials
# at once
glm_res_full = N.dot(beta_maker,data.samples)

# map the data into images and save to betaseries directory
for e in range(len(glm_res_full)):
    outdata = zscore(glm_res_full[e])
    ni = map2nifti(data,data=outdata)
    ni.to_filename(os.path.join(betadir,
                                'ev{:03d}.nii.gz'.format(good_evs[e])))
