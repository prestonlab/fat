#!/usr/bin/env python

import os

from subjutil import *

parser = SubjParser()
parser.add_argument('template', help="Path to template image")
parser.add_argument('-a', '--anat', default='',
    help="anatomical image number (default: none)")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('reganat', 'preproc', args)

log.start()

reg_data = sp.path('anatomy', 'antsreg', 'data')
reg_xfm = sp.path('anatomy', 'antsreg', 'transforms')
log.run('mkdir -p %s' % reg_data)
log.run('mkdir -p %s' % reg_xfm)

xfm_base = os.path.join(reg_xfm, 'orig-template_')
highres = sp.image_path('anatomy', 'orig_brain' + args.anat)
highres_cor = sp.image_path('anatomy', 'orig_brain_cor{}'.format(args.anat))

log.run('N4BiasFieldCorrection -d 3 -i {} -o {}'.format(highres, highres_cor))

# from buildtemplateparallel.sh
log.run('ANTS 3 -m CC[{template},{highres},1,5] -t SyN[0.25] -r Gauss[3,0] -o {xfm} -i 30x90x20 --use-Histogram-Matching  --number-of-affine-iterations 10000x10000x10000x10000x10000 --MI-option 32x16000'.format(
    template=args.template, highres=highres_cor, xfm=xfm_base))

xfm_file = xfm_base + 'Affine.txt'
warp_file = xfm_base + 'Warp.nii.gz'
images = ['orig', 'orig_brain', 'brainmask', 'aparc+aseg', 'wm', 'ctx']
labels = [False, False, True, True, True, True]
for i, image in enumerate(images):
    # add optional anatomical number to the input image name
    image_file = sp.image_path('anatomy', image + args.anat)

    # remove it from the destination image
    new_file = impath(reg_data, image)
    if labels[i]:
        cmd = 'WarpImageMultiTransform 3 %s %s -R %s --use-NN %s %s' % (
            image_file, new_file, args.template, warp_file, xfm_file)
    else:
        cmd = 'WarpImageMultiTransform 3 %s %s -R %s %s %s' % (
            image_file, new_file, args.template, warp_file, xfm_file)
    log.run(cmd)

log.finish()
