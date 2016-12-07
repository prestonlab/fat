#!/bin/bash

fslhd $1 > hdr1.txt
fslhd $2 > hdr2.txt

diff hdr1.txt hdr2.txt
rm hdr{1,2}.txt
