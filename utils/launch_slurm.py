#!/usr/bin/env python

# launch script for stampede
# deals with both command files for parametric launcher and with single commands

import argparse
import sys,os
from tempfile import *
import subprocess
import math

CORES={'normal':24, 'largemem':32, 'hugemem': 20,
       'development':24, 'gpu':10}
MAXNODES={'normal':171, 'largemem':342, 'hugemem': 2,
          'development':11, 'gpu':4}
MAXCORES={'normal':4104, 'largemem':8208, 'hugemem': 40,
          'development':264, 'gpu':40}

def launch_slurm(serialcmd='', script_name=None, runtime='01:00:00',
                 jobname='launch', outfile=None, projname=None, queue='normal',
                 email=None, qsubfile=None, keepqsubfile=False,
                 test=False, compiler='intel', hold=None, cwd=None,
                 nnodes=None, ntasks=None, tpn=None):

    cmd = serialcmd
    
    if len(cmd) > 0:
        parametric = False
        print 'Running serial command: ' + cmd
        ncmds = 1
        nnodes = 1
        ntasks = 1
    elif script_name is not None:
        parametric = True
        print 'Submitting parametric job file: ' + script_name
        try:
            f = open(script_name, 'r')
        except:
            print '%s does not exist!' % script_name
            sys.exit(0)
        script_cmds = f.readlines()
        f.close()
        ncmds = len(script_cmds)
        print 'found %d commands' % ncmds
        # need to check for empty lines
        for s in script_cmds:
            if s.strip() == '':
                print 'command file contains empty lines - please remove them first'
                sys.exit()
    else:
        print 'ERROR: you must either specify a script name (using -s) or a command to run\n\n'
        sys.exit()
    
    if qsubfile is None:
        qsubfile, qsubfilepath = mkstemp(prefix=jobname + "_",
                                         dir='.', suffix='.slurm', text=True)
        os.close(qsubfile)

    print 'Outputting SLURM commands to %s' % qsubfilepath
    qsubfile = open(qsubfilepath, 'w')
    qsubfile.write('#!/bin/bash\n#\n')
    qsubfile.write('# SLURM control file automatically created by launch\n#\n')
    if parametric:
        # fill in the blanks
        if tpn is not None:
            # user specified the number of tasks per node; get the
            # number of nodes given that, evenly splitting tasks by
            # node
            nnodes = int(math.ceil(float(ncmds)/float(tpn)))
            ntasks = nnodes * int(tpn)
        elif nnodes is None and ntasks is None:
            # nothing is explicitly specified; use one task per core
            # based on the queue, with the minimum number of nodes
            # given that
            nnodes = int(math.ceil(float(ncmds)/float(CORES[queue])))
            ntasks = nnodes * float(CORES[queue])
            print "Estimated %d nodes and %d tasks" % (nnodes, ntasks)
        elif nnodes is None and ntasks is not None:
            # number of total tasks is specified, but not nodes or
            # tpn; cannot calculate tpn, so just minimize the number
            # of nodes
            ntasks = int(ntasks)
            nnodes = int(math.ceil(float(ntasks)/float(CORES[queue])))
            print "Number of nodes not specified; estimated as %d" % nnodes
        elif ntasks is None and nnodes is not None:
            # tasks and tpn not specified; set tasks to the number of
            # commands
            nnodes = int(nnodes)
            ntasks = nnodes * float(CORES[queue])
            print "Number of tasks not specified; estimated as %d" % ntasks
        else:
            nnodes = int(nnodes)
            ntasks = int(ntasks)

        if nnodes > MAXNODES[queue]:
            nnodes = MAXNODES[queue]
        if ntasks > MAXCORES[queue]:
            ntasks = MAXCORES[queue]

        qsubfile.write('# Using parametric launcher with control file: %s\n#\n' % script_name)
        qsubfile.write('#SBATCH -N %d\n' % nnodes)
        qsubfile.write('#SBATCH -n %d\n' % ntasks)
    else:
        qsubfile.write('# Launching single command: %s\n#\n' % cmd)
        qsubfile.write('#SBATCH -N 1\n')
        qsubfile.write('#SBATCH -n %d\n' % CORES[queue])

    if cwd is not None:
        qsubfile.write('#SBATCH -D %s\n' % cwd)
    qsubfile.write('#SBATCH -J %s\n' % jobname)
    if outfile is not None:
        qsubfile.write('#SBATCH -o {0}\n'.format(outfile))
    else:
        qsubfile.write('#SBATCH -o {0}.o%j\n'.format(jobname))
    qsubfile.write('#SBATCH -p %s\n' % queue)
    qsubfile.write('#SBATCH -t %s\n' % runtime)

    if type(hold) is str: 
        qsubfile.write("#SBATCH -d afterok")
        qsubfile.write(":{0}".format(int(hold)))
        qsubfile.write('\n')

    if projname is not None:
        qsubfile.write("#SBATCH -A {0}\n".format(projname))

    if email is not None:
        qsubfile.write('#SBATCH --mail-type=ALL\n')
        qsubfile.write('#SBATCH --mail-user=%s\n' % email)
                       
    qsubfile.write('\numask 2\n\n')
    
    if compiler == "gcc":
        qsubfile.write('module swap intel gcc\n')

    if not parametric:
        qsubfile.write('set -x\n')
        qsubfile.write(cmd + '\n')
    else:
        qsubfile.write('export LAUNCHER_JOB_FILE=%s\n' % script_name)
        if cwd is not None:
            qsubfile.write('export LAUNCHER_WORKDIR=%s\n' % cwd)
        else:
            qsubfile.write('export LAUNCHER_WORKDIR=$(pwd)\n')
        qsubfile.write('echo "WORKING DIR: $LAUNCHER_WORKDIR/"\n')
        qsubfile.write('$LAUNCHER_DIR/paramrun\n')
        qsubfile.write('echo " "\necho " Parameteric Job Complete"\necho " "\n')
        
    qsubfile.close()
    
    jobid = None
    if not test:
        process = subprocess.Popen('sbatch %s' % qsubfilepath,
                                   shell=True, stdout=subprocess.PIPE)
        for line in process.stdout:
            print line.strip()
            
            if line.find('Submitted batch job') == 0:
                jobid = int(line.strip().split(' ')[3])
        process.wait()
    
    if not keepqsubfile:
        print 'Deleting qsubfile: %s' % qsubfilepath
        os.remove(qsubfilepath)
    return jobid
    
