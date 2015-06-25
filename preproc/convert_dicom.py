#!/usr/bin/env python

from subjutil import *
import skyra

parser = SubjParser()
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, 'dcm2nii', 'preproc',
              args.clean_logs, args.dry_run)

# make sure standard directories exist
sp.make_std_dirs()
log.start()

skyra.dicom2nifti(sp, log)

log.finish()

