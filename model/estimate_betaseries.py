#!/usr/bin/env python

from subjutil import *
from glob import glob
import os

parser = SubjParser()
parser.add_argument('model', help="name of model", type=str)
parser.add_argument('n', help="number of trials to estimate", type=int)
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, args.model, 'model',
              args.clean_logs, args.dry_run)

# find FSF files for this subject
data_dir = os.path.dirname(sp.path('base'))
model_dir = os.path.join(data_dir, 'batch', 'glm', args.model)
pattern = '%s_%s*.fsf' % (args.model, args.subject)
fsf_files = glob(os.path.join(model_dir, 'fsf', pattern))
fsf_files.sort()

log.start()

# temporary subject directory for individual beta images
out_dir = os.path.join(model_dir, 'beta', args.subject)
log.run('mkdir -p %s' % out_dir)

beta_files = []
for f in fsf_files:
    # use a feat utility to create the design matrix
    (base, ext) = os.path.splitext(f)
    name = os.path.basename(base)
    log.run('feat_model %s' % base)

    # obtain individual trial estimates
    log.run('betaseries.py %s %s %d' % (base, out_dir, args.n))

    # get one file with estimates for each trial/stimulus
    beta_file = os.path.join(out_dir, name + '.nii.gz')
    ev_files = []
    for i in range(args.n):
        ev_files.append(os.path.join(out_dir, 'ev%03d.nii.gz' % i))
    cmd = 'fslmerge -t %s %s' % (beta_file, ' '.join(ev_files))
    log.run(cmd)
    beta_files.append(beta_file)

    # remove temp files
    log.run('rm %s' % ' '.join(ev_files))

# merge all runs into one file
out_file = os.path.join(model_dir, 'beta',
                        '%s_beta.nii.gz' % args.subject)
cmd = 'fslmerge -t %s %s' % (out_file, ' '.join(beta_files))
log.run(cmd)

# delete individual run beta files
log.run('rm %s' % ' '.join(beta_files))
log.run('rmdir %s' % out_dir)

log.finish()