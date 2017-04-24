#!/usr/bin/env python

import sys
from mvpa2.base import hdf5
from mvpa2.base.dataset import vstack

outfile = sys.argv[1]

# load and concatenate all input files
for i, file in enumerate(sys.argv[2:]):
    print file
    if i == 0:
        ds = hdf5.h5load(file)
        ds.sa['chunks'] = [i]
        a = ds.a
    else:
        newds = hdf5.h5load(file)
        newds.sa['chunks'] = [i]
        ds = vstack((ds, newds))

# save the full dataset
ds.a = a
ds.save(outfile)
