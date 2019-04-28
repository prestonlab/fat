
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

    for i, file in enumerate(srcfiles):
        print("Loading %s" % file)
        if i == 0:
            ds = fmri_dataset(file, mask=maskfile)
            ds.sa['chunks'] = [i]
            a = ds.a
        else:
            newds = fmri_dataset(file, mask=maskfile)
            newds.sa['chunks'] = [i]
            ds = vstack((ds, newds))

    ds.a = a
    return ds
    
