#!/usr/bin/env python

import sys
import niiload

maskfile = sys.argv[1]
outfile = sys.argv[2]

# load and concatenate all input files
ds = niiload.loadcat(sys.argv[3:], maskfile)

# save the full dataset
ds.save(outfile)
