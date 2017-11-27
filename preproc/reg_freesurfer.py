#!/usr/bin/env python

from subjutil import *
import os
from glob import glob

parser = SubjParser(description="Register FreeSurfer output to original anatomical spaces.")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('postfs', 'preproc', args)

log.start()

# look for registration between scans
dest = sp.path('anatomy')
reg_dir_list = glob(os.path.join(dest, 'highres?_highres?'))
if not reg_dir_list:
    raise IOError('Cannot find registration between different highres scans.')
elif len(reg_dir_list) > 1:
    raise IOError('Found multiple registrations between scans.')
reg_dir = reg_dir_list[0]

# unpack which scan was used as reference in the registration
movname, fixname = os.path.basename(reg_dir).split('_')
movnum = movname.split('highres')[1]
fixnum = fixname.split('highres')[1]

# register orig to highres
log.run('antsRegistration -d 3 -r [{ref},{src},1] -t Rigid[0.1] -m MI[{ref},{src},1,32,Regular,0.25] -c [1000x500x250x100,1e-6,10] -f 8x4x2x1 -s 3x2x1x0vox -n BSpline -w [0.005,0.995] -o {xfm}'.format(
        ref=impath(dest, 'highres'), src=impath(dest, 'orig'),
        xfm=os.path.join(dest, 'orig-highres_')))
o2h = os.path.join(dest, 'orig-highres_0GenericAffine.mat')

h2h_affine = os.path.join(dest, reg_dir, 'mov-fix_0GenericAffine.mat')
h2h_warp = os.path.join(dest, reg_dir, 'mov-fix_1InverseWarp.nii.gz')
images = ['orig', 'orig_brain', 'brainmask', 'aparc+aseg', 'ctx', 'wm']
labels = [False, False, True, True, True, True]
for image, label in zip(images, labels):
    if label:
        interp = 'NearestNeighbor'
    else:
        interp = 'BSpline'
        
    # transform to the space of the moving image
    log.run('antsApplyTransforms -i {} -o {} -r {} -t [{},1] -t {} -t {} -n {}'.format(
        impath(dest, image), impath(dest, image + movnum),
        impath(dest, 'highres' + movnum), h2h_affine, h2h_warp, o2h, interp))

    # transform to the space of the fixed image
    log.run('antsApplyTransforms -i {} -o {} -r {} -t {} -n {}'.format(
        impath(dest, image), impath(dest, image + fixnum),
        impath(dest, 'highres' + fixnum), o2h, interp))

log.finish()
