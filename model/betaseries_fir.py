#!/usr/bin/env python

from argparse import ArgumentParser, RawTextHelpFormatter

s = """Estimate a betaseries using FIR HRF estimation for one run.

First, set up an fsf file using FEAT. You'll need one EV for each 
trial/stimulus to estimate activation for. The script will use the 
onset files, confound matrix (if specified), and the high-pass filter 
setting. In the model, the first ntrials regressors are assumed to be 
the trials of interest. Any additional regressors after that will be 
included as regressors of no interest.
"""

parser = ArgumentParser(description=s, formatter_class=RawTextHelpFormatter)
parser.add_argument('modelbase', type=str,
                    help="path to model files, without file extension")
parser.add_argument('ntrials', type=int,
                    help="number of trials to be estimated")
parser.add_argument('outdir', type=str,
                    help="path to directory to save betaseries")
parser.add_argument('-m', '--mask', default=None,
                    help="(optional) path to mask image, indicating included voxels")
parser.add_argument('-s', '--smooth', default=None,
                    help="(optional) smoothing of HRF in mm FWHM")
parser.add_argument('-j', '--n-jobs', type=int, default=1,
                    help="number of CPUs to use (default 1)")
parser.add_argument('-l', '--hrf-length', type=float, default=20.0,
                    help="length of HRF to estimate in s (default: 20 s)")
args = parser.parse_args()

import os
import subprocess as sub

if not os.path.exists(args.outdir):
    os.makedirs(args.outdir)

# initial estimates
# creates betaseries_init, betaseries_init_hrfs
print("Creating initial betaseries and HRF estimates...")
init_file = os.path.join(args.outdir, 'betaseries_init')
sub.call(['betaseries_hrf.py', args.modelbase, args.ntrials,
          'r1glm','fir', init_file, '-m', args.mask, '-j', '24',
          '-l', args.hrf_length])
hrf_file = os.path.join(args.outdir, 'betaseries_init_hrfs.nii.gz')

# smooth the initial hrf estimates
if args.smooth is not None:
    print("Smoothing HRF estimates...")
    hrf_smooth_file = os.path.join(args.outdir, 'betaseries_init_hrfs_sm.nii.gz')
    sub.call(['smooth_susan', hrf_file, args.mask, args.smooth,
              hrf_smooth_file])
else:
    hrf_smooth_file = hrf_file

# make a new design matrix for each voxel
print("Creating voxelwise design matrices...")
voxel_design_file = os.path.join(args.outdir, 'betaseries_design.npy')
sub.call(['betaseries_refine_hrf.py', args.modelbase, args.ntrials,
          hrf_smooth_file, voxel_design_file, '-m', args.mask,
          '-j', '8'])

# final estimation with the new design matrices
print("Estimating final betaseries image...")
betaseries_file = os.path.join(args.outdir, 'betaseries.nii.gz')
sub.call(['betaseries_hrf_model.py', args.modelbase, voxel_design_file,
          betaseries_file, '-m', args.mask])
