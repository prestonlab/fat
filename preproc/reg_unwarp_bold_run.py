#!/usr/bin/env python

from subjutil import *
import os

parser = SubjParser()
parser.add_argument('runid', help="run identifier")
parser.add_argument('refrun', help="reference run")
parser.add_argument('-k', '--keep', help="keep intermediate files",
                    action='store_true')
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('regunwarp_%s' % args.runid, 'preproc', args)
log.start()

reg_data = sp.path('bold', 'antsreg', 'data')
reg_xfm = sp.path('bold', 'antsreg', 'transforms')
log.run('mkdir -p %s' % reg_data)
log.run('mkdir -p %s' % reg_xfm)

srcvol = sp.image_path('bold', args.runid, 'bold_cor_mcf_avg_unwarp_brain')
refvol = sp.image_path('bold', args.refrun, 'bold_cor_mcf_avg_unwarp_brain')

srcdir = sp.path('bold', args.runid)
fmdir = os.path.join(srcdir, 'fm')

# motion correction and distortion correction files
mcf_file = os.path.join(srcdir, 'bold_cor_mcf.cat')
warp_file = impath(fmdir, 'epireg_epi_warp')

bold = sp.image_path('bold', args.runid, 'bold')
bold_init = sp.image_path('bold', args.runid, 'bold_reg_init')
bold_reg = sp.image_path('bold', args.runid, 'bold_reg')

output = impath(reg_data, args.runid)

mask = sp.image_path('bold', args.refrun, 'fm', 'brainmask')

nitk_var = 'ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS'
if nitk_var in os.environ:
    nitk = int(os.environ[nitk_var])
else:
    nitk = 1

if args.refrun == args.runid:
    # just motion correct and unwarp
    log.run('applywarp -i %s -r %s -o %s --premat=%s -w %s --interp=spline --rel --paddingsize=1' % (
        bold, refvol, bold_reg, mcf_file, warp_file))
    log.run('cp %s %s' % (refvol, impath(reg_data, 'refvol')))
    log.run('cp %s %s' % (mask, impath(reg_data, 'mask')))
else:
    # nonlinear registration to the reference run
    xfm_base = os.path.join(reg_xfm, '%s-refvol_' % args.runid)
    log.run('antsRegistrationSyN.sh -d 3 -m {mov} -f {fix} -o {out} -n {nitk} -t s'.format(
        mov=srcvol, fix=refvol, out=xfm_base, nitk=nitk))
    
    # convert the affine part to FSL format
    itk_file = xfm_base + '0GenericAffine.mat'
    txt_file = xfm_base + '0GenericAffine.txt'
    reg_file = os.path.join(reg_xfm, '%s-refvol.mat' % args.runid)
    log.run('ConvertTransformFile 3 %s %s' % (itk_file, txt_file))
    log.run('c3d_affine_tool -itk %s -ref %s -src %s -ras2fsl -o %s' % (
        txt_file, refvol, srcvol, reg_file))

    # apply motion correction, unwarping, and affine co-registration
    log.run('applywarp -i %s -r %s -o %s --premat=%s -w %s --postmat=%s --interp=spline --rel --paddingsize=1' %
        (bold, refvol, bold_init, mcf_file, warp_file, reg_file))

    # apply co-registration warp. Tried to figure out how to do this
    # with FSL so that all transformations would be in one step, but
    # as of 2017-02-06 there doesn't seem to be a tool for converting
    # ITK/ANTS warps to FSL format. So will settle for two
    # interpolations to take the raw bold to motion-corrected,
    # unwarped common functional space
    warp = xfm_base + '1Warp.nii.gz'
    log.run('antsApplyTransforms -d 4 -i {} -o {} -r {} -t {} -n BSpline'.format(
        bold_init, bold_reg, bold_init, warp))

# estimate bias field based on the average over time (so the shape of
# each voxel timeseries does not change)
bold_reg_avg = sp.image_path('bold', args.runid, 'bold_reg_avg')
log.run('fslmaths %s -Tmean %s' % (bold_reg, bold_reg_avg))

bold_reg_avg_cor = sp.image_path('bold', args.runid, 'bold_reg_avg_cor')
bias = sp.image_path('bold', args.runid, 'bold_reg_avg_bias')
log.run('N4BiasFieldCorrection -d 3 -i %s -o [%s,%s]' % (
    bold_reg_avg, bold_reg_avg_cor, bias))

# correct for the bias field and mask with anatomical mask
log.run('fslmaths %s -div %s -mas %s %s' % (
    bold_reg, bias, mask, output))

# remove intermediate files
if not args.keep:
    log.run('rm -f %s/bold_reg*' % srcdir)

log.finish()
