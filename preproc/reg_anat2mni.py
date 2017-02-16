#!/usr/bin/env python

import os

from subjutil import *

parser = SubjParser()
parser.add_argument('template', help="Path to template image")
parser.add_argument('--new', '-n', action="store_true",
                    help="Use new ANTs registration functions")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('reganat', 'preproc', args)

log.start()

if args.new:
    reg_data = sp.path('anatomy', 'antsreg2', 'data')
    reg_xfm = sp.path('anatomy', 'antsreg2', 'transforms')
else:
    reg_data = sp.path('anatomy', 'antsreg', 'data')
    reg_xfm = sp.path('anatomy', 'antsreg', 'transforms')
log.run('mkdir -p %s' % reg_data)
log.run('mkdir -p %s' % reg_xfm)

xfm_base = os.path.join(reg_xfm, 'orig-template_')
t1_brain = sp.image_path('anatomy', 'orig_brain.nii.gz')
if args.new:
    cmd = 'antsRegistration -d 3 -o %s -i 30x90x20 -n BSpline -m MI[%s,%s,1,32] -t SyN[0.25] --use-Histogram-Matching' % (
        xfm_base)
else:
    # from buildtemplateparallel.sh
    log.run('ANTS 3 -m  CC[{template},{struct},1,5] -t SyN[0.25] -r Gauss[3,0] -o /work/03206/mortonne/lonestar/bender/gptemplate/highres_all/gp_highres_bender_02 -i 30x90x20 --use-Histogram-Matching  --number-of-affine-iterations 10000x10000x10000x10000x10000 --MI-option 32x16000'
    cmd = 'ANTS 3 -m PR[%s,%s,1,4] -t SyN[0.25] -r Gauss[3,0] -o %s -i 30x90x20 --use-Histogram-Matching' % (
        args.template, t1_brain, xfm_base)
log.run(cmd)

xfm_file = xfm_base + 'Affine.txt'
warp_file = xfm_base + 'Warp.nii.gz'
images = ['orig', 'orig_brain', 'brainmask', 'aparc+aseg']
labels = [False, False, True, True]
for i, image in enumerate(images):
    image_file = sp.image_path('anatomy', image)
    new_file = impath(reg_data, image)
    if labels[i]:
        cmd = 'WarpImageMultiTransform 3 %s %s -R %s --use-NN %s %s' % (
            image_file, new_file, args.template, warp_file, xfm_file)
    else:
        cmd = 'WarpImageMultiTransform 3 %s %s -R %s %s %s' % (
            image_file, new_file, args.template, warp_file, xfm_file)
    log.run(cmd)

log.finish()
