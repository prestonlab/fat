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

sp = SubjPath(args.subject, args.study_dir)
log = SubjLog(args.subject, 'regunwarpbold', 'preproc',
              args.clean_logs, args.dry_run)
log.start()

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

# copy the reference
avg_ref = sp.path('bold', args.refrun, 'bold_mcf_brain_avg_unwarp.nii.gz')
refvol = os.path.join(reg_data, 'refvol.nii.gz')
log.run('cp %s %s' % (avg_ref, refvol))

# calculate and apply the tranformation for every non-reference run
for i in range(len(run_dirs)):
    run_name = os.path.basename(run_dirs[i])
    fm_dir = os.path.join(run_dirs[i], 'fm')
    bold_file = os.path.join(run_dirs[i], 'bold_mcf_brain.nii.gz')
    avg_file = os.path.join(run_dirs[i], 'bold_mcf_brain_avg_unwarp.nii.gz')
    new_file = os.path.join(reg_data, run_name + '.nii.gz')

    # preprare registration and unwarping
    shift_file = os.path.join(fm_dir,
                              'epireg_fieldmaprads2epi_sm_shift.nii.gz')
    warp_file = os.path.join(fm_dir, 'epireg_reg_warp.nii.gz')
    if run_name == args.refrun:
        # no registration needed; just prep unwarping
        cmd = 'convertwarp -r %s -s %s -o %s --shiftdir=y- --relout' % (
            refvol, shift_file, warp_file)
        log.run(cmd)
    else:
        # calculate transform
        xfm_base = os.path.join(reg_xfm, '%s-refvol_' % run_name)
        cmd = 'ANTS 3 -m CC[%s,%s,1,32] -o %s --rigid-affine -i 0' % (
            refvol, avg_file, xfm_base)
        log.run(cmd)

        # convert to FSL format
        xfm_file = xfm_base + 'Affine.txt'
        mat_file = xfm_base + 'Affine.mat'
        cmd = 'c3d_affine_tool -itk %s -ref %s -src %s -ras2fsl -o %s' % (
            xfm_file, refvol, avg_file, mat_file)
        log.run(cmd)

        # set to unwarp, then transform
        cmd = 'convertwarp -r %s -s %s --postmat=%s -o %s --shiftdir=y- --relout' % (
            refvol, shift_file, mat_file, warp_file)
        log.run(cmd)

    # apply unwarping and transformation
    cmd = 'applywarp -i %s -r %s -o %s -w %s --interp=spline --rel' % (
        bold_file, refvol, new_file, warp_file)
    log.run(cmd)
log.finish()

