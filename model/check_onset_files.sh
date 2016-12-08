#!/bin/bash

for fsf; do
    if [ ! -e $fsf ]; then
	echo "Error: FSF file does not exist: $fsf"
	exit 1
    fi

    files=$(grep "fmri(custom" $fsf | awk -F '"' '{print $2}')
    for f in $files; do
	if [ ! -e $f ]; then
	    echo "missing: $f"
	elif [ ! -s $f ]; then
	    echo "empty:   $f"
	fi
    done
done
