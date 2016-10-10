#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: revert_level1.sh featdir"
    exit 1
fi

featdir=$1

if [ ! -d $featdir ]; then
    echo "Error: featdir does not exist: $featdir"
    exit 2
fi

cd $featdir

if [ -d stats_native ]; then
    if [ -d stats ]; then
	rm -rf stats
    fi
    mv stats_native stats
fi

for f in example_func mask mean_func; do
    native=${f}_native.nii.gz
    orig=${f}.nii.gz
    if [ -e $native ]; then
	mv $native $orig
    fi
done
