#!/usr/bin/env python

from subjutil import *
import skyra

parser = SubjParser()
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, 'rename', 'preproc',
              args.clean_logs, args.dry_run)

log.start()
skyra.rename_bold(sp, log)
skyra.rename_anat(sp, log)
log.finish()

