#!/usr/bin/env python

from subjutil import *
import os

parser = SubjParser()
parser.add_argument('tr', help='repetition time', type=float)
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, 'prepbold', 'preproc',
              args.clean_logs, args.dry_run)

log.start()
bold_dirs = sp.bold()
base = {}
mcf = {}
mcf_brain = {}
for d in bold_dirs:
    base[d] = os.path.join(d, 'bold.nii.gz')
    mcf[d] = os.path.join(d, 'bold_mcf.nii.gz')
    mcf_brain[d] = os.path.join(d, 'bold_mcf_brain.nii.gz')

# motion correction
for d in bold_dirs:
    log.run('mcflirt -in %s -plots -sinc_final' % base[d])

# brain extraction
for d in bold_dirs:
    log.run('bet %s %s -F' % (mcf[d], mcf_brain[d]))

# quality assurance
for d in bold_dirs:
    log.run('fmriqa.py %s %f' % (mcf[d], args.tr))
    
log.finish()


