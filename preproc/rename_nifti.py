#!/usr/bin/env python

from subjutil import *
import skyra

parser = SubjParser()
args = parser.parse_args()
sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('rename', 'preproc', args)

log.start()
skyra.rename_bold(sp, log)
skyra.rename_anat(sp, log)
log.finish()

