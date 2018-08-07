#!/usr/bin/env python

import os

from subjutil import *

parser = SubjParser()
parser.add_argument('featdir', help="path to feat directory")
args = parser.parse_args()

featname = os.path.splitext(os.path.basename(args.featdir))[0]

sp = SubjPath(args.subject, args.study_dir)
log = SubjLog(args.subject, 'identlev1_' + featname, 'model',
              args.clean_logs, args.dry_run)

# highres image for rendering level 2 results
highres = sp.image_path('anatomy', 'bbreg', 'data', 'orig_brain')

# identity transform that will leave images in native space
identity = sp.proj_path('resources', 'identity.mat')

log.start()

reg_dir = os.path.join(args.featdir, 'reg')
log.run('mkdir -p {}'.format(reg_dir))
log.run('ln -sf {} {}'.format(highres, impath(reg_dir, 'highres')))
log.run('ln -sf {} {}'.format(highres, impath(reg_dir, 'standard')))
log.run('cp {} {}'.format(
    identity, os.path.join(reg_dir, 'standard2example_func.mat')))
log.run('cp {} {}'.format(
    identity, os.path.join(reg_dir, 'example_func2standard.mat')))
log.run('updatefeatreg {} -pngs'.format(args.featdir))

log.finish()
