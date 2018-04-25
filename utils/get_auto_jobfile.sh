#!/bin/bash
if [ -z $BATCHDIR ]; then
    echo "Error: Must define BATCHDIR to indicate directory to save jobs in." >&2
    exit 1
fi

mkdir -p $BATCHDIR

cd $BATCHDIR

if [ ! -e Job1.sh ]; then
    file=Job1.sh
else
    ar=(`/bin/ls Job*.sh -1 | cut -c 4- | cut -d . -f 1`)

    max=0
    for n in "${ar[@]}" ; do
	((n > max)) && max=$n
    done
    file=Job$(( max + 1 )).sh
fi
echo ${BATCHDIR}/${file}
