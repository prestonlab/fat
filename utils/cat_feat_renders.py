#!/usr/bin/env python

import os
import sys

from subjutil import *

parser = SubjParser()
parser.add_argument('model', help="name of model")
parser.add_argument('runids', help="list of run ids")
parser.add_argument('ncope', help="number of COPEs")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('%s_check', 'preproc', args)

log.start()

out_dir = sp.path('model', args.model, 'checks')
if not os.path.exists(out_dir):
    os.mkdir(out_dir)

runs = args.runids.split(':')
for i in range(1, int(args.ncope)+1):
    cope_render = 'rendered_thresh_zstat%d.png' % i
    png_files = []
    for run in runs:
        run_dir = sp.path('model', args.model, '%s.feat' % run)
        png_files.append(os.path.join(run_dir, cope_render))
    out_file = os.path.join(out_dir, cope_render)
    log.run('pngappend %s %s' % (' + '.join(png_files), out_file))

log.finish()
