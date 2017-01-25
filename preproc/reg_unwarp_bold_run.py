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
log = sp.init_log('epireg_%s' % args.runid, 'preproc', args)
log.start()

reg_data = sp.path('bold', 'antsreg', 'data')
reg_xfm = sp.path('bold', 'antsreg', 'transforms')
log.run('mkdir -p %s' % reg_data)
log.run('mkdir -p %s' % reg_xfm)

srcvol = sp.image_path('bold', args.runid, 'bold_cor_mcf_brain_avg_unwarp')
refvol = sp.image_path('bold', args.refrun, 'bold_cor_mcf_brain_avg_unwarp')

srcdir = sp.path('bold', args.runid)
fmdir = os.path.join(srcdir, 'fm')

# motion correction and distortion correction files
mcf_file = os.path.join(srcdir, 'bold_cor_mcf.cat')
warp_file = impath(fmdir, 'epireg_epi_warp')

bold = sp.image_path('bold', args.runid, 'bold')
bold_reg = sp.image_path('bold', args.runid, 'bold_reg')

output = impath(reg_data, args.runid)

mask = sp.image_path('bold', args.refrun, 'fm', 'brainmask')

if args.refrun == args.runid:
    # just motion correct and unwarp
    log.run('applywarp -i %s -r %s -o %s --premat=%s -w %s --interp=spline --rel --paddingsize=1' % (
        bold, refvol, bold_reg, mcf_file, warp_file))
    log.run('cp %s %s' % (refvol, impath(reg_data, 'refvol')))
    log.run('cp %s %s' % (mask, impath(reg_data, 'mask')))
else:
    # register to the reference run
    xfm_base = os.path.join(reg_xfm, '%s-refvol_' % args.runid)
    log.run('antsRegistration -d 3 -r [%s,%s,1] -t Rigid[0.1] -m MI[%s,%s,1,32,Regular,0.25] -c [1000x500x250x100,1e-6,10] -f 8x4x2x1 -s 3x2x1x0vox -n BSpline -w [0.005,0.995] -o %s' % (
        refvol, srcvol, refvol, srcvol, xfm_base))

    # convert to FSL format
    itk_file = xfm_base + '0GenericAffine.mat'
    txt_file = xfm_base + '0GenericAffine.txt'
    reg_file = os.path.join(reg_xfm, '%s-refvol.mat' % args.runid)
    log.run('ConvertTransformFile 3 %s %s' % (itk_file, txt_file))
    log.run('c3d_affine_tool -itk %s -ref %s -src %s -ras2fsl -o %s' % (
        txt_file, refvol, srcvol, reg_file))

    # apply motion correction, unwarping, and co-registration to bold
    log.run('applywarp -i %s -r %s -o %s --premat=%s -w %s --postmat=%s --interp=spline --rel --paddingsize=1' %
        (bold, refvol, bold_reg, mcf_file, warp_file, reg_file))

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
