#!/usr/bin/env python

from argparse import ArgumentParser

parser = ArgumentParser(description="Estimate a betaseries using smoothed hrf estimates.")
parser.add_argument('modelbase', type=str,
                    help="path to model FSF file, without file extension")
parser.add_argument('ntrials', type=int,
                    help="number of trials to be estimated")
parser.add_argument('hrffile', type=str,
                    help="path to hrf image")
parser.add_argument('designfile', type=str,
                    help="path to file with design matrices")
parser.add_argument('outfile', type=str,
                    help="path to output filtered design matrices")
parser.add_argument('-m', '--mask', default=None,
                    help="(optional) path to mask image, indicating included voxels")
parser.add_argument('-j', '--n-jobs', type=int, default=1,
                    help="number of CPUs to use (default 1)")
args = parser.parse_args()

import os
import subprocess as sub
from joblib import Parallel, delayed
import numpy as np
from mvpa2.misc.fsl.base import FslGLMDesign, read_fsl_design
from mvpa2.datasets.mri import fmri_dataset, map2nifti

# check HRF file
hrffile = args.hrffile
if not hrffile.endswith('.nii.gz'):
    hrffile += '.nii.gz'
if not os.path.exists(hrffile):
    raise IOError('HRF file not found: {}'.format(hrffile))

print("Loading HRF dataset...")
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

# design and scan information
design = read_fsl_design(args.modelbase + '.fsf')
tr = float(design['fmri(tr)'])
hpf = float(design['fmri(paradigm_hp)'])
hpf_sigma = hpf / 2.0 / tr

# load the design matrix for each voxel (ideally would use memory
# mapping here, but that isn't working in our python environment)
print("Loading voxel-specific design matrices...")
n_trial_evs = args.ntrials
outname = args.outfile.split('.npy')[0]
    
def filter_ev(ev, hrf_ds, outname):
    # calculate mean over time
    print('{}: calculating mean...'.format(ev))
    ev_file = '{}_ev{:d}.nii.gz'.format(outname, ev)
    mean_file = '{}_ev{:d}_mean.nii.gz'.format(outname, ev)
    filt_file = '{}_ev{:d}_filt.nii.gz'.format(outname, ev)
    sub.call(['fslmaths',ev_file,'-Tmean',mean_file])

    # calculate filtered image for this regressor
    print('{}: temporal filtering...'.format(ev))
    sub.call(['fslmaths',ev_file,'-bptf','{:.4f}'.format(hpf_sigma),
              '-1','-add',mean_file,'-mas',args.mask,filt_file])

    return filt_file

# list of voxelwise regressor images for each EV
# each item includes a [TRs x voxels] matrix
print("High-pass filtering EV regressors...")

nif args.n_jobs > 1:
    filt_files = Parallel(n_jobs=args.n_jobs,
                          verbose=10)(delayed(filter_ev)(ev, hrf_ds, outname)
                                      for ev in range(n_trial_evs))
else:
    filt_files = [filter_ev(ev, hrf_ds, outname) for ev in range(n_trial_evs)]

# read in filtered data
l = []
for ev, filt_file in enumerate(filt_files):
    print('{}: reading filtered dataset...'.format(ev))
    ev_ds = fmri_dataset(filt_file, mask=args.mask)
    l.append(ev_ds.samples.astype('float32'))
    
print("Saving filtered design matrices")    
desmat_all_vox_filt = np.dstack(l)
del l
np.save(args.outfile, desmat_all_vox_filt)
del desmat_all_vox_filt

# remove temp files
for ev in range(n_trial_evs):
    ev_file = '{}_ev{:d}.nii.gz'.format(outname, ev)
    mean_file = '{}_ev{:d}_mean.nii.gz'.format(outname, ev)
    filt_file = '{}_ev{:d}_filt.nii.gz'.format(outname, ev)
    sub.call(['rm',ev_file,mean_file,filt_file])
