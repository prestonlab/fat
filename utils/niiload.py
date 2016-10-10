
import nibabel as nib
from mvpa2.base.dataset import vstack
from mvpa2.datasets.mri import fmri_dataset

def loadmask(srcfile, maskfile):

    maskimg = nib.load(maskfile)
    mask = img.get_data()
    mask_ind = np.where(mask > 0)

    dmin = [np.min(m) for m in mask_ind]
    dmax = [np.max(m) for m in mask_ind]

def loadcat(srcfiles, maskfile):

    ds = fmri_dataset(srcfiles[0], mask=maskfile)
    for file in srcfiles[1:]:
        newds = fmri_dataset(file, mask=maskfile)
        ds = vstack((ds, newds))

    return ds
    
