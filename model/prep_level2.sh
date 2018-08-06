#!/bin/bash

if [ $# -eq 0 ]
then
    cat <<EOF
Prepare level 2 analysis from an example FSF file.

Usage:
prep_level2.sh [-p] example outdir model orig_subj all_subj

Example:
prep_level2.sh disp_stim_mistr_02.fsf \$STUDYDIR/batch/glm/disp_stim/fsf disp_stim mistr_02 \$SUBJIDS

Inputs:
example
    Path to example FSF file created using FEAT for one subject.

outdir
    Path to output directory. Customized FSF files for each subject
    will be saved in this directory.

model
    Model name. Used to set the filenames of the FSF files.

orig_subj
    Subject ID for the subject used in the example FSF file.

all_subj
    Colon-separated list of all subjects to create FSF files for.

Options:
-p
    Include partial inputs. If this option is set, will check whether
    each of the level 1 FEAT directories listed in the FSF file exists.
    Any directories that do not exist for a subject will be excluded from
    that subject's level 2 FSF file.
EOF
    exit 1
fi

partial=false
while getopts ":p" opt; do
    case $opt in
	p)
	    partial=true
	    ;;
    esac
done
shift $((OPTIND-1))

example="$1"
outdir="$2"
model="$3"
orig_subj="$4"
all_subj="$5"

mkdir -p "$outdir"

for subj in $(echo $all_subj | tr ':' ' '); do
    # create the customized file
    customfsf="$outdir"/${model}_${subj}.fsf
    sed -e "s|${orig_subj}|${subj}|g" <"$example" >"$customfsf"

    if [ $partial = true ]; then
	# get all included level 1 feat directories
	files=$(grep feat_files "$customfsf" | cut -d '"' -f 2 | tr '\n' ' ')

	# only feat directories that exist
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
	    rm "$customfsf"
	else
	    # some inputs exist; create custom fsf file
	    gfeat_subset "$customfsf" temp $include
	    mv temp "$customfsf"
	fi
    fi
done
