#!/usr/bin/env python

import os

from subjutil import *

s = """Prepare fieldmaps for use with unwarping functional scans.

Registers a fieldmap to a highres anatomical image, and uses a
brainmask in that space to mask the fieldmap images. Then runs
fsl_prepare_fieldmap to create an unwrapped image in radians/seconds
format, for use with epi_reg_run.py.

Required images: 

[subjdir]/anatomy/orig_brain.nii.gz - skull-stripped T1-weighted
image. If multiple images exist, should be named orig_brain1.nii.gz,
orig_brain2.nii.gz, etc. Set the -a flag to indicate which anatomical
image to use (e.g. 1 for orig_brain1.nii.gz)

[subjdir]/anatomy/brainmask.nii.gz - brain mask in the space of the
T1-weighted image. If multiple T1 scans exist, which be named
e.g. brainmask1.nii.gz.

[subjdir]/fieldmap/fieldmap_mag.nii.gz - fieldmap magnitude image. May
use either magnitude image for a given scan. If multiple images exist,
should be named e.g. fieldmap_mag1.nii.gz. Set the -f flag to indicate
which fieldmap images to use (e.g. 1 for fieldmap_mag1.nii.gz)

[subjdir]/fieldmap/fieldmap_phase.nii.gz - fieldmap phase image. If
multiple images exist, should be named e.g. fieldmap_phase1.nii.gz

For a given fieldmap scan, generally it is best to register to
whatever highres scan was collected closest in time to that image, in
order to minimize differences in distortion."""

parser = SubjParser(description=s, raw=True)
parser.add_argument('--dte', default=2.46,
    help="delta TE (time between the echo times of the two fieldmap scans). (default: 2.46)")
parser.add_argument('-a', '--anat', default='',
    help="anatomical image number (default: none)")
parser.add_argument('-f', '--fieldmap', default='',
    help="fieldmap image number (default: none)")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('prepfm{}'.format(args.fieldmap), 'preproc', args)

reg_xfm = sp.path('fieldmap', 'antsreg', 'transforms')

log.start()
log.run('mkdir -p {}'.format(reg_xfm))

# input images
mag = sp.image_path('fieldmap', 'fieldmap_mag{}'.format(args.fieldmap))
phase = sp.image_path('fieldmap', 'fieldmap_phase{}'.format(args.fieldmap))
highres_brain = sp.image_path('anatomy', 'orig_brain{}'.format(args.anat))
highres_mask = sp.image_path('anatomy', 'brainmask{}'.format(args.anat))

if not os.path.exists(mag):
    raise IOError('Magnitude image does not exist: {}'.format(mag))
if not os.path.exists(phase):
    raise IOError('Phase image does not exist: {}'.format(phase))
if not os.path.exists(phase):
    raise IOError('Highres image does not exist: {}'.format(highres_brain))
if not os.path.exists(highres_mask):
    raise IOError('Highres mask image does not exist: {}'.format(highres_mask))

# correct bias of magnitude image
mag_cor = sp.image_path('fieldmap', 'fieldmap_mag_cor{}'.format(args.fieldmap))
log.run('N4BiasFieldCorrection -d 3 -i {} -o {}'.format(mag, mag_cor))

# register the corrected magnitude image to the corrected highres
xfm_base = os.path.join(reg_xfm, 'fieldmap{}-orig{}_'.format(
    args.fieldmap, args.anat))
xfm_file = xfm_base + '0GenericAffine.mat'
log.run('antsRegistration -d 3 -r [{ref},{mov},1] -t Rigid[0.1] -m MI[{ref},{mov},1,32,Regular,0.25] -c [1000x500x250x100,1e-6,10] -f 8x4x2x1 -s 3x2x1x0vox -n BSpline -w [0.005,0.995] -o {xfm}'.format(
    ref=highres_brain, mov=mag_cor, xfm=xfm_base))

# use the highres brain mask to mask the magnitude image
mask_reg = sp.image_path('fieldmap', 'brainmask{}'.format(args.fieldmap))
mag_brain = sp.image_path('fieldmap', 'fieldmap_mag_brain{}'.format(args.fieldmap))
mag_cor_brain = sp.image_path('fieldmap', 'fieldmap_mag_cor_brain{}'.format(args.fieldmap))

log.run('antsApplyTransforms -i {} -o {} -r {} -t [{},1] -n NearestNeighbor'.format(
    highres_mask, mask_reg, mag, xfm_file))
log.run('fslmaths {mask} -fillh26 {mask}'.format(mask=mask_reg))
log.run('fslmaths {} -mas {} {}'.format(mag, mask_reg, mag_brain))
log.run('fslmaths {} -mas {} {}'.format(mag_cor, mask_reg, mag_cor_brain))

# convert the phase image to radians
rads = sp.image_path('fieldmap', 'fieldmap_rads_brain{}'.format(args.fieldmap))
log.run('fsl_prepare_fieldmap SIEMENS {} {} {} {}'.format(
    phase, mag_brain, rads, args.dte))

log.finish()
