#!/usr/bin/env python

import os

from subjutil import *

parser = SubjParser()
parser.add_argument('template', help="Path to template image")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = SubjLog(args.subject, 'reganat', 'preproc',
              args.clean_logs, args.dry_run)

log.start()

reg_data = sp.path('anatomy', 'antsreg', 'data')
reg_xfm = sp.path('anatomy', 'antsreg', 'transforms')
log.run('mkdir -p %s' % reg_data)
log.run('mkdir -p %s' % reg_xfm)

xfm_base = os.path.join(reg_xfm, 'orig-template_')
t1_brain = sp.image_path('anatomy', 'orig_brain.nii.gz')
cmd = 'ANTS 3 -m PR[%s,%s,1,4] -t SyN[0.25] -r Gauss[3,0] -o %s -i 30x90x20 --use-Histogram-Matching' % (
    args.template, t1_brain, xfm_base)
log.run(cmd)

xfm_file = xfm_base + 'Affine.txt'
warp_file = xfm_base + 'Warp.nii.gz'
images = ['orig', 'orig_brain', 'aparc+aseg']
labels = [False, False, True]
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
