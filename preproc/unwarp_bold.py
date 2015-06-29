#!/usr/bin/env python

from subjutil import *
import os

parser = SubjParser()
parser.add_argument('--run-pattern', '-r',
                    help="regular expression for run directories",
                    metavar='regexp',
                    default='^\D+_\d+$')
parser.add_argument('--echo-spacing', help="effective EPI echo spacing",
                    default=0.00047)
parser.add_argument('--pedir', help="phase encoding direction",
                    default='y-')
parser.add_argument('--smooth3', help="smoothing for fieldmap",
                    default=1.444)
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, 'unwarpbold', 'preproc',
              args.clean_logs, args.dry_run)
log.start()

# find the runs to include
run_dirs = sp.bold(args.run_pattern)

for i in range(len(run_dirs)):
    bold = os.path.join(run_dirs[i], 'bold_mcf_brain_avg.nii.gz')
    fm_dir = os.path.join(run_dirs[i], 'fm')
    fm = os.path.join(fm_dir, 'epireg_fieldmaprads2epi.nii.gz')
    fm_mask = os.path.join(fm_dir,
                           'epireg_fieldmaprads2epi_mask.nii.gz')
    log.run('fslmaths %s -abs -bin %s' % (fm, fm_mask))

    # calculate the voxel shift and unwarp the average run image for
    # registraion purposes
    output = os.path.join(run_dirs[i], 'bold_mcf_brain_avg_unwarp.nii.gz')
    shift = os.path.join(fm_dir, 'epireg_fieldmaprads2epi_sm_shift.nii.gz')
    cmd = 'fugue -i %s --loadfmap=%s --mask=%s --dwell=%.6f --unwarpdir=%s --smooth3=%.6f -u %s --saveshift=%s --unmaskshift' % (
        bold, fm, fm_mask, args.echo_spacing, args.pedir, args.smooth3,
        output, shift)
    log.run(cmd)
log.finish()
