#!/usr/bin/env python

from subjutil import *

parser = SubjParser()
parser.add_argument('--reg', '-r', help='registration type', default='bbreg')
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('anatrois', 'preproc', args)

log.start()
data_dir = sp.path('anatomy', args.reg, 'data')
parc_file = impath(data_dir, 'aparc+aseg')
log.run('roi_freesurfer.sh %s %s' % (parc_file, data_dir))
log.finish()
