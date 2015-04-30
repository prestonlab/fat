#!/bin/bash

for subj in $SUBJIDS; do
    command="$1 $subj"
    eval $command
done

