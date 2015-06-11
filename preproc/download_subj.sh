#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: download_subj.sh [subject ID used for scan]"
    echo "Uses environment variables:"
    echo "  STUDY    study name"
    echo "  DATADIR  main data directory for all experiments"
    exit 1
fi

SUBJID=$1

setup_subject.py --getdata --keepdata -o --studyname $STUDY \
		 -s $SUBJID -b $DATADIR --xnat-project preston
