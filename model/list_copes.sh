#!/bin/bash

# lev3=$1
# copes=$(ls -1dv $lev3/cope*.gfeat)
# for cope in copes; do
#     lev2report=$(grep cope $cope/report_firstlevel.html | grep -oE 'report.html>[^<]*' | cut -d '>' -f 2)
    
lev1=$1
grep conname_orig $lev1 | cut -d '.' -f 2 | tr '"' ' '
