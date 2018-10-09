#!/usr/bin/env python

from argparse import ArgumentParser

parser = ArgumentParser(description="Estimate a betaseries using smoothed hrf estimates.")
parser.add_argument('modelbase', type=str,
                    help="path to model FSF file, without file extension")
parser.add_argument('voxdesfile', type=str,
                    help="path to voxelwise design file (.npy)")
parser.add_argument('outfile', type=str,
                    help="path to file to save betaseries image")
parser.add_argument('-m', '--mask', default=None,
                    help="(optional) path to mask image, indicating included voxels")
args = parser.parse_args()

from mvpa2.misc.fsl.base import FslGLMDesign, read_fsl_design
from mvpa2.datasets.mri import fmri_dataset, map2nifti

import numpy as np
import scipy.stats
from scipy.stats.mstats import zscore
import os

fsffile = args.modelbase + '.fsf'
matfile = args.modelbase + '.mat'

print("Loading design...")
design = read_fsl_design(fsffile)
desmat = FslGLMDesign(matfile)

# number of original regressors and all regressors including
# derivatives
n_orig = design['fmri(evs_orig)']

desmat_all_vox = np.load(args.voxdesfile)
n_tp, n_vox, n_evs = desmat_all_vox.shape

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

# everything after the trial EVs is regressors of no interest
dm_extra = desmat.mat[:,n_evs:]

# additional confound regressors
if design.has_key('confoundev_files'):
    conf_file = design['confoundev_files']
    print("Loading confound file {}...".format(conf_file))
    dm_nuisance = np.loadtxt(conf_file)
else:
    print("No confound file indicated. Including no confound regressors...")
    dm_nuisance = None

betaimage = np.zeros((n_evs, n_vox))
print("Estimating betaseries for each voxel...")
for j in range(n_vox):
    beta_maker = np.zeros((n_evs, n_tp))
    for i in range(n_evs):
        # just the one regressor for this trial
        dm_trial = desmat_all_vox[:,j,i,np.newaxis]

        # other trials, summed together
        other_trial_evs = [x for x in range(n_evs) if x != i]
        dm_otherevs = np.sum(desmat_all_vox[:,j,other_trial_evs,np.newaxis],2)

        # put together the design matrix
        if dm_nuisance is not None:
            dm_full = np.hstack((dm_trial, dm_otherevs, dm_nuisance, dm_extra))
        else:
            dm_full = np.hstack((dm_trial, dm_otherevs, dm_extra))
        s = dm_full.shape
        dm_full = dm_full - np.kron(np.ones(s), np.mean(dm_full,0))[:s[0],:s[1]]
        dm_full = np.hstack((dm_full, np.ones((n_tp,1))))

        # calculate beta-forming vector
        beta_maker_loop = np.linalg.pinv(dm_full)
        beta_maker[i,:] = beta_maker_loop[0,:]

    # this uses Jeanette's trick of extracting the beta-forming vector for each
    # trial and putting them together, which allows estimation for all trials
    # at once
    betaimage[:,j] = np.dot(beta_maker, data.samples[:,j])
del desmat_all_vox

# write out betaseries
print("Writing betaseries image...")
ni = map2nifti(data, betaimage)
ni.to_filename(args.outfile)
