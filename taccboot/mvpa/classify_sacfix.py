#!/opt/apps/python/epd/7.2.2/bin/python

## Usage: python classify_sacfix.py 103
##    This script classifies saccade and fixation using
##    the whole brain and the two functional runs.
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
# subject's directory
sbjdir = bdir+sbjcode+'/'

print 'MVPA classification for '+sbjcode

## Read in volume information
# runs: what run the volume is from 1 = 6, 2 = 13
# label: 1 = saccade, 2 = fixation
runs,label = loadtxt(sbjdir+'behav/sacfix_vol.txt',unpack=1)

## Read in imaging data to a dataset structure
# list of functional files for the runs
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

## Remove null events (volumes labeled with 0)
ds = ds[ds.targets>0]

## Z-score data within runs
zscore(ds,chunks_attr='chunks')

print '-- starting classification ('+time.strftime('%H:%M:%S',time.localtime())+')'

## Set up classification scheme
# linear SVM classifier
clf = LinearCSVMC()
# partition the data by runs
ptf = NFoldPartitioner(attr='chunks')
# cross validate the classifier using the partitioner
# note: test performance stats are enabled (enable_ca=['stats'])
cv = CrossValidation(clf,ptf,enable_ca=['stats'])

## Run the cross validation of the classifier
results = cv(ds)

print '-- classification finished print ('+time.strftime('%H:%M:%S',time.localtime())+')'

## Classifier accuracy
acc1 = 1-mean(results) # cross validation output error term
acc2 = cv.ca.stats.stats['ACC'] # accuracy also in stats structure
print 'ACC fold 1 = %.5f'%(1-results.samples[0])
print 'ACC fold 2 = %.5f'%(1-results.samples[1])
print 'Mean ACC = %.5f'%(acc1)

# print out all stats
print cv.ca.stats.as_string()
# use below to get a description for all the stats
# print cv.ca.stats.as_string(description=True)

# save accuracy to text file
savetxt('classify_results_'+sbj+'.txt',[acc1],fmt='%.6f')

## MVPA sensitivity (or importance) maps
sa = clf.get_sensitivity_analyzer(auto_train=False,force_train=False,postproc=maxofabs_sample())
rm = RepeatedMeasure(sa,ptf)
sens_results = rm(ds)
map2nifti(ds,sens_results).to_filename(sbjdir+'/mvpa/sensitivity_sacfix.nii.gz')
