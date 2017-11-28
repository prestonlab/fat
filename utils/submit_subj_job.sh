#!/bin/bash

if [ $# -lt 2 ]; then
    echo "submit_subj_job.sh   Submit jobs for multiple subjects."
    echo
    echo "Usage: submit_subj_job.sh [pre-options] commands subjects [options]"
    echo
    echo "Construct a command for multiple subjects and submit a job to"
    echo "run the commands in parallel."
    echo
    echo "Run launch -h for explanation of options. Using the -t option"
    echo "to create the job file but not launch can be a good idea to"
    echo "make sure you get the commands you expected. Then you can run"
    echo "sbatch on the .slurm file to submit."
    echo
    echo "You must first define the BATCHDIR variable to indicate where"
    echo "to save jobs. See submit_job.sh for more information about setup."
    echo
    echo "In the commands string, any '{}' will be replaced with"
    echo "subject identifier. Takes subject numbers (e.g. 1, 2)"
    echo "and constructs them in the format [study]_DD, e.g. bender_01."
    echo
    echo "Pre-options:"
    echo "-t"
    echo "    Test; just display all commands that would be run."
    echo
    echo "-f file"
    echo "    Test for a file dependency. Any {} is replaced with the"
    echo "    subject, and that subject is only run if the file exists."
    echo
    echo "-n file"
    echo "    Test for an output that does not exist. Any {} is replaced"
    echo "    with the subject, and that subject only runs if the file"
    echo "    does not exist."
    echo
    echo "Example:"
    echo "export SUBJIDFORMAT=bender_%02d"
    echo "export BATCHDIR=$WORK/batch"
    echo "export SUBJNOS=1:2:3:4"
    echo 'submit_subj_job.sh "convert_dicom.py {}" $SUBJNOS -N 1 -n 4 -r 00:30:00'
    echo "runs convert_dicom.py bender_01, convert_dicom.py bender_02, ..."
    echo "running subjects in parallel on one node, with 30 minutes"
    echo "allocated to the job."
    echo "The export commands can be placed in your .bashrc. This makes it"
    echo "quick to run different commands on a large list of subjects, just"
    echo "writing the list once in your .bashrc."
    echo
    echo "See also run_subjs.sh for a version that runs commands locally."
    echo
    exit 1
fi

test=false
runifexist=false
runifmissing=false
while getopts ":f:n:t" opt; do
    case $opt in
	t)
	    test=true
	    ;;
	f)
	    runifexist=true
	    file="$OPTARG"
	    ;;
	n)
	    runifmissing=true
	    file="$OPTARG"
	    ;;
    esac
done
shift $((OPTIND-1))

command="$1"
nos="$2"
shift 2

nos=$(echo $nos | sed "s/:/ /g")

jobfile=$(get_auto_jobfile.sh)
for no in $nos; do
    subject=$(subjids $no)

    if [ $runifexist = true ]; then
	subj_file=$(echo "$file" | sed s/{}/$subject/g)
	if [ ! -f "$subj_file" ]; then
	    echo "Missing file: $subj_file"
	    continue
	fi
    elif [ $runifmissing = true ]; then
	subj_file=$(echo "$file" | sed s/{}/$subject/g)
	if [ -f "$subj_file" ]; then
	    echo "File exists: $subj_file"
	    continue
	fi
    fi
    
    # fill in subject ID and split commands
    subj_command=$(echo $command | sed s/{}/$subject/g | tr ':' '\n')
    echo "$subj_command"
    
    if [ $test = false ]; then
	echo -e "$subj_command" >> $jobfile
    fi
done

if [ $test = true ]; then
    exit 1
fi

chmod +x $jobfile

file=$(basename $jobfile)
name=$(echo $file | cut -d . -f 1)

outfile=$BATCHDIR/${name}.out
batchfile=$BATCHDIR/${name}.slurm
launch -s $jobfile -J $name -o $outfile -f $batchfile -k "$@"
