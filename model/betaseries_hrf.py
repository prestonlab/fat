#!/usr/bin/env python
"""betaseries: script for computing beta-series regression on fMRI data
"""

from argparse import ArgumentParser, RawTextHelpFormatter
s = """Estimate betaseries using LS-S regression.

See Mumford et al. 2014 for details. 

Specify the base for a design generated by FEAT. For example, if you
have a .fsf file in mydesign.fsf, specify mydesign as the modelbase.

The trial regressors are assumed to be in your original EVs (as opposed
to the real EVs, which include for example temporal derivatives of the
original EVs). The trials to model are assumed to be the first ones listed.
For example, if 30 orig EVs are included in the model, and ntrials is set
to 20, then the last 10 EVs are assumed to be modeling things other than
the individual trials. The exception are temporal derivatives of the trial
EVs, which are assumed to be interleaved with the original trial EVs.

If derivatives are included in the model, they will be included as
additional regressors. If --sep-derivs is included as an option, then the
current trial derivative and other trial derivatives will be estimated
separately.

For unknown reasons, each trial image is z-scored over voxels. This
means that the value of a voxel in a given trial image will depend on
things like the size of the mask and values at other voxels. For
legacy purposes, for now that is still the default. To write raw
betaseries estimates, use the --no-zscore flag.

You may also specify confound regressors (defined in the fsf file under
'confoundev_files'), which will be included as regressors of no interest.

"""

parser = ArgumentParser(description="Estimate betaseries using LS-S regression (Mumford et al. 2014).")
parser.add_argument('modelbase', type=str,
                    help="path to model files, without file extension")
parser.add_argument('ntrials', type=int,
                    help="number of trials to be estimated")
parser.add_argument('modeltype',
                    help="GLM model to use (r1glm, r1glms glms glm)")
parser.add_argument('basis', help="basis to use (hrf, 3hrf, fir)")
parser.add_argument('outfile', type=str,
                    help="path to file to save betaseries")
parser.add_argument('-m', '--mask', type=str,
                    help="(optional) path to mask image, indicating included voxels")
parser.add_argument('-j', '--n-jobs', type=int, default=1,
                    help="number of CPUs to use (default 1)")
parser.add_argument('-l', '--hrf-length', type=float, default=20.0,
                    help="length of HRF to estimate in s (default: 20 s)")
args = parser.parse_args()

from mvpa2.misc.fsl.base import FslGLMDesign, read_fsl_design
from mvpa2.datasets.mri import fmri_dataset, map2nifti
import hrf_estimation as he

import numpy as np
import scipy.stats
from scipy.stats.mstats import zscore
import os
import subprocess as sub

fsffile = args.modelbase + '.fsf'
matfile = args.modelbase + '.mat'
n_trial = args.ntrials

print("Loading design...")
design = read_fsl_design(fsffile)
desmat = FslGLMDesign(matfile)

n_tp, n_evs = desmat.mat.shape

# number of original regressors and all regressors including
# derivatives
n_orig = design['fmri(evs_orig)']

# check which trial regressors have temporal derivatives
isderiv = np.zeros(n_orig, dtype=bool)
for i in range(n_orig):
    f = 'fmri(deriv_yn{:d})'.format(i+1)
    isderiv[i] = design[f]

# check if derivatives are included for all trials
n_trial_deriv = np.sum(isderiv)
if n_trial_deriv == n_trial:
    deriv = True
elif n_trial_deriv == 0:
    deriv = False
else:
    raise ValueError('Must either include derivatives for all trials or none.')
    
if deriv:
    # temporal derivatives are included. FEAT interleaves them with
    # the original ones, starting with the first original regressor
    n_trial_evs = n_trial * 2
    trial_evs = range(0, n_trial_evs, 2)
    deriv_evs = range(1, n_trial_evs, 2)
    print("Using derivatives of trial regressors.")
else:
    # trial regressors are just the first N regressors
    n_trial_evs = n_trial
    trial_evs = range(0, n_trial)
    deriv_evs = []

# find input bold data
bold = design['feat_files']
if not bold.endswith('.nii.gz'):
    bold += '.nii.gz'
if not os.path.exists(bold):
    raise IOError('BOLD file not found: {}'.format(bold))

# everything after the trial EVs is regressors of no interest
dm_extra = desmat.mat[:,n_trial_evs:]

# additional confound regressors
if design.has_key('confoundev_files'):
    conf_file = design['confoundev_files']
    print("Loading confound file {}...".format(conf_file))
    dm_nuisance = np.loadtxt(conf_file)
    dm_extra = np.hstack((dm_extra, dm_nuisance))

# get onsets and conditions in the correct format
onset_list = []
cond_list = []
for i in range(n_orig):
    onset_file = design['fmri(custom{:d})'.format(i+1)]
    mat = np.loadtxt(onset_file)
    for onset in mat[:,0]:
        onset_list.append(onset)
        cond_list.append(i+1)
onsets = np.array(onset_list)
conds = np.array(cond_list)

# regress out nuisance regressors
#n_extra = dm_extra.shape[1]
#reg_filter = ','.join([str(x) for x in range(1, n_extra+1)])

print("Loading data from {}...".format(bold))
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

# remove voxel means
data.samples -= np.mean(data.samples, 0)

# glm estimation
ind = np.argsort(onsets)
tr = design['fmri(tr)']
drifts = np.ones((data.shape[0], 1))
hrfs, betas = he.glm(conds[ind], onsets[ind], tr, data.samples,
                     mode=args.modeltype, basis=args.basis, drifts=drifts,
                     hrf_length=args.hrf_length, n_jobs=args.n_jobs,
                     verbose=True)

# write out hrf estimates
outname = os.path.splitext(os.path.splitext(args.outfile)[0])[0]
hrf_file = outname + '_hrfs.nii.gz'
ni = map2nifti(data, hrfs)
ni.to_filename(hrf_file)

# write out initial betaseries
ni = map2nifti(data, betas)
ni.to_filename(args.outfile)
