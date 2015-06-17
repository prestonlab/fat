#!/usr/bin/env python

import os
import re
import subprocess as sub
from datetime import datetime
from glob import glob
from argparse import ArgumentParser

class SubjParser(ArgumentParser):
    def __init__(self):
        ArgumentParser.__init__(self)
        self.add_argument('subject', type=str,
                          help="full subject identifier string")
        self.add_argument('--dry-run',
                          help="display commands without executing",
                          default=False, action="store_true")
        self.add_argument('--clean-logs',
                          help="remove existing similar logs",
                          default=False, action="store_true")
    
class SubjPath:
    """Information about subject directory structure."""

    def __init__(self, subject):

        self.subject = subject
        self.study_dir = os.environ['STUDYDIR']
        self.subj_dir = os.path.join(self.study_dir, self.subject)
        self.d = dict()
        
        self.d['base'] = self.subj_dir
        dirnames = ['anatomy', 'behav', 'BOLD', 'DTI', 'fieldmap', 'logs',
                    'model', 'raw']
        for dirname in dirnames:
            self.d[dirname.lower()] = os.path.join(self.subj_dir, dirname)
    
        self.d['anatomy.antsreg.xfm'] = os.path.join(self.d['anatomy'],
                                                     'antsreg', 'transforms')
        self.d['anatomy.antsreg.data'] = os.path.join(self.d['anatomy'],
                                                      'antsreg', 'data')
    def path(self, std, *args):
        fulldir = os.path.join(self.d[std], *args)
        return fulldir

    def glob(self, std, *args):
        paths = glob(os.path.join(self.d[std], *args))
        return paths

    def bold(self, run_pattern='^\D+_\d+$'):
        bold_dir = self.path('bold')
        d = os.listdir(bold_dir)
        test = re.compile(run_pattern)
        run_dirs = []
        for i in range(len(d)):
            full = os.path.join(bold_dir, d[i])
            if test.match(d[i]) and os.path.isdir(full):
                run_dirs.append(full)
        run_dirs.sort()
        return run_dirs

class SubjLog:
    """Class for logging subject processing."""

    def __init__(self, subject, base, rm_existing=False, dry_run=False):

        self.subject = subject
        self.dry_run = dry_run

        # set the log file
        study_dir = os.environ['STUDYDIR']
        timestamp = datetime.now().strftime('%Y_%m_%d_%H_%M_%S')
        filename = base + '_' + timestamp + '.log'
        log_dir = os.path.join(study_dir, subject, 'logs')
        log_file = os.path.join(log_dir, filename)

        if rm_existing:
            # clear logs that match the supplied base
            existing = glob(os.path.join(log_dir, '%s_*.log' % base))
            for filepath in existing:
                os.remove(filepath)
        self.log_file = log_file

    def run(self, cmd):

        if self.dry_run:
            print cmd
            return
        
        # open log file and print command to run
        outfile = open(self.log_file, 'a')
        outfile.write('\nRUNNING: ' + cmd + '\n')

        # actually running the command
        p = sub.Popen(cmd, stdout=sub.PIPE, stderr=sub.PIPE, shell=True)
        output, errors = p.communicate()
        if output:
            outfile.write('OUTPUT:  ' + output)
        if errors:
            outfile.write('ERROR:   ' + errors)
            print '%s: ERROR: ' % self.subject + errors
        outfile.close()

    def write(self, message):
        outfile = open(self.log_file, 'a')
        outfile.write('\nMESSAGE: ' + message + '\n')
        outfile.close()
