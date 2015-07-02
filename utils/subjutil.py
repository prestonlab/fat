#!/usr/bin/env python

import os
import re
import subprocess as sub
from datetime import datetime
from glob import glob
from argparse import ArgumentParser

def imname(filepath):
    return os.path.basename(filepath.split('.nii.gz')[0])

def impath(*args):
    p = os.path.join(*args)
    if not p.endswith('.nii.gz'):
        p += '.nii.gz'
    return p

class SubjParser(ArgumentParser):
    def __init__(self):
        ArgumentParser.__init__(self)
        self.add_argument('subject', type=str,
                          help="full subject identifier string")
        self.add_argument('--study-dir', type=str,
                          default=None, help="path to main study directory")
        self.add_argument('--dry-run',
                          help="display commands without executing",
                          default=False, action="store_true")
        self.add_argument('--clean-logs',
                          help="remove existing similar logs",
                          default=False, action="store_true")
    
class SubjPath:
    """Information about subject directory structure."""

    def __init__(self, subject, study_dir=None):

        self.subject = subject
        if study_dir:
            self.study_dir = study_dir
        else:
            self.study_dir = os.environ['STUDYDIR']
        self.subj_dir = os.path.join(self.study_dir, self.subject)
        self.dirnames = ['anatomy', 'behav', 'BOLD', 'DTI', 
                         'fieldmap', 'logs', 'model', 'raw']
        self.d = dict()
        self.d['base'] = self.subj_dir
        for dirname in self.dirnames:
            self.d[dirname.lower()] = os.path.join(self.subj_dir, dirname)

    def make_std_dirs(self):
        if not os.path.exists(self.d['base']):
            os.mkdir(self.d['base'])
        for std in self.dirnames:
            name = std.lower()
            if not os.path.exists(self.d[name]):
                os.mkdir(self.d[name])
        
    def path(self, std, *args):
        fulldir = os.path.join(self.d[std.lower()], *args)
        return fulldir

    def image_path(self, std, *args):
        return impath(self.path(std, *args))
    
    def proj_path(self, std, *args):
        proj_dir = os.path.dirname(os.path.dirname(__file__))
        fulldir = os.path.join(proj_dir, *args)
        return fulldir

    def glob(self, std, *args):
        paths = glob(os.path.join(self.d[std.lower()], *args))
        return paths

    def bold_dirs(self, run_pattern='^\D+_\d+$'):
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
        
    def bold_files(self, sepdirs=True, dir_pattern='^\D+_\d+$',
                   file_pattern='^\D+_\d+', file_ext='.nii.gz$',
                   filename='bold.nii.gz', subdir=None, suffix=None):
        if sepdirs:
            # find directories with standard names
            run_dirs = self.bold_dirs(dir_pattern)
            files = []
            for d in run_dirs:
                # create each full path
                full = os.path.join(d, filename)
                if os.path.isfile(full):
                    files.append(full)
        else:
            # look in one directory for all run files
            bold_dir = self.path('bold')
            if subdir:
                bold_dir = os.path.join(bold_dir, subdir)
            if suffix:
                pat = file_pattern + suffix + file_ext
            else:
                pat = file_pattern + file_ext

            # find files matching the specified pattern
            test = re.compile(pat)
            all_files = os.listdir(bold_dir)
            files = []
            for f in all_files:
                full = os.path.join(bold_dir, f)
                if test.match(f) and os.path.isfile(full):
                    files.append(full)
            files.sort()
        return files
    
    def bold(self, run_pattern='^\D+_\d+$'):
        # backwards compatibility
        return self.bold_dirs(run_pattern)

class SubjLog:
    """Class for logging subject processing."""

    def __init__(self, subject, base, main=None, rm_existing=False,
                 dry_run=False):

        self.subject = subject
        self.name = base
        self.dry_run = dry_run
        self.main_file = None

        # set the log file
        study_dir = os.environ['STUDYDIR']
        timestamp = datetime.now().strftime('%Y-%m-%d_%H-%M-%S')
        filename = base + '_' + timestamp + '.log'
        log_dir = os.path.join(study_dir, subject, 'logs')
        log_file = os.path.join(log_dir, filename)
        if main:
            filename = main + '.log'
            self.main_file = os.path.join(log_dir, filename)

        if rm_existing:
            # clear logs that match the supplied base
            existing = glob(os.path.join(log_dir, '%s_*.log' % base))
            for filepath in existing:
                os.remove(filepath)
        self.log_file = log_file

    def get_logo(self):
        proj_dir = os.path.dirname(os.path.dirname(__file__))
        logo_file = os.path.join(proj_dir, 'resources', 'prestonlab_logo.txt')
        f = open(logo_file, 'r')
        logo = f.read()
        f.close()
        return logo
        
    def timestamp(self):
        return datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
    def start(self):
        if self.dry_run:
            return
        
        # print a header
        self.write(self.get_logo(), wrap=False)
        msg = 'Starting %s for %s at: %s\n' % (
            self.name, self.subject, self.timestamp())
        self.write(msg, wrap=False)
        if self.main_file:
            self.write(msg, wrap=False, main_log=True)

    def finish(self):
        if self.dry_run:
            return

        msg = 'Finished %s for %s at: %s\n' % (
            self.name, self.subject, self.timestamp())
        self.write(msg, wrap=False)
        if self.main_file:
            self.write(msg, wrap=False, main_log=True)
        
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

    def write(self, message, wrap=True, main_log=False):
        if self.dry_run:
            print message
            return

        if main_log:
            outfile = open(self.main_file, 'a')
        else:
            outfile = open(self.log_file, 'a')
        if wrap:
            outfile.write('\nMESSAGE: ' + message + '\n')
        else:
            outfile.write(message)
        outfile.close()
