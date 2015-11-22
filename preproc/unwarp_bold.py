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

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('unwarpbold', 'preproc', args)
log.start()

# find the runs to include
run_dirs = sp.bold(args.run_pattern)

for i in range(len(run_dirs)):
    bold = impath(run_dirs[i], 'bold_mcf_brain_avg')
    fm_dir = os.path.join(run_dirs[i], 'fm')
    fm = impath(fm_dir, 'epireg_fieldmaprads2epi')
    fm_mask = impath(fm_dir, 'epireg_fieldmaprads2epi_mask')
    log.run('fslmaths %s -abs -bin %s' % (fm, fm_mask))

    # calculate the voxel shift and unwarp the average run image for
    # registration purposes
    output = impath(run_dirs[i], 'bold_mcf_brain_avg_unwarp')
    shift = impath(fm_dir, 'epireg_fieldmaprads2epi_sm_shift')
    cmd = 'fugue -i %s --loadfmap=%s --mask=%s --dwell=%.6f --unwarpdir=%s --smooth3=%.6f -u %s --saveshift=%s --unmaskshift' % (
        bold, fm, fm_mask, args.echo_spacing, args.pedir, args.smooth3,
        output, shift)
    log.run(cmd)
log.finish()
