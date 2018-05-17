#!/usr/bin/env python

from subjutil import *
from glob import glob
import os

from mvpa2.misc.fsl.base import read_fsl_design

parser = SubjParser()
parser.add_argument('model', help="name of model", type=str)
parser.add_argument('n', help="number of trials to estimate", type=int)
parser.add_argument('modeltype',
                    help="GLM model to use (r1glm, r1glms glms glm)")
parser.add_argument('basis', help="basis to use (hrf, 3hrf, fir)")
parser.add_argument('-m', '--mask', help="mask file", type=str, default=None)
parser.add_argument('-j', '--n-jobs', type=int, default=None,
                    help="number of CPUs to use (default 1)")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log(args.model, 'model', args)

# find FSF files for this subject
data_dir = os.path.dirname(sp.path('base'))
model_dir = os.path.join(data_dir, 'batch', 'glm', args.model)
pattern = os.path.join(model_dir, 'fsf',
                       '{}_{}*.fsf'.format(args.model, args.subject))
fsf_files = glob(pattern)
if not fsf_files:
    raise IOError('No FSF files found matching: {}'.format(pattern))

fsf_files.sort()

log.start()

# temporary subject directory for individual beta images
out_dir = os.path.join(model_dir, 'beta', args.subject)
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
    if args.n_jobs is not None:
        opt += ' -j {}'.format(args.n_jobs)
    
    # obtain individual trial estimates
    beta_file = os.path.join(out_dir, name + '.nii.gz')
    log.run('betaseries_hrf.py {} {:d} {} {} {}{}'.format(
        base, args.n, args.modeltype, args.basis, beta_file, opt))

    # get one file with estimates for each trial/stimulus
    beta_files.append(beta_file)

    # remove temp files
    log.run('rm {}*.{{con,png,ppm,frf,mat,min,trg}}'.format(base))

# merge all runs into one file
out_file = os.path.join(model_dir, 'beta',
                        '{}_beta.nii.gz'.format(args.subject))
cmd = 'fslmerge -t {} {}'.format(out_file, ' '.join(beta_files))
log.run(cmd)

# delete individual run beta files
log.run('rm {}'.format(' '.join(beta_files)))
log.run('rmdir {}'.format(out_dir))

log.finish()
