#!/bin/bash

if [ $# -eq 0 ]
then
    echo "Prepare level 2 analysis from an FSL template"
    echo
    echo "Usage:"
    echo "`basename $0` [-d studydir] [-s subjids] [-p] template model"
    echo
    echo "Optional inputs:"
    echo "-d"
    echo "      path to base study directory. If not specified,"
    echo "      STUDYDIR environment variable will be used."
    echo
    echo "-s"
    echo "      list of subject ids, separated by ':'. If not"
    echo "      specified, SUBJIDS environment variable will be used."
    echo
    echo "-p"
    echo "      if set, will allow use of a partial set of level 1 models."
    echo "      Will check for existence of a feat directory for each"
    echo "      run in each subject's fsf file. If all are missing, no"
    echo "      level 2 fsf will be generated. If some are missing, each"
    echo "      level 2 fsf file will just use the level 1 feat directories"
    echo "      that exist."
    echo
    echo "Required inputs:"
    echo "template   path to FSF template"
    echo "model      name of statistical model"
    echo
    echo "These strings will be replaced in the FSF template:"
    echo "STUDYDIR   path to directory with study data"
    echo "SUBJID     full subject identifier, e.g. bender_01"
    echo
    echo 'Customized fsf files will be placed in $STUDYDIR/batch/glm/$model.'
    echo
    exit 1
fi

partial=0
while getopts ":d:s:p" opt; do
    case $opt in
	d)
	    STUDYDIR=$OPTARG
	    ;;
	s)
	    SUBJIDS=$OPTARG
	    ;;
	p)
	    partial=1
	    ;;
    esac
done
shift $((OPTIND-1))

if [ -z $STUDYDIR ]; then
    echo "Error: Study directory undefined."
fi
if [ -z $SUBJIDS ]; then
    echo "Error: Subject identifiers undefined."
fi

template=$1
model=$2

modeldir=${STUDYDIR}/batch/glm/${model}
fsfdir=${modeldir}/fsf
mkdir -p ${fsfdir}

# copy template to standard file
fsftemplate=${modeldir}/${model}_level2.fsf
cp ${template} ${fsftemplate}

sids="`echo $SUBJIDS | sed "s/:/ /g"`"
for subjid in ${sids}; do
    customfsf=${fsfdir}/${model}_${subjid}.fsf

    # create the customized file
    sed -e "s|STUDYDIR|${STUDYDIR}|g" \
	-e "s|SUBJID|${subjid}|g" \
	<${fsftemplate} >${customfsf}

    if [ $partial = 1 ]; then
	# get inputs that exist
	files=$(grep feat_files $customfsf | cut -d '"' -f 2 | tr '\n' ' ')
	include=""
	for f in $files; do
	    if [ -e $f ]; then
		if [ -z "$include" ]; then
		    include=$f
		else
		    include="$include $f"
		fi
	    fi
	done
	
	if [ -z "$include" ]; then
	    # no inputs exist; remove fsf file
	    rm $customfsf
	else
	    # some inputs exist; create custom fsf file
	    gfeat_subset $customfsf temp $include
	    mv temp $customfsf
	fi
    fi
done
