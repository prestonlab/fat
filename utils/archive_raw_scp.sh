#!/bin/bash

if [ $# -lt 1 ]; then
    echo "Usage: archive_raw_scp.sh datadir blacklist"
    exit 1
fi

datadir="$1"
blacklist="$2"

filelist=""
for f in $(find "$datadir" -name "*.tar.gz"); do
    # if f in blacklist, continue (probably grep for the exact string,
    if grep -Fxq $f $blacklist; then
	continue
    fi
    # check if anything was returned)
    if [ -z "$filelist" ]; then
        filelist="$f"
    else
        filelist="$filelist $f"
    fi
done

dir=$(dirname "${f}")
echo "scp $filelist ranch.tacc.utexas.edu:raw/$dir"
read -p "send files?" resp
if [ "$resp" = "yes" ]; then
    if scp $filelist ranch.tacc.utexas.edu:raw/$dir; then
        echo "$filelist" | tr ' ' '\n' >> $blacklist
    fi
fi
