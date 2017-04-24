#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Revert the registration of a level 1 model to native space."
    echo "Assumes that transform_level1.py or similar was used for"
    echo "transforming the images."
    echo
    echo "Usage: revert_level1_reg.sh featdir"
    exit 1
fi

featdir=$1

if [ ! -d $featdir ]; then
    echo "Feat directory does not exist: $featdir"
    exit 1
fi

if [ ! -d $featdir/native ]; then
    echo "Feat directory does not have native directory; cannot revert."
    exit 1
fi

if cd $featdir; then
    # unpack native backup dir
    if [ -d native/stats ]; then
	rm -rf stats
	mv native/stats .
    fi
    immv native/{example_func,mask,mean_func} .
    rmdir native

    # delete registration directories
    rm -rf reg
    rm -rf reg_standard
else
    echo "Problem changing to Feat directory."
    exit 1
fi
