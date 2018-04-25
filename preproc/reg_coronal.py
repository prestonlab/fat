#!/usr/bin/env python

from subjutil import *

s = """Run basic preprocessing of coronal scans.

If multiple coronal scans, will co-register and average them.
Registers the (only or average) coronal scan with the highres scan,
and transforms the coronal to highres space for quality checks.
"""

parser = SubjParser(description=s, raw=True)
args = parser.parse_args()

sp = SubjPath(args.subject, args.study_dir)
log = sp.init_log('regcoronal', 'preproc', args)
log.start()

img_dir = sp.path('anatomy')
xfm_dir = sp.path('anatomy', 'antsreg', 'transforms')

log.run('mkdir -p %s' % xfm_dir)

image1 = sp.image_path('anatomy', 'coronal1')
image2 = sp.image_path('anatomy', 'coronal2')
merged = sp.image_path('anatomy', 'coronal')
coronal_merge = sp.image_path('anatomy', 'coronal_brain')

if not os.path.exists(image2) and os.path.exists(image1):
    merge = False
else:
    merge = True

if merge:
    # correct for bias field, register using linear registration,
    # scale, and average
    log.run('merge_anat.sh -c {} {} {}'.format(image1, image2, merged))
else:
    # just correct for bias field
    log.run('N4BiasFieldCorrection -i {} -o {}'.format(image1, merged))
log.run('bet {} {} -f 0.01'.format(merged, coronal_merge))

# create bias-corrected and brain-extracted highres
highres = sp.image_path('anatomy', 'highres')
highres_cor = sp.image_path('anatomy', 'highres_cor')
highres_brain = sp.image_path('anatomy', 'highres_cor_brain')
log.run('N4BiasFieldCorrection -i {} -o {}'.format(highres, highres_cor))
log.run('bet {} {}'.format(highres_cor, highres_brain))

# register coronal to highres
coronal_merge = sp.image_path('anatomy', 'coronal_brain')
xfm_base = os.path.join(xfm_dir, 'coronal-highres_')
log.run('antsRegistration -d 3 -r [{highres},{coronal},1] -t Rigid[0.1] -m MI[{highres},{coronal},1,32,Regular,0.25] -c [1000x500x250x100,1e-6,10] -f 8x4x2x1 -s 3x2x1x0vox -n BSpline -w [0.005,0.995] -o {xfm}'.format(
    highres=highres_brain, coronal=coronal_merge, xfm=xfm_base))
c2h = os.path.join(xfm_dir, xfm_base + '0GenericAffine.mat')

# create registered coronal image
coronal_reg = sp.image_path('anatomy', 'coronal-highres')
if not merge:
    # only one coronal; just carry out the transformation
    log.run('antsApplyTransforms -i {input} -o {output} -r {ref} -t {c2h} -n BSpline'.format(
        input=coronal_merge, output=coronal_reg, ref=highres_brain, c2h=c2h))
else:
    # transform coronal 2 (coronal 2 to highres)
    cmerge_dir = sp.path('anatomy', 'coronal1_coronal2')
    coronal2 = impath(cmerge_dir, 'fix_cor')
    coronal2_reg = sp.image_path('anatomy', 'coronal2-highres')
    log.run('antsApplyTransforms -i {input} -o {output} -r {ref} -t {c2h} -n BSpline'.format(
        input=coronal2, output=coronal2_reg, ref=highres_brain, c2h=c2h))

    # transform coronal 1 (coronal 1 to coronal 2, coronal 2 to highres)
    coronal1 = impath(cmerge_dir, 'mov_cor')
    coronal1_reg = sp.image_path('anatomy', 'coronal1-highres')
    c2c = os.path.join(cmerge_dir, 'mov-fix_0GenericAffine.mat')
    log.run('antsApplyTransforms -i {input} -o {output} -r {ref} -t {c2h} -t {c2c} -n BSpline'.format(
        input=coronal1, output=coronal1_reg, ref=highres_brain,
        c2h=c2h, c2c=c2c))

    # merge registered coronals
    log.run('merge_anat.sh -m {} {} {}'.format(
        coronal1_reg, coronal2_reg, coronal_reg))

log.finish()
