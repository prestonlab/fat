#!/usr/bin/env python

from subjutil import *
import os
import re

s = """Tranform anatomical images to native functional space.

Given transformation information calculated using epi_reg_ants,
transforms commonly used anatomical images to native functional space.

You must specify the reference run, which specifies which run to use
as the common native functional space.

If you have multiple anatomical scans for each subject, use the -a
flag to specify which anatomical images to transform (e.g., '2' to
specify the anatomical image collected on day 2).

By default, will transform a number of commonly used anatomical images
and masks. Can customize using the --images and --labels flags.
"""

parser = SubjParser(description=s, raw=True)
parser.add_argument('refrun', help="reference run")
parser.add_argument('-a', '--anat', default='',
    help="anatomical image number (default: none)")
parser.add_argument('--images', '-i',
                    help="file names of images to transform",
                    default='orig orig_brain')
parser.add_argument('--labels', '-l',
                    help="file names of label images (e.g. masks)",
                    default='aparc+aseg ctx wm brainmask')
args = parser.parse_args()

images = args.images.split()
labels = args.labels.split()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('anat2func', 'preproc', args)
log.start()

# prepare transformation directories
reg_data = sp.path('anatomy', 'bbreg', 'data')
reg_xfm = sp.path('anatomy', 'bbreg', 'transforms')
reg_check = sp.path('anatomy', 'bbreg', 'checks')
log.run('mkdir -p %s' % reg_data)
log.run('mkdir -p %s' % reg_xfm)
log.run('mkdir -p %s' % reg_check)

# copy transformation parameters from the reference run
inv_file = sp.path('bold', args.refrun, 'fm', 'epireg_inv.mat')
anat2func = os.path.join(reg_xfm, 'highres-refvol.mat')
log.run('cp %s %s' % (inv_file, anat2func))
refvol = sp.image_path('bold', args.refrun, 'bold_cor_mcf_avg_unwarp_brain')

# apply the transformation to each structural file of interest
for image_name in images:
    in_file = sp.image_path('anatomy', image_name + args.anat)
    out_file = impath(reg_data, image_name)
    cmd = 'flirt -interp spline -in %s -ref %s -applyxfm -init %s -out %s' % (
        in_file, refvol, anat2func, out_file)
    log.run(cmd)

# can't use interpolation on label images
for image_name in labels:
    in_file = sp.image_path('anatomy', image_name + args.anat)
    out_file = impath(reg_data, image_name)
    cmd = 'flirt -interp nearestneighbour -in %s -ref %s -applyxfm -init %s -out %s' % (
        in_file, refvol, anat2func, out_file)
    log.run(cmd)

# run a check on the registration
image_file = impath(reg_data, images[0])
png_file = '%s2refvol.png' % images[0]
cmd = 'reg_slice_check.sh %s %s %s %s' % (
    image_file, refvol, reg_check, png_file)
log.run(cmd)
    
log.finish()
