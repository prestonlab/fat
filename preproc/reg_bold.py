#!/usr/bin/env python

from subjutil import *
import os
import re

parser = SubjParser()
parser.add_argument('--run-pattern', '-r',
                    help="regular expression for run directories",
                    metavar='regexp',
                    default='^\D+_\d+$')
parser.add_argument('refrun', help="reference run")
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, 'regbold', args.clean_logs, args.dry_run)

# find all files/directories in the BOLD directory
d = os.listdir(sp.path('bold'))
if args.refrun not in d:
    raise ValueError('Reference run not found.')

# find the runs to include
run_dirs = sp.bold(args.run_pattern)

# prepare transformation directories
reg_data = sp.path('bold', 'antsreg', 'data')
reg_xfm = sp.path('bold', 'antsreg', 'transforms')
log.run('mkdir -p %s' % reg_data)
log.run('mkdir -p %s' % reg_xfm)

# calculate a timeseries average for each run
bold_file = []
avg_file = []
for i in range(len(run_dirs)):
    bold_file.append(os.path.join(run_dirs[i], 'bold_mcf_brain.nii.gz'))
    avg_file.append(os.path.join(run_dirs[i], 'bold_mcf_brain_avg.nii.gz'))
    log.run('fslmaths %s -Tmean %s' % (bold_file[i], avg_file[i]))

    if os.path.basename(run_dirs[i]) == args.refrun:
        bold_ref = os.path.join(reg_data, 'refvol.nii.gz')
        log.run('cp %s %s' % (avg_file[i], bold_ref))

# calculate and apply the tranformation for every non-reference run
for i in range(len(run_dirs)):
    run_name = os.path.basename(run_dirs[i])
    new_file = os.path.join(reg_data, run_name + '.nii.gz')

    if run_name == args.refrun:
        # no need to transform
        log.run('cp %s %s' % (bold_file[i], new_file))
        continue
        
    # calculate transform
    xfm_base = os.path.join(reg_xfm, '%s-refvol_' % run_name)
    cmd = 'ANTS 3 -m MI[%s,%s,1,32] -o %s --rigid-affine -i 0' % (
        bold_ref, avg_file[i], xfm_base)
    log.run(cmd)

    # apply transform to run
    xfm_file = xfm_base + 'Affine.txt'
    cmd = 'WarpTimeSeriesImageMultiTransform 4 %s %s -R %s %s' % (
        bold_file[i], new_file, bold_ref, xfm_file)
    log.run(cmd)



