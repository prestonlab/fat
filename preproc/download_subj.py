#!/usr/bin/env python

from subjutil import *
import os
import xnat_tools

parser = SubjParser()
parser.add_argument('--xnat-project', '-x', help='XNAT project name',
    default='preston')
parser.add_argument('--xnat-server', help='URL for xnat server', 
    default="https://xnat.irc.utexas.edu/xnat-irc")
parser.add_argument('--xnat-username',
    help='user name for xnat server', default='')
parser.add_argument('--xnat-password', 
    help='password for xnat server', default='')
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, 'download', 'preproc',
              args.clean_logs, args.dry_run)

# make sure standard directories exist
sp.make_std_dirs()
log.start()

log.write('Downloading DICOM files for %s...' % args.subject)
if not args.xnat_username or not args.xnat_password:
    xnat_tools.down_subject_dicoms(args.xnat_server, sp.path('raw'),
                                   args.xnat_project, args.subject)
else:
    xnat_tools.down_subject_dicoms(args.xnat_server, sp.path('raw'),
                                   args.xnat_project, args.subject,
                                   xnat_username=args.xnat_username,
                                   xnat_password=args.xnat_password)
log.finish()
