#!/bin/bash
#
#  get_auto_jobfile.sh   Generate a job file with a serial number.
#
#  Usage:
#  get_auto_jobfile.sh [base]
#
#  If base is not specified, "Job" will be used. The file will be in BATCHDIR.

if [ $# -lt 1 ]; then
    base=Job
else
    base="$1"
fi

if [ -z $BATCHDIR ]; then
    echo "Error: Must define BATCHDIR to indicate directory to save jobs in." >&2
    exit 1
fi

mkdir -p $BATCHDIR

cd $BATCHDIR

if [ ! -e "${base}"1.sh ]; then
    file="${base}"1.sh
else
    start=$((${#base}+1))
    max=0
    for filename in "${base}"*.sh; do
	n=$(echo $filename | cut -c ${start}- | cut -d . -f 1)
	((n > max)) && max=$n
    done
    file="${base}"$(( max + 1 )).sh
fi
echo ${BATCHDIR}/${file}
