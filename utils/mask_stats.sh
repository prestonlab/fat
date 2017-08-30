#!/bin/bash

snr="$1"
shift

nfile=$(echo "$snr" | wc -w)
for mask; do
    n=0
    for file in $snr; do
	n=$((n+1))
	mean=$(fslstats $file -k $mask -m)
	maskname=$(basename $mask .nii.gz)
	#echo "$maskname $mean"
	if [ $n -eq 1 ]; then
	    printf "%-10s %.2f" $maskname $mean
	else
	    printf " %.2f" $mean
	fi
	if [ $n -eq $nfile ]; then
	    printf "\n"
	fi
    done
done
