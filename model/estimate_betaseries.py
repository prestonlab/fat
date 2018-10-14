#!/usr/bin/env python

from subjutil import *

s = """Estimate a betaseries using a LS-S model.

First, set up an fsf file using FEAT, for one sample run. You'll need
one EV for each trial/stimulus to estimate activation for. The script
will use the onset files, confound matrix (if specified), and the
high-pass filter setting. In the model, the first ntrials regressors
are assumed to be the trials of interest. Any additional regressors
after that will be included as regressors of no interest.

To generate fsf files for all subjects and all runs, use
prep_level1.sh. This just takes the sample fsf file and replaces
subject and run codes to generate a customized file for each run.

The BOLD data to estimate the model for will be the file specified in
the FEAT model (in the fsf file, this is in the feat_files
field). Generally, these data should have already been smoothed (if
desired) and high-pass filtered; the high-pass filter specified in the
model is only applied to the model itself, and it's assumed that the
data have already been filtered using the same FWHM.

The script runs betaseries.py to estimate each EV for each run,
concatenate the estimate EVs into one image, and then concatenates all
runs together (in the sorted order of the run names).

"""

parser = SubjParser(raw=True, description=s)
parser.add_argument('model', help="name of model", type=str)
parser.add_argument('n', help="number of trials to estimate", type=int)
parser.add_argument('-m', '--mask', help="mask file", type=str, default=None)
parser.add_argument('-n', '--no-zscore', action="store_true",
                    help="do not z-score trial images over voxels")
parser.add_argument('-f', '--fsf-dir', default=None,
                    help="path to directory with fsf files (default: $STUDYDIR/batch/glm/$model/fsf")
parser.add_argument('-o', '--out-dir', default=None,
                    help="path to directory to save betaseries images (default: $STUDYDIR/batch/glm/$model/beta")
args = parser.parse_args()

from glob import glob
import os

from mvpa2.misc.fsl.base import read_fsl_design

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log(args.model, 'model', args)

# find FSF files for this subject
data_dir = os.path.dirname(sp.path('base'))
if args.fsf_dir is None:
    fsf_dir = os.path.join(data_dir, 'batch', 'glm', args.model, 'fsf')
else:
    fsf_dir = args.fsf_dir
pattern = os.path.join(fsf_dir, 'fsf',
                       '{}_{}*.fsf'.format(args.model, args.subject))
fsf_files = glob(pattern)
if not fsf_files:
    raise IOError('No FSF files found matching: {}'.format(pattern))

fsf_files.sort()

log.start()

# temporary subject directory for individual beta images
if args.out_dir is None:
    out_dir = os.path.join(data_dir, 'batch', 'glm', args.model,
                           'beta', args.subject)
else:
    out_dir = args.out_dir
log.run('mkdir -p {}'.format(out_dir))

beta_files = []
for f in fsf_files:
    # use a feat utility to create the design matrix
    (base, ext) = os.path.splitext(f)
    name = os.path.basename(base)
    log.run('feat_model {}'.format(base))

    design = read_fsl_design(f)
    bold = design['feat_files']
    if not bold.endswith('.nii.gz'):
        bold += '.nii.gz'
    if not os.path.exists(bold):
        raise IOError('BOLD file not found: {}'.format(bold))

    opt = ''
    if args.mask is not None:
        opt += ' -m {}'.format(args.mask)
    if args.no_zscore:
        opt += ' -n'
    
    # obtain individual trial estimates
    log.run('betaseries.py {} {} {:d}{}'.format(base, out_dir, args.n, opt))

    # get one file with estimates for each trial/stimulus
    beta_file = os.path.join(out_dir, name + '.nii.gz')
    ev_files = []
    for i in range(args.n):
        ev_files.append(os.path.join(out_dir, 'ev{:03d}.nii.gz'.format(i)))
    log.run('fslmerge -t {} {}'.format(beta_file, ' '.join(ev_files)))
    beta_files.append(beta_file)

    # remove temp files
    log.run('rm {}'.format(' '.join(ev_files)))
    log.run('rm {}*.{{con,png,ppm,frf,mat,min,trg}}'.format(base))

# merge all runs into one file
out_file = os.path.join(out_dir, '{}_beta.nii.gz'.format(args.subject))
cmd = 'fslmerge -t {} {}'.format(out_file, ' '.join(beta_files))
log.run(cmd)

# delete individual run beta files
log.run('rm {}'.format(' '.join(beta_files)))
log.run('rmdir {}'.format(out_dir))

log.finish()
