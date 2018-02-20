#!/usr/bin/env python

import os, sys
from string import Template
from glob import glob
import warnings

from subjutil import *

parser = SubjParser()
parser.add_argument('featdir', help="path to feat directory")
parser.add_argument('template', help="path to template image")
parser.add_argument('-a', '--anat', default='',
                    help="anatomical image number used to register reference functional volume (default: none)")
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = SubjLog(args.subject, 'translev1', 'model',
              args.clean_logs, args.dry_run)

bbreg = sp.path('anatomy', 'bbreg', 'transforms')
antsreg = sp.path('anatomy', 'antsreg', 'transforms')

t1_brain = sp.image_path('anatomy', 'orig_brain' + args.anat)
t1_warped = sp.image_path('anatomy', 'antsreg', 'data', 'orig_brain')
refvol = sp.image_path('bold', 'antsreg', 'data', 'refvol')

log.start()

# invert refvol2orig transformation
refvol2orig = os.path.join(bbreg, 'refvol-highres.mat')
if not os.path.exists(refvol2orig):
    orig2refvol = os.path.join(bbreg, 'highres-refvol.mat')
    if os.path.exists(orig2refvol):
        log.run('convert_xfm -omat %s -inverse %s' %
                (refvol2orig, orig2refvol))
    else:
        raise IOError('Functional to structural registration not found.')

# convert functional to anatomy transformation to ITK format
func2anat_affine = os.path.join(bbreg, 'refvol-orig_Affine.txt')
if not os.path.exists(func2anat_affine):
    cmd = 'c3d_affine_tool -ref %s -src %s %s -fsl2ras -oitk %s' % (
        t1_brain, refvol, refvol2orig, func2anat_affine)
    log.run(cmd)

# orig to MNI affine and warp
anat2mni_warp = os.path.join(antsreg, 'orig-template_Warp.nii.gz')
anat2mni_affine = os.path.join(antsreg, 'orig-template_Affine.txt')

transform = Template('antsApplyTransforms -d 3 -i $native -o $mni -n BSpline -r %s -t %s -t %s -t %s' % (
    args.template, anat2mni_warp, anat2mni_affine, func2anat_affine))
transform_label = Template('antsApplyTransforms -d 3 -i $native -o $mni -n NearestNeighbor -r %s -t %s -t %s -t %s' % (
    args.template, anat2mni_warp, anat2mni_affine, func2anat_affine))

identity_affine = sp.proj_path('resources', 'identity.mat')
images = ['example_func','mean_func','mask']
islabel = [False,False,True]

# prep directories for native-space images
native_dir = os.path.join(args.featdir, 'native')
native_stats_dir = os.path.join(args.featdir, 'native', 'stats')
if os.path.exists(native_dir):
    raise IOError('Backup directory already exists.')

if not os.path.exists(native_dir):
    log.run('mkdir -p %s' % native_dir)

# set up the reg directory for an identity transform (so that
# higher-level Feat doesn't change anything)
reg_dir = os.path.join(args.featdir, 'reg')
affine_file = os.path.join(reg_dir, 'example_func2standard.mat')
standard_file = impath(reg_dir, 'standard')
highres_file = impath(reg_dir, 'highres')
log.run('mkdir -p %s' % reg_dir)
log.run('cp %s %s' % (identity_affine, affine_file))
log.run('cp %s %s' % (args.template, standard_file))
log.run('cp %s %s' % (t1_warped, highres_file))

# transform functional images
for i in range(len(images)):
    native = impath(args.featdir, native_dir, images[i])
    mni = impath(args.featdir, images[i])
    if not os.path.exists(native):
        log.run('mv %s %s' % (mni, native_dir))

    if islabel[i]:
        log.run(transform_label.substitute(native=native, mni=mni))
    else:
        log.run(transform.substitute(native=native, mni=mni))

# move existing stats
stats_dir = os.path.join(args.featdir, 'stats')
if not os.path.exists(native_stats_dir):
    log.run('mv %s %s' % (stats_dir, native_dir))
if not os.path.exists(stats_dir):
    log.run('mkdir -p %s' % stats_dir)
    log.run('cp %s %s' % (os.path.join(native_stats_dir, 'dof'), stats_dir))

# transform cope and varcope images
all_copes = glob(impath(native_stats_dir, '*cope*'))
for copefile in all_copes:
    filename = os.path.basename(copefile)
    native = impath(native_stats_dir, filename)
    mni = impath(stats_dir, filename)
    log.run(transform.substitute(native=native, mni=mni))

# prepare the new files for Feat
log.run('updatefeatreg %s -pngs' % args.featdir)

log.finish()
