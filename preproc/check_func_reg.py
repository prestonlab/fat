#!/usr/bin/env python

from subjutil import *
import os

parser = SubjParser()
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('funcregcheck', 'preproc', args)

log.start()

# make sure a checks dir exists
checks_dir = sp.path('bold', 'antsreg', 'checks')
log.run('mkdir -p %s' % checks_dir)

png_files = []
bold1_files = []
bold_dir = sp.path('bold', 'antsreg', 'data')
refvol = impath(bold_dir, 'refvol')
bold_files = sp.bold_files(sepdirs=False, subdir='antsreg/data')
for bold_file in bold_files:
    name = imname(bold_file)

    # get the first volume of the run
    bold1_file = impath(bold_dir, name + '_vol1')
    log.run('fslroi %s %s 0 1' % (bold_file, bold1_file))

    output = '%s-refvol.png' % name
    cmd = 'reg_slice_check.sh %s %s %s %s' % (
        bold1_file, refvol, checks_dir, output)
    log.run(cmd)
    png_files.append(os.path.join(checks_dir, output))
    bold1_files.append(bold1_file)

# create an image with all runs
out_file = os.path.join(checks_dir, 'regcheck.png')
if os.path.exists(out_file):
    log.run('rm %s' % out_file)
log.run('pngappend %s %s' % (' - '.join(png_files), out_file))
log.run('rm %s' % ' '.join(png_files))
log.run('rm %s' % ' '.join(bold1_files))

log.finish()
