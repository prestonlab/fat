#!/opt/apps/python/epd/7.2.2/bin/python

## Usage: python searchlight_sacfix.py 103
##    This script performs searchlight classification
##

## Import all python libraries we need
from numpy import *
from pylab import *
from scipy.io import *
from mvpa2.datasets.mri import *
from mvpa2.mappers.detrend import *
from mvpa2.mappers.zscore import *
from mvpa2.clfs.svm import *
from mvpa2.generators.partition import *
from mvpa2.measures.base import *
from mvpa2.measures import *
from mvpa2.measures.searchlight import *
from mvpa2.misc.stats import *
from mvpa2.mappers.fx import *
from mvpa2.generators.permutation import *
from mvpa2.clfs.stats import *
from mvpa2.generators.base import *
from mvpa2.base.node import *
from random import sample
import os
import sys

## Setup up subject and directory variables
# subject number from input
sbj = sys.argv[1]
# subject code
sbjcode = 'iceman_'+sbj
# base directory of experiment
bdir = '/corral-repl/utexas/prestonlab/taccboot/'
# subject's director
sbjdir = bdir+sbjcode+'/'
    
print 'MVPA searchlight classification for '+sbjcode

## Read in volume information
# runs: what run the volume is from 1 = 6, 2 = 13
# label: 1 = saccade, 2 = fixation
runs,label = loadtxt(sbjdir+'behav/sacfix_vol.txt',unpack=1)

## Read in imaging data to a dataset structure 
# list of 4d functional files for the runs
funcs = [sbjdir+'BOLD/antsreg/data/functional_6_bold_mcf_brain.nii.gz',
         sbjdir+'BOLD/antsreg/data/functional_13_bold_mcf_brain.nii.gz']
# location of the whole brain mask (from the reference run)
mask = sbjdir+'BOLD/functional_saccade_6/bold_mcf_brain_mask.nii.gz'
# read in dataset and assign volume run number to the 
# chunks attribute and label to the target attribute
ds = fmri_dataset(funcs,mask=mask,chunks=runs,targets=label)

print '-- dataset read in ('+time.strftime('%H:%M:%S',time.localtime())+')'

## Remove linear trends (note: setting chunks_attr to runs means
## detrending will occur within runs)
poly_detrend(ds,polyord=1,chunks_attr='chunks')

## Remove bookend volumes (volumes labeled with 0)
ds = ds[ds.targets>0]

## Z-score data within runs
zscore(ds,chunks_attr='chunks')

print '-- starting searchlight ('+time.strftime('%H:%M:%S',time.localtime())+')'

## Set up classification scheme
# linear SVM classifier
clf = LinearCSVMC()
# partition the data by runs
ptf = NFoldPartitioner(attr='chunks')
# cross validate the classifier using the partitioner
# note: postproc defines a function to call after cross validation, in this
# case, we are averaging over the cv folds to get a single searchlight image
cv = CrossValidation(clf,ptf,postproc=mean_sample(),enable_ca=['stats'])

## Define searchlight (radius is in voxels)
sl = sphere_searchlight(cv,radius=2)
# note: by default searchlight uses all available cpu cores,
# to change this add nproc=#cores to searchlight definition
# e.g., sl = sphere_searchlight(cv,radius=2,nproc=4)

## change debug status to display searchlight progress
if __debug__:
    debug.active+=["SLC"]

## Run the searchlight
sl_results = sl(ds)

## Save out accuracy map
map2nifti(ds,1-sl_results.samples).to_filename(sbjdir+'mvpa/searchlight_sacfix.nii.gz')
