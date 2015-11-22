#!/usr/bin/env python

import os
import subprocess as sub
import numpy as np

from subjutil import *

parser = SubjParser()
parser.add_argument('task', help='task name')
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('cleanbold', 'preproc', args)

log.start()

pattern = 'functional_%s_\d+' % args.task
files = sp.bold_files(dir_pattern=pattern)

# get the number of volumes for each scan in this task
n_vols = []
for f in files:
    cmd = 'fslinfo %s | grep "^dim4" | tr -s " " | cut -d " " -f 2' % f
    p = sub.Popen(cmd, stdout=sub.PIPE, stderr=sub.PIPE, shell=True)
    output, errors = p.communicate()
    n_vols.append(int(output))

# delete short runs
isshort = n_vols < np.max(n_vols)
if np.any(isshort):
    ind = np.nonzero(isshort)[0]
    for i in ind:
        log.run('rm %s' % files[i])
        parent = os.path.dirname(files[i])
        log.run('rmdir %s' % parent)
else:
    log.write('No short runs found. Quitting...')
    
log.finish()
