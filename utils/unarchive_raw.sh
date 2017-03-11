#!/bin/bash

if [ -u $ARCHIVER ]; then
    ARCHIVER=ranch.tacc.utexas.edu
fi
if [ -u $ARCHIVE ]; then
    ARCHIVE=$HOME
fi

out_dir=$1
study=$2
subject=$3

if [ ! -d $out_dir ]; then
    echo "Output directory does not exist: ${out_dir}. Quitting..."
    exit 2
fi

src=$ARCHIVER:$ARCHIVE/$study/raw/raw_${subject}.tar.gz
scp $src $out_dir
