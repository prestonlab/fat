#!/usr/bin/env python

from subjutil import *

parser = SubjParser()
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, 'anatrois', 'preproc',
              args.clean_logs, args.dry_run)

log.start()
data_dir = sp.path('anatomy', 'bbreg', 'data')
parc_file = impath(data_dir, 'aparc+aseg')
log.run('roi_freesurfer.sh %s %s' % (parc_file, data_dir))
log.finish()
