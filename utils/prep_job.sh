#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: prep_job.sh [command] [file]"
    exit 1
fi

cd $BATCHDIR
command=$1
file=$2

echo "Creating job file $file..."
echo "Command: $command"
echo $command > $file
chmod +x $file

if [ ! -e $file ]; then
    echo "Problem creating job file."
    exit 1
fi
echo "Job file created."

