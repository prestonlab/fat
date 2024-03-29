#!/usr/bin/env python

from subjutil import *
import os

s = """Register functional scan to anatomical space and unwarp.

Assumes you have already run prep_fieldmap.py or similar to skull-strip
your fieldmap scan and calculate an image with radians/second, and that
you have a white-matter mask in structural image space generated from
FreeSurfer.

Required images:

[subjdir]/anatomy/origX.nii.gz - highres anatomical image (X indicates
    anatomical scan number; if none specified, X is omitted)
[subjdir]/anatomy/orig_brainX.nii.gz - skull-stripped highres image
[subjdir]/anatomy/brainmaskX.nii.gz - brain mask for highres image
[subjdir]/anatomy/wmX.nii.gz - white matter mask for highres image

[subjdir]/fieldmap/fieldmap_mag_corX.nii.gz - fieldmap magnitude
    (X indicates fieldmap scan number; if none specified, X is omitted)
[subjdir]/fieldmap/fieldmap_mag_cor_brainX.nii.gz - skull-stripped
    magnitude image
[subjdir]/fieldmap/fieldmap_rads_brainX.nii.gz - fieldmap image in
    radians/second.

[subjdir]/BOLD/[runid]/bold_cor_mcf_avg.nii.gz - functional image to 
    register to structural space and calculate unwarping.

See also: prep_fieldmap.py, reg_unwarp_bold_run.py.
"""

parser = SubjParser(description=s, raw=True)
parser.add_argument('runid', help="run identifier")
parser.add_argument('ees', help="effective echo spacing (s)", type=float)
parser.add_argument('-a', '--anat', help="anatomical number (default: none)",
                    default='')
parser.add_argument('-f', '--fieldmap', help="fieldmap number (default: none)",
                    default='')
parser.add_argument('-p', '--pedir', default='y-',
                    help="phase encoding direction (default: y-)")
parser.add_argument('-k', '--keep', help="keep intermediate files",
                    action='store_true')
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('epireg_%s' % args.runid, 'preproc', args)

log.start()

map_dir = sp.path('fieldmap')

# structural files (use the one collected that day)
highres = sp.image_path('anatomy', 'orig{}'.format(args.anat))
highres_brain = sp.image_path('anatomy', 'orig_brain{}'.format(args.anat))
highres_mask = sp.image_path('anatomy', 'brainmask{}'.format(args.anat))
wm_mask = sp.image_path('anatomy', 'wm{}'.format(args.anat))

if not os.path.exists(highres):
    raise IOError('Highres does not exist: {}'.format(highres))
if not os.path.exists(highres_brain):
    raise IOError('Highres brain does not exist: {}'.format(highres_brain))
if not os.path.exists(highres_mask):
    raise IOError('Highres mask does not exist: {}'.format(highres_mask))
if not os.path.exists(wm_mask):
    raise IOError('White matter mask does not exist: {}'.format(wm_mask))

# epi files
epi_dir = sp.path('bold', args.runid)
epi_input = impath(epi_dir, 'bold_cor_mcf_avg')
epi_output = impath(epi_dir, 'bold_cor_mcf_avg_unwarp_brain')
if not os.path.exists(epi_input):
    raise IOError('EPI input does not exist: {}'.format(epi_input))

# prepare output directory
fm_dir = sp.path('bold', args.runid, 'fm')
out_base = os.path.join(fm_dir, 'epireg')
log.run('mkdir -p %s' % fm_dir)

# more than one fieldmap; must specify
fmap = impath(map_dir, 'fieldmap_rads_brain{}'.format(args.fieldmap))
fmapmag = impath(map_dir, 'fieldmap_mag_cor{}'.format(args.fieldmap))
fmapmagbrain = impath(map_dir,
                      'fieldmap_mag_cor_brain{}'.format(args.fieldmap))

if not os.path.exists(fmap):
    raise IOError('Fieldmap does not exist: {}'.format(fmap))
if not os.path.exists(fmapmag):
    raise IOError('Fieldmap magnitude does not exist: {}'.format(fmapmag))
if not os.path.exists(fmapmagbrain):
    raise IOError('Fieldmap magnitude brain does not exist: {}'.format(fmapmagbrain))
    
# run epi_reg
cmd = 'epi_reg_ants --fmap=%s --fmapmag=%s --fmapmagbrain=%s --wmseg=%s --echospacing=%.06f --pedir=%s -v --epi=%s --t1=%s --t1brain=%s --out=%s --noclean' % (
    fmap, fmapmag, fmapmagbrain, wm_mask, args.ees, args.pedir, epi_input, highres,
    highres_brain, out_base)
log.run(cmd)

# convert shift map to a warp
shift = impath(fm_dir, 'epireg_fieldmaprads2epi_shift')
warp = impath(fm_dir, 'epireg_epi_warp')
log.run('convertwarp -r %s -s %s -o %s --shiftdir=%s --relout' % (
    epi_input, shift, warp, args.pedir))

# unwarp the average run image for registration purposes
epi_unwarped = impath(fm_dir, 'epireg_epi_unwarped')
log.run('applywarp -i %s -r %s -o %s -w %s --interp=spline --rel' % (
    epi_input, epi_input, epi_unwarped, warp))

# transform the anatomical brain mask into functional space
mask_reg = impath(fm_dir, 'brainmask')
log.run('flirt -in %s -ref %s -applyxfm -init %s -out %s -interp nearestneighbour' % (
    highres_mask, epi_unwarped, os.path.join(fm_dir, 'epireg_inv.mat'),
    mask_reg))

# dilate to make a tighter brain extraction than the liberal one
# originally used for the functionals
log.run('fslmaths %s -kernel sphere 3 -dilD %s' % (mask_reg, mask_reg))

# mask the unwarped epi
log.run('fslmaths %s -mas %s %s' % (epi_unwarped, mask_reg, epi_output))

if not args.keep:
    log.run('rm -f %s/{epireg,epireg_fieldmap*,epireg_1vol,epireg_fast*,epireg_epi_unwarped,epireg_warp}.nii.gz' % fm_dir)

log.finish()
