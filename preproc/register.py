#!/usr/bin/env python

import os

def merge(img_dir, xfm_dir, name1, name2, outname, log, bet=False):

    img1 = os.path.join(img_dir, name1 + '.nii.gz')
    img2 = os.path.join(img_dir, name2 + '.nii.gz')

    if not (os.path.exists(img1) and os.path.exists(img2)):
        log.write('Register: one or more images does not exist.')
        return
    
    # extract the brain
    if bet:
        brain1 = os.path.join(img_dir, name1 + '_brain.nii.gz')
        brain2 = os.path.join(img_dir, name2 + '_brain.nii.gz')
        log.run('bet %s %s -R' % (img1, brain1))
        log.run('bet %s %s -R' % (img2, brain2))

        # calculate transform
        transform_base = os.path.join(xfm_dir,
                                      '%s_brain-%s_brain_' % (name2, name1))
        cmd = 'ANTS 3 -m MI[%s,%s,1,32] -o %s --rigid-affine true -i 0' % (
            brain1, brain2, transform_base)
        log.run(cmd)
    else:
        # calculate transform
        transform_base = os.path.join(xfm_dir, '%s-%s_' % (name2, name1))
        cmd = 'ANTS 3 -m MI[%s,%s,1,32] -o %s --rigid-affine true -i 0' % (
            img1, img2, transform_base)
        log.run(cmd)

    # apply transformation
    reg_file = os.path.join(img_dir, name2 + '_reg.nii.gz')
    transform_file = transform_base + 'Affine.txt'
    cmd = 'WarpImageMultiTransform 3 %s %s -R %s %s' % (
        img2, reg_file, img1, transform_file)
    log.run(cmd)
    
    # create mean image
    mean_file = os.path.join(img_dir, outname + '.nii.gz')
    log.run('fslmaths %s -add %s -div 2 %s' % (
        reg_file, img1, mean_file))
    
