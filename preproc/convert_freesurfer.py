#!/usr/bin/env python

from subjutil import *
import os

parser = SubjParser()
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, 'postfs', 'preproc',
              args.clean_logs, args.dry_run)

src = sp.path('anatomy', args.subject, 'mri')
dest = sp.path('anatomy')

if not os.path.exists(src):
    raise IOError('FreeSurfer directory does not exist: %s' % src)

log.start()
src_names = ['orig', 'brainmask', 'aparc+aseg', 'wm']
dest_names = ['orig', 'orig_brain_auto', 'aparc+aseg', 'wm']
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

# use the FS parcelation to get an improved brain extraction

# smooth and threshold the identified tissues; fill any remaining holes
parcel = impath(dest, 'aparc+aseg')
mask = impath(dest, 'brainmask')
log.run('fslmaths %s -thr 0.5 -bin -s 0.25 -bin -fillh26 %s' % (
    parcel, mask))

# create a brain-extracted image
fs_brain = impath(dest, 'orig_brain_auto')
output = impath(dest, 'orig_brain')
log.run('fslmaths %s -mul %s %s' % (mask, fs_brain, output))

log.finish()
