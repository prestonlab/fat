#!/bin/bash

if [ $# -lt 3 ]; then
    echo "rename_func.sh   Rename and renumber functional scans."
    echo
    echo "Usage:   rename_func.sh olddir newdir oldbase newbase"
    echo "Example: rename_func.sh /corral-repl/utexas/prestonlab/bender/bender_1a/BOLD /corral-repl/utexas/prestonlab/bender/bender_1/BOLD functional_study_ study_"
    exit 1
fi

olddir=$1
newdir=$2
oldbase=$3
newbase=$4

# get all run numbers
oldrunnos=`get_run_nos ${olddir} ${oldbase}`

count=0
for oldno in $oldrunnos; do
    count=$(($count+1))
    oldrundir=${olddir}/${oldbase}${oldno}
    newrundir=${newdir}/${newbase}${count}
    mv $oldrundir $newrundir
done
