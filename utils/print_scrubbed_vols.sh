#!/bin/bash

studydir=$1
cd $studydir

for subject in No_*; do
    if cd $studydir/$subject/BOLD 2>/dev/null; then
	for run in *_?; do
	    nscrub=0
	    scrubfile=$studydir/$subject/BOLD/$run/QA/scrubvols.txt
	    confoundfile=$studydir/$subject/BOLD/$run/QA/confound.txt
	    if [ -f $scrubfile ]; then
		nscrub=$(wc -l $scrubfile | cut -f 1 -d ' ')
	    fi
	    nvol=$(wc -l $confoundfile | cut -f 1 -d ' ')
	    echo "$studydir/$subject/$run: $nscrub/$nvol"
	done
    fi
done
    
