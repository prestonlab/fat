#!/usr/bin/env python

from subjutil import *
import os

parser = SubjParser()
parser.add_argument('template', help="path to template file")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('anatregcheck', 'preproc', args)

log.start()

# make sure a checks dir exists
checks_dir = sp.path('anatomy', 'antsreg', 'checks')
log.run('mkdir -p %s' % checks_dir)

anat_file = sp.image_path('anatomy', 'antsreg', 'data', 'orig_brain')
cmd = 'reg_slice_check.sh %s %s %s %s' % (
    anat_file, args.template, checks_dir, 'orig-template.png')
log.run(cmd)

log.finish()
