#!/usr/bin/env python

from subjutil import *
import skyra

parser = SubjParser()
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('dcm2nii', 'preproc', args)

# make sure standard directories exist
sp.make_std_dirs()
log.start()

skyra.dicom2nifti(sp, log)

log.finish()

