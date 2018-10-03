#!/usr/bin/env python

from argparse import ArgumentParser

parser = ArgumentParser(description="Estimate a betaseries using smoothed hrf estimates.")
parser.add_argument('modelbase', type=str,
                    help="path to model FSF file, without file extension")
parser.add_argument('ntrials', type=int,
                    help="number of trials to be estimated")
parser.add_argument('hrffile', type=str,
                    help="path to hrf image")
parser.add_argument('outfile', type=str,
                    help="path to file to save design matrices")
parser.add_argument('-m', '--mask', default=None,
                    help="(optional) path to mask image, indicating included voxels")
args = parser.parse_args()

import os
import numpy as np
from mvpa2.misc.fsl.base import FslGLMDesign, read_fsl_design
from mvpa2.datasets.mri import fmri_dataset
import hrf_estimation as he

design = read_fsl_design(args.modelbase + '.fsf')
desmat = FslGLMDesign(args.modelbase + '.mat')

n_tp, n_evs = desmat.mat.shape

# trial regressors are just the first N regressors
n_trial_evs = args.ntrials
trial_evs = range(0, args.ntrials)

# number of original regressors and all regressors including
# derivatives
n_orig = design['fmri(evs_orig)']

# check which trial regressors have temporal derivatives
isderiv = np.zeros(n_orig, dtype=bool)
for i in range(n_orig):
    f = 'fmri(deriv_yn{:d})'.format(i+1)
    isderiv[i] = design[f]

if np.any(isderiv):
    raise IOError('Must not include derivatives in design matrix.')

# check bold file
bold = design['feat_files']
if not bold.endswith('.nii.gz'):
    bold += '.nii.gz'
if not os.path.exists(bold):
    raise IOError('BOLD file not found: {}'.format(bold))

# check HRF file
hrffile = args.hrffile
if not hrffile.endswith('.nii.gz'):
    hrffile += '.nii.gz'
if not os.path.exists(hrffile):
    raise IOError('HRF file not found: {}'.format(hrffile))

if args.mask is not None:
    # user specified a mask
    mask = args.mask
    if not mask.endswith('.nii.gz'):
        mask += '.nii.gz'
    if not os.path.exists(mask):
        raise IOError('Mask file not found: {}'.format(mask))
    hrf_ds = fmri_dataset(hrffile, mask=args.mask)
else:
    # load all voxels
    hrf_ds = fmri_dataset(hrffile)

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

tr = float(design['fmri(tr)'])

# generate canonical HRF at the sampled times
(n_hrf_tp, n_vox) = hrf_ds.shape
hrf_length = (n_hrf_tp - 1) * tr
xx = np.arange(0, hrf_length + 1, tr)
canonical = he.hrf.spmt(xx)

# get a design matrix for each voxel
print("Creating voxel-specific design matrices...")
desmat_all_vox = np.zeros((n_tp, n_vox, n_trial_evs), dtype=np.float32)
for i in range(n_vox):
    # re-normalize so that the max is one and there is a positive
    # correlation with the canonical HRF
    hrf_estimate = hrf_ds.samples[:,i]
    sign = np.sign(np.dot(hrf_estimate, canonical))
    norm = np.abs(hrf_estimate).max()
    norm_hrf = hrf_estimate * sign / norm

    # generate the design matrix
    (desmat_all_vox[:,i,:],
     Q) = he.utils.create_design_matrix(conds, onsets, tr, n_tp,
                                        basis=[norm_hrf],
                                        hrf_length=hrf_length)
np.save(args.outfile, desmat_all_vox)
