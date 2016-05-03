#!/bin/bash

if [ $# -lt 2 ]; then
    echo "submit_subj_job.sh   Submits jobs for multiple subjects."
    echo
    echo "Usage: submit_subj_job.sh commands subjects [options]"
    echo "See launch for explanation of options."
    echo
    echo "In the commands string, any '{}' will be replaced with"
    echo "subject identifier. Takes subject numbers (e.g. 1, 2)"
    echo "and constructs them in the format [study]_DD, e.g. bender_01."
    echo
    echo "Example 1:"
    echo "export STUDY=bender"
    echo 'submit_subj_job.sh "convert_dicom.py {}" "1 2 3 4" -r 01:00:00 -e 4'
    echo "runs convert_dicom.py bender_01, convert_dicom.py bender_02, ..."
    echo "running 4 subjects per node, with 1 hour allocated to the job."
    echo "The export command can be placed in your .bashrc."
    echo
    echo "Example 2:"
    echo 'submit_subj_job.sh "echo {};echo{}-2" "1 2 3 4" -r 01:00:00'
    echo "Can separate different commands to be run in parallel for a given"
    echo "subject with ':'. Here, will run e.g. 'echo bender_01' and"
    echo "'echo bender_01-2' in parallel. This can be used to batch"
    echo "multiple commands per subject in a single job."
    exit 1
fi

command="$1"
nos="$2"
shift 2

nos=`echo $nos | sed "s/:/ /g"`
jobfile=`get_auto_jobfile.sh`
n=0
for no in $nos; do
    n=$((n + 1))
    subject=${STUDY}_`printf "%02d" $no`

    # fill in subject ID and split commands
    subj_command=`echo $command | sed s/{}/$subject/g | tr ':' '\n'`
    echo -e "$subj_command" >> $jobfile
    echo "$subj_command"
done

chmod +x $jobfile

cd `dirname $jobfile`
file=`basename $jobfile`
name=`echo $file | cut -d . -f 1`

launch -s $jobfile -J $name "$@"
