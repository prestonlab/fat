#!/usr/bin/env python

import os

from subjutil import *

parser = SubjParser()
parser.add_argument('model', help="name of model")
parser.add_argument('--feat-pattern', '-f',
                    help="regular expression for feat directories (default: ^\D+_\d+\.feat$)",
                    metavar='regexp',
                    default='^\D+_\d+\.feat$')
parser.add_argument('--anat', '-a',
                    default="anatomy/bbreg/data/orig_brain",
                    help="path to anatomical image in functional space, relative to subject directory (default: anatomy/bbreg/data/orig_brain)")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('%s_level1_ident' % args.model, 'model', args)

feat_dirs = sp.feat_dirs(args.model)

highres = impath(sp.subj_dir, args.anat)
identity = sp.proj_path('resources', 'identity.mat')

log.start()
for feat in feat_dirs:
    reg_dir = os.path.join(feat, 'reg')
    log.run('mkdir -p %s' % reg_dir)
    log.run('ln -sf %s %s' % (highres, impath(reg_dir, 'highres')))
    log.run('ln -sf %s %s' % (highres, impath(reg_dir, 'standard')))
    log.run('cp %s %s' % (
        identity, os.path.join(reg_dir, 'standard2example_func.mat')))
    log.run('cp %s %s' % (
        identity, os.path.join(reg_dir, 'example_func2standard.mat')))
    log.run('updatefeatreg %s -pngs' % feat)

log.finish()
