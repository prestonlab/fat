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
dest_names = ['orig', 'orig_brain', 'aparc+aseg', 'wm']
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
log.finish()
