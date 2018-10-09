#!/usr/bin/env python

from argparse import ArgumentParser, RawTextHelpFormatter

s = """Estimate a betaseries using FIR HRF estimation for one run.

First, set up an fsf file using FEAT. You'll need one EV for each
trial/stimulus to estimate activation for. The script will use the
onset files, confound matrix (if specified), and the high-pass filter
setting. In the model, the first ntrials regressors are assumed to be
the trials of interest. Any additional regressors after that will be
included as regressors of no interest. 

The BOLD data to estimate the model for will be the file specified in
the FEAT model (in the fsf file, this is in the feat_files
field). Generally, these data should have already been smoothed (if
desired) and high-pass filtered; the high-pass filter specified in the
model is only applied to the model itself, and it's assumed that the
data have already been filtered using the same FWHM.

The script first calculates an initial estimate of both the betaseries
and the HRF function at each voxel, estimating both simultaneously
using a rank-one GLM method (Pedregosa et al. 2015). It then
optionally smooths the voxel HRF estimates to improve their
reliability. The HRF estimates are then used to create a design matrix
for each voxel and each individual trial/stimulus using the LS-S
method (Mumford et al. 2012). Each design matrix is high-pass
filtered. Finally, the betaseries image is estimated using ordinary
least squares.

"""

parser = ArgumentParser(description=s, formatter_class=RawTextHelpFormatter)
parser.add_argument('modelbase', type=str,
                    help="path to .fsf file, without file extension")
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
parser.add_argument('-o', '--overwrite', type=bool, default=False,
                    help="overwrite existing results")
args = parser.parse_args()

import os
import subprocess as sub

if not os.path.exists(args.outdir):
    os.makedirs(args.outdir)

log_file = os.path.join(args.outdir, 'log.txt')
log = open(log_file, 'w')
print("Estimating betaseries and HRF shape...")
print("Status will be written to: {}".format(log_file))

# initial estimates
# creates betaseries_init, betaseries_init_hrfs
init_file = os.path.join(args.outdir, 'betaseries_init')
hrf_file = os.path.join(args.outdir, 'betaseries_init_hrfs.nii.gz')
if args.overwrite or not os.path.exists(hrf_file):
    print("Creating initial betaseries and HRF estimates...")
    sub.call(['betaseries_hrf.py', args.modelbase, str(args.ntrials),
              'r1glm','fir', init_file, '-m', args.mask, '-j', '24',
              '-l', '{:.2f}'.format(args.hrf_length)],
             stdout=log, stderr=log)

# smooth the initial hrf estimates
if args.smooth is not None:
    hrf_smooth_file = os.path.join(args.outdir, 'betaseries_init_hrfs_sm.nii.gz')
    if args.overwrite or not os.path.exists(hrf_smooth_file):
        print("Smoothing HRF estimates...")
        sub.call(['smooth_susan', hrf_file, args.mask, args.smooth,
                  hrf_smooth_file], stdout=log, stderr=log)
else:
    hrf_smooth_file = hrf_file

# make a new design matrix for each voxel
ev_design_base = os.path.join(args.outdir, 'betaseries_design')

# check whether the output files exist
all_exist = True
for ev in range(args.ntrials):
    design_file = '{}_ev{:d}.nii.gz'.format(ev_design_base, ev)
    if not os.path.exists(design_file):
        all_exist = False
        break

if args.overwrite or not all_exist:
    print("Creating voxelwise design matrices...")
    sub.call(['betaseries_design_hrf.py', args.modelbase, str(args.ntrials),
              hrf_smooth_file, ev_design_base, '-m', args.mask],
             stdout=log, stderr=log)

voxel_design_file = os.path.join(args.outdir, 'betaseries_design.npy')
if args.overwrite or not os.path.exists(voxel_design_file):
    print("Filtering design matrices...")
    sub.call(['betaseries_filter_hrf.py', args.modelbase, str(args.ntrials),
              hrf_smooth_file, ev_design_base, voxel_design_file,
              '-m', args.mask, '-j', '24'], stdout=log, stderr=log)
    
# final estimation with the new design matrices
betaseries_file = os.path.join(args.outdir, 'betaseries.nii.gz')
if args.overwrite or not os.path.exists(betaseries_file):
    print("Estimating final betaseries image...")
    sub.call(['betaseries_hrf_model.py', args.modelbase, voxel_design_file,
              betaseries_file, '-m', args.mask], stdout=log, stderr=log)

log.close()
