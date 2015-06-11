#!/usr/bin/env python

import os
import subprocess as sub
from datetime import datetime
from glob import glob

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

        # open log file and print command to run
        outfile = open(self.log_file, 'a')
        outfile.write('\nRunning: ' + cmd + '\n')
        if not self.dry_run:
            # actually running the command
            p = sub.Popen(cmd, stdout=sub.PIPE, stderr=sub.PIPE, shell=True)
            output, errors = p.communicate()
            outfile.write('Output: ' + output)
            if errors:
                outfile.write('ERROR: ' + errors)
                print '%s: ERROR: ' % self.subject + errors
        outfile.close()

    def write(self, message):
        outfile = open(self.log_file, 'a')
        outfile.write(message + '\n')
        outfile.close()
