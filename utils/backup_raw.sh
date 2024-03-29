#!/bin/bash

if [ $# -eq 0 ]; then
    cat <<EOF
Usage:   backup_raw.sh subject_dicom_dir studytype study subject
Example: backup_raw.sh remind_202a fmri remind remind_202a
Use the '-o' flag to skip overwrite check
EOF
    exit 1
fi

DATADIR=/corral-repl/utexas/prestonlab
has_sk_option=false
while getopts ":od" opt; do 
    case $opt in
        o) 
           echo "-o triggered overwrite check skipped" >&2
           has_o_option=true
           ;;
	d) 
	   echo "-d triggered dicom check skipped" >&2 
	   has_d_option=true
	   ;;
    esac
done 


raw_dir="$1"
studytype="$2"
study="$3"
subject="$4"

if [ ! -d $raw_dir ]; then
    echo "Raw directory does not exist: ${raw_dir}. Quitting..."
    exit 2
fi

# determine directories
parent_dir=$(dirname $raw_dir)
src=$parent_dir/raw_${subject}.tar.gz
destdir=$DATADIR/raw/$studytype/$study

mkdir -p $destdir
dest=$DATADIR/raw/$studytype/$study/raw_${subject}.tar.gz

if [ "$has_o_option" == false ]; then
   if [ -e $dest ]; then
      echo "This file already exists would you like to overwrite?"
      read varname
      if [ $varname == "yes" ] || [ $varname == "y" ]; then
         echo "overwriting file"
      else 
         echo "Quitting operation"
	 exit 1
      fi 
   fi
fi 
# sanity checks
isvalid=false
if [ "$has_d_option" == false ]; then


    for subdir in $raw_dir/*; do
	if [ -d $subdir ]; then
	    # this is a directory
	    # check for any dicoms
	    has_dicoms=false
	    for file in $subdir/*; do
		if [ ${file: -4} == ".dcm" ] || [ ${file: -4} == ".IMA" ]; then 
		    # if good, set isvalid to true and break
		    isvalid=true
		    has_dicoms=true 
		    break
		fi
	    done
	fi
    done
fi 
# is this a valid directory with dicom subdirectories?

if [ "$isvalid" == false ] & [ "$has_d_option" == true ]; then
    echo "There is no raw data in this directory"
fi
# compress raw files
if [ ! -f $src ]; then
    echo "Compressing raw files in $src..."
fi

# archive the raw tar file
if [ -f $src ] || tar czf $src $raw_dir; then
    echo "Sending raw data to corral raw directory..."
    mv $src $dest
else
    echo "Error: problem compressing data."
    exit 1
fi

# set permissions for raw tar file
chmod 775 $dest

