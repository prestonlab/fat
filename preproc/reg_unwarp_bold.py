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
log = sp.init_log('regunwarpbold', 'preproc', args)
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
avg_ref = sp.path('bold', args.refrun, 'bold_mcf_brain_avg_cor_unwarp.nii.gz')
refvol = os.path.join(reg_data, 'refvol.nii.gz')
log.run('cp %s %s' % (avg_ref, refvol))

# calculate and apply the tranformation for every non-reference run
for run_dir in run_dirs:
    run_name = os.path.basename(run_dir)
    fm_dir = os.path.join(run_dir, 'fm')
    bold_file = impath(run_dir, 'bold')
    avg_file = impath(run_dir, 'bold_mcf_brain_avg_cor_unwarp')
    new_file = impath(reg_data, run_name)

    # preprare registration and unwarping
    mcf_file = os.path.join(run_dir, 'bold_cor_mcf.cat')
    warp_file = impath(fm_dir, 'epireg_epi_warp')
    reg_warp_file = impath(fm_dir, 'epireg_reg_warp')
    if run_name == args.refrun:
        # no registration needed; just prep unwarping
        cmd = 'convertwarp -r %s --premat=%s -w %s -o %s --rel' % (
            refvol, mcf_file, warp_file reg_warp_file)
        log.run(cmd)
    else:
        # calculate transform
        xfm_base = os.path.join(reg_xfm, '%s-refvol_' % run_name)
        log.run('antsRegistration -d 3 -r [%s,%s,1] -t Rigid[0.1] -m MI[%s,%s,1,32,Regular,0.25] -c [1000x500x250x100,1e-6,10] -f 8x4x2x1 -s 3x2x1x0vox -n BSpline -w [0.005,0.995] -o %s' % (
            refvol, avg_file, refvol, avg_file, xfm_base))

        # convert to text format
        itk_file = xfm_base + '0GenericAffine.mat'
        txt_file = xfm_base + '0GenericAffine.txt'
        mat_file = os.path.join(reg_xfm, '%s-refvol.mat')
        log.run('ConvertTransformFile 3 %s %s' % (itk_file, txt_file))

        # convert to FSL format
        log.run('c3d_affine_tool -itk %s -ref %s -src %s -ras2fsl -o %s' % (
            txt_file, refvol, avg_file, mat_file)

        # set to motion correct, unwarp, and register
        cmd = 'convertwarp -r %s -s %s --postmat=%s -o %s --rel' % (
            refvol, shift_file, mat_file, warp_file)
        log.run(cmd)

    # apply unwarping and transformation
    cmd = 'applywarp -i %s -r %s -o %s -w %s --interp=spline --rel' % (
        bold_file, refvol, new_file, warp_file)
    log.run(cmd)
log.finish()

