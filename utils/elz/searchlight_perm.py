#!/usr/bin/env python

from subjutil import SubjParser

parser = SubjParser(include_log=False)
parser.add_argument('mask', help="name of mask file")
parser.add_argument('model', help="name of model")
parser.add_argument('items', help='faces or places?')
parser.add_argument('radius', type=int, help='searchlight radius') 
args = parser.parse_args()

import os
import numpy as np
import scipy as sp
import scipy.io as sio
from scipy.spatial.distance import squareform
from scipy.stats import spearmanr
from scipy.spatial.distance import pdist
from mvpa2.mappers.zscore import zscore
from mvpa2.mappers.fx import mean_group_sample
from mvpa2.measures import rsa
from mvpa2.measures.searchlight import sphere_searchlight
from mvpa2.base.learner import ChainLearner
from mvpa2.mappers.shape import TransposeMapper
from mvpa2.datasets.mri import map2nifti

from os.path import join as pjoin
from mvpa2 import cfg
from time import gmtime, strftime

import bender

bp = bender.BenderPath(args.subject, args.study_dir)
mask_file = bp.image_path('anatomy', 'bbreg', 'data', args.mask)

print "Loading pre-exposure beta series with %s mask..." % args.mask
ds = bp.beta_dataset('a_prex', mask_file)

# z-score
print "Normalizing within run..."
zscore(ds, chunks_attr='chunks')

# calculate average for each stimulus
print "Calculating average for each stimulus..."
mtgs = mean_group_sample(['group'])
mtds = mtgs(ds)

mtds_face = mtds[mtds.sa['condition'][:]=='face']
mtds_place = mtds[mtds.sa['condition'][:]=='scene']
mtds2use = mtds_face[:] if args.items=='faces' else mtds_place[:]
print "Reading in model..." 
model_path = os.path.join('/home1/02837/elz226/analysis/searchlight/models/', args.model+ '.mat')
model_contents = sio.loadmat(model_path)
model_rdm = model_contents[args.model]

model_face = model_rdm[0:60, 0:60]
model_place = model_rdm[60:120, 60:120]
model2use_pre = model_face[:] if args.items=='faces' else model_place[:]

rand_ind_path = ('/home1/02837/elz226/analysis/searchlight/models/rand_ind.mat')
rand_ind_contents = sio.loadmat(rand_ind_path)
rand_ind_all = rand_ind_contents['rand_ind']

items2remove = np.isnan(model2use_pre)

## permuted_model = [];
for ind in range(0,100):
    temp_ind = rand_ind_all[ind]
    temp_model = model2use_pre[:, temp_ind][temp_ind]
    
    isbad = np.isnan(temp_model)
    vecisbad = squareform(isbad)

    model_rdm_nonans = temp_model
    model_rdm_nonans[np.isnan(model_rdm_nonans)] = 0
    model_rdm_nonans_vec = squareform(model_rdm_nonans)
    short_model_vec = model_rdm_nonans_vec[vecisbad == 0]
    model2use = squareform(short_model_vec)

    # searchlight
    print "Performing searchlight number %03d for %s..." % (ind, bp.subject)    
    tdsm = rsa.PDistTargetSimilarity(squareform(model2use))
    sl_tdsm = sphere_searchlight(ChainLearner([tdsm, TransposeMapper()]), args.radius)
    slres_tdsm = sl_tdsm(mtds2use[items2remove[1]==False])
    fischerz_slres = np.arctanh(slres_tdsm[0]) 

    # save file
    print "Saving maps %03d for %s..." % (ind, bp.subject) 
    res_dir =  os.path.join('/work/02837/elz226/lonestar/searchlight/perm_res',args.mask, 'r%d' % (args.radius), args.items, args.model) 
    if not os.path.exists(res_dir):
        os.makedirs(res_dir)
    labels = np.unique(ds.sa.group)
    nifti = map2nifti(ds, fischerz_slres)
    filepath = os.path.join(res_dir, '%s_%s_%s_%03d.nii.gz' % (bp.subject, args.model, args.items, ind))
    nifti.to_filename(filepath)
