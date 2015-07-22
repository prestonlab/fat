#!/usr/bin/env python

from subjutil import *
import os

parser = SubjParser()
parser.add_argument('--run-pattern', '-r',
                    help="regular expression for run directories",
                    metavar='regexp',
                    default='^\D+_\d+$')
args = parser.parse_args()

sp = SubjPath(args.subject)
log = SubjLog(args.subject, 'collectqa', 'preproc',
              args.clean_logs, args.dry_run)
log.start()

collect_dir = sp.path('bold', 'QA')
log.run('mkdir -p %s' % collect_dir)

# find all directories in the BOLD directory
run_dirs = sp.bold(args.run_pattern)
for run_dir in run_dirs:
    src = os.path.join(run_dir, 'QA', 'QA_report.pdf')
    run_name = os.path.basename(run_dir)
    dest = os.path.join(collect_dir, '%s_QA_report.pdf' % run_name)
    log.run('cp %s %s' % (src, dest))

log.finish()
