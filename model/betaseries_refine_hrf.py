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
                    help="path to file to save filtered design matrices")
parser.add_argument('-m', '--mask', default=None,
                    help="(optional) path to mask image, indicating included voxels")
parser.add_argument('-j', '--n-jobs', type=int, default=1,
                    help="number of CPUs to use (default 1)")
args = parser.parse_args()

import os
import subprocess as sub
from joblib import Parallel, delayed
import numpy as np
from scipy.signal import savgol_filter
from mvpa2.misc.fsl.base import FslGLMDesign, read_fsl_design
from mvpa2.datasets.mri import fmri_dataset, map2nifti
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
    #bold_ds = fmri_dataset(bold, mask=mask)
else:
    # load all voxels
    hrf_ds = fmri_dataset(hrffile)
    #bold_ds = fmri_dataset(bold)

# everything after the trial EVs is regressors of no interest
dm_extra = desmat.mat[:,n_trial_evs:]

# additional confound regressors
if design.has_key('confoundev_files'):
    conf_file = design['confoundev_files']
    print("Loading confound file {}...".format(conf_file))
    dm_nuisance = np.loadtxt(conf_file)
else:
    print("No confound file indicated. Including no confound regressors...")
    dm_nuisance = None

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
hpf = float(design['fmri(paradigm_hp)'])
hpf_sigma = hpf / 2.0 / tr

# get a design matrix for each voxel
print("Creating voxel-specific design matrices...")
n_vox = hrf_ds.shape[1]
n_hrf_tp = hrf_ds.shape[0]
hrf_length = (n_hrf_tp-1) * tr
desmat_all_vox = np.zeros((n_tp, n_vox, n_trial_evs))
for i in range(n_vox):
    hrf_estimate = hrf_ds.samples[:,i]

    # re-normalize so that the max is one and there is a positive
    # correlation with the canonical HRF
    xx = np.arange(0, hrf_length+1, tr)
    sign = np.sign(np.dot(hrf_estimate, he.hrf.spmt(xx)))
    norm = np.abs(hrf_estimate).max()
    norm_hrf = hrf_estimate * sign / norm
    vox_mat, Q = he.utils.create_design_matrix(conds, onsets, tr, n_tp,
                                               basis=[hrf_estimate],
                                               hrf_length=hrf_length)
    desmat_all_vox[:,i,:] = vox_mat

def filter_ev(ev, hrf_ds, desmat, outname):
    print('{}: writing data to file...'.format(ev))
    nifti = map2nifti(hrf_ds, desmat_all_vox[:,:,ev])
    filepath = '{}_ev{:d}.nii.gz'.format(outname, ev)
    nifti.to_filename(filepath)

    # calculate mean over time
    print('{}: calculating mean...'.format(ev))
    mean_file = '{}_ev{:d}_mean.nii.gz'.format(outname, ev)
    filt_file = '{}_ev{:d}_filt.nii.gz'.format(outname, ev)
    sub.call(['fslmaths',filepath,'-Tmean',mean_file])

    # calculate filtered image for this regressor
    print('{}: temporal filtering...'.format(ev))
    sub.call(['fslmaths',filepath,'-bptf','{:.4f}'.format(hpf_sigma),
              '-1','-add',mean_file,filt_file])

    print('{}: reading filtered dataset...'.format(ev))
    ev_ds = fmri_dataset(filt_file, mask=args.mask)

    # remove temp files
    sub.call(['rm',filepath,mean_file,filt_file])
    
    return ev_ds.samples

# list of voxelwise regressor images for each EV
# each item includes a [TRs x voxels] matrix
print("High-pass filtering EV regressors...")
outname = args.outfile.split('.npy')[0]
if args.n_jobs > 1:
    l = Parallel(n_jobs=args.n_jobs,verbose=10)(delayed(filter_ev)(ev, hrf_ds,
                                                                   desmat_all_vox,
                                                                   outname)
                                                for ev in range(n_trial_evs))
else:
    l = [filter_ev(ev, hrf_ds, desmat_all_vox, outname)
         for ev in range(n_trial_evs)]
    
desmat_all_vox_filt = np.dstack(l)
np.save(args.outfile, desmat_all_vox_filt)
