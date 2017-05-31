#!/usr/bin/env python

from subjutil import *
import os

parser = SubjParser()
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('postfs', 'preproc', args)

src = sp.path('anatomy', args.subject, 'mri')
dest = sp.path('anatomy')

if not os.path.exists(src):
    raise IOError('FreeSurfer directory does not exist: %s' % src)

log.start()
src_names = ['orig', 'brainmask', 'aparc+aseg']
dest_names = ['orig', 'orig_brain_auto', 'aparc+aseg']
for i in range(len(src_names)):
    src_file = os.path.join(src, src_names[i] + '.mgz')
    dest_file = os.path.join(dest, dest_names[i] + '.nii.gz')

    if not os.path.exists(src_file):
        log.write('FreeSurfer file not found: %s' % src_file)
        continue
    
    # convert to Nifti
    log.run('mri_convert %s %s' % (src_file, dest_file))

    # fix orientation
    log.run('fslreorient2std %s %s' % (dest_file, dest_file))

# register orig to highres
log.run('antsRegistration -d 3 -r [{ref},{src},1] -t Rigid[0.1] -m MI[{ref},{src},1,32,Regular,0.25] -c [1000x500x250x100,1e-6,10] -f 8x4x2x1 -s 3x2x1x0vox -n BSpline -w [0.005,0.995] -o {xfm}'.format(
        ref=impath(dest, 'highres'), src=impath(dest, 'orig'),
        xfm=os.path.join(dest, 'orig-highres_')))
o2h = os.path.join(dest, 'orig-highres_0GenericAffine.mat')
    
# use the FS parcelation to get an improved brain extraction

# mask for original brain extraction
brain_auto = impath(dest, 'orig_brain_auto')
mask_auto = impath(dest, 'brainmask_auto')
log.run('fslmaths %s -thr 0.5 -bin %s' % (brain_auto, mask_auto))

# smooth and threshold the identified tissues; fill any remaining holes
parcel = impath(dest, 'aparc+aseg')
mask_surf = impath(dest, 'brainmask_surf')
log.run('fslmaths %s -thr 0.5 -bin -s 0.25 -bin -fillh26 %s' % (
    parcel, mask_surf))

# take intersection with original mask (assumed to include all cortex,
# so don't want to extend beyond that)
mask = impath(dest, 'brainmask')
log.run('fslmaths %s -mul %s -bin %s' % (mask_surf, mask_auto, mask))

# create a brain-extracted image based on the orig image from
# freesurfer (later images have various normalization things done that
# won't match the MNI template as well)
orig = impath(dest, 'orig')
output = impath(dest, 'orig_brain')
log.run('fslmaths %s -mas %s %s' % (orig, mask, output))

# cortex
log.run('fslmaths %s -thr 1000 -bin %s' % (parcel, impath(dest, 'ctx')))

# cerebral white matter
log.run('fslmaths %s -thr 2 -uthr 2 -bin %s' % (parcel, impath(dest, 'l_wm')))
log.run('fslmaths %s -thr 41 -uthr 41 -bin %s' % (parcel, impath(dest, 'r_wm')))
log.run('fslmaths %s -add %s -bin %s' % (
    impath(dest, 'l_wm'), impath(dest, 'r_wm'), impath(dest, 'wm')))

log.finish()
