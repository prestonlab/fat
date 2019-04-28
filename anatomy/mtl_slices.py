#!/usr/bin/env python

# PrC: 3, 4
# PHC: 7, 8

import sys
import os

import numpy as np
import nibabel as nib

def get_slices(data, labels):
    slices = []
    for label in labels:
        ind = np.nonzero(data == label)
        slices.extend(ind[1])
    return np.unique(slices)

def main():
    seg_image = sys.argv[1]
    outdir = sys.argv[2]
    roi_spec = sys.argv[3:]
    n_input = len(roi_spec)

    img = nib.load(seg_image)
    data = img.get_data()
    
    for i in range(0,n_input,2):
        roi_name = roi_spec[i]
        roi_dir = roi_spec[i+1]
        roi_val = int(roi_spec[i+1][1:])
        roi_slices = np.unique(np.nonzero(data == roi_val)[1])
        for i, s in enumerate(roi_slices):
            slice_mask = np.zeros(data.shape)
            slice_mask[:,s,:] = 1
            mask = np.array(np.logical_and(slice_mask, data == roi_val),
                            dtype=int)
            mask_img = nib.Nifti1Image(mask, img.affine)
            filename = os.path.join(outdir,
                '%s%02d.nii.gz' % (roi_name, i+1))
            print(filename)
            #mask_img.to_filename(filename)

if __name__ == "__main__":
    main()
    
