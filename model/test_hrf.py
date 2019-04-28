#!/usr/bin/env python

import numpy as np
from scipy.signal import savgol_filter
from mvpa2.misc.fsl.base import FslGLMDesign, read_fsl_design
from mvpa2.datasets.mri import fmri_dataset, map2nifti
import hrf_estimation as he

# TODO: interface like betaseries_hrf.py
# filtering like in FEAT
# run smoothing of voxelwise HRF, read in smoothed HRF at each voxel
# loop over voxels, creating convolved and filtered design matrix for each
# estimate betaseries like in betaseries.py

model_file = '/corral-repl/utexas/prestonlab/mistr/batch/glm/disp_stim_hrf_sm5/fsf/disp_stim_hrf_sm5_mistr_02_disp_1'

design = read_fsl_design(model_file + '.fsf')
desmat = FslGLMDesign(model_file + '.mat')

n_tp, n_evs = desmat.mat.shape

# trial regressors are just the first N regressors
n_trial_evs = n_trial
trial_evs = list(range(0, n_trial))

# number of original regressors and all regressors including
# derivatives
n_orig = design['fmri(evs_orig)']

# check which trial regressors have temporal derivatives
isderiv = np.zeros(n_orig, dtype=bool)
for i in range(n_orig):
    f = 'fmri(deriv_yn{:d})'.format(i+1)
    isderiv[i] = design[f]

if np.any(isderiv):
    raise IOError('Must not include derivatives in design matrix.')

# read in voxelwise hrf estimates from lateral occipital ROI
#bold = design['feat_files']
data = fmri_dataset('/corral-repl/utexas/prestonlab/mistr/batch/glm/disp_stim_hrf_sm5/r1glm_fir/mistr_02/disp_stim_hrf_sm5_mistr_02_disp_1_hrfs.nii.gz',
                    mask='/corral-repl/utexas/prestonlab/mistr/mistr_02/anatomy/bbreg/data/b_lo.nii.gz')

# average HRF
mean_hrf = np.mean(data.samples,1)

# get onsets and conditions in the correct format
onset_list = []
cond_list = []
for i in range(n_orig):
    onset_file = design['fmri(custom{:d})'.format(i+1)]
    mat = np.loadtxt(onset_file)
    for onset in mat[:,0]:
        onset_list.append(onset)
        cond_list.append(i+1)
onsets = np.array(onset_list)
conds = np.array(cond_list)

tr = design['fmri(tr)']

# create a design matrix with the average estimated hrf
n_tp = design['fmri(npts)']
mat, Q = he.utils.create_design_matrix(conds, onsets, tr, n_tp, basis='hrf')

# TODO: filtering
#mat_filt = savgol_filter(mat, 64, 1, axis=0)

n_vox = data.shape[1]
for i in range(n_vox):
    beta_maker = N.zeros((n_trial, n_tp))
    for i, ev in enumerate(trial_evs):
        # this trial
        if deriv and args.sep_derivs:
            # if using separate derivatives, include a dedicated regressor
            # for this trial
            dm_trial = N.hstack((desmat.mat[:,ev,N.newaxis],
                                 desmat.mat[:,deriv_evs[i],N.newaxis]))
        else:
            # just the one regressor for this trial
            dm_trial = desmat.mat[:,ev,N.newaxis]

        # other trials, summed together
        other_trial_evs = [x for x in trial_evs if x != ev]
        if deriv:
            if args.sep_derivs:
                # only include derivatives except for this trial
                other_deriv_evs = [x for x in deriv_evs if x != deriv_evs[i]]
                dm_otherevs = N.hstack((
                    N.sum(desmat.mat[:,other_trial_evs,N.newaxis],1),
                    N.sum(desmat.mat[:,other_deriv_evs,N.newaxis],1)))
            else:
                # put all derivatives in one regressor
                dm_otherevs = N.hstack((
                    N.sum(desmat.mat[:,other_trial_evs,N.newaxis],1),
                    N.sum(desmat.mat[:,deriv_evs,N.newaxis],1)))
        else:
            # just one regressor for all other trials
            dm_otherevs = N.sum(desmat.mat[:,other_trial_evs,N.newaxis],1)

        # put together the design matrix
        if dm_nuisance is not None:
            dm_full = N.hstack((dm_trial, dm_otherevs, dm_nuisance, dm_extra))
        else:
            dm_full = N.hstack((dm_trial, dm_otherevs, dm_extra))
        s = dm_full.shape
        dm_full = dm_full - N.kron(N.ones(s), N.mean(dm_full,0))[:s[0],:s[1]]
        dm_full = N.hstack((dm_full, N.ones((n_tp,1))))

        # calculate beta-forming vector
        beta_maker_loop = N.linalg.pinv(dm_full)
        beta_maker[i,:] = beta_maker_loop[0,:]

    print("Estimating model...")
    # this uses Jeanette's trick of extracting the beta-forming vector for each
    # trial and putting them together, which allows estimation for all trials
    # at once
    glm_res_full = N.dot(beta_maker, data.samples)
