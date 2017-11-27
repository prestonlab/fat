FAT
===

Functional analysis toolbox: scripts for analysis of fMRI data

# Preprocessing

There are a number of simple tools for running preprocessing and
creating standard directory structure and file names. These tools
include most of the basic functionality of `setup_subject.py`, and are
designed to be easier to understand and fix when problems arise.

Here is a list of available preprocessing scripts in the usual order
of execution:

* `convert_dicom.py` Converts DICOM files to Nifti format. This should
  work on either data downloaded from XNAT or files that were exported
  manually.
* `rename_nifti.py` Creates standard sub-directories and renames Nifti
  files to standard names.
* `prep_bold_run.sh` Does basic processing of BOLD runs, including motion
  correction, brain extraction, and quality assurance. Assumes that
  files have been placed in a standard directory structure where each
  run is in a file called `[SUBJECT_DIR]/BOLD/[RUN_NAME]/bold.nii.gz`.
* `merge_anat.sh` Registers and averages anatomical (highres and coronal)
  images. Prepares MPRAGE scans for FreeSurfer.
* `run_freesurfer.sh` Simple script that runs a
  standard FreeSurfer reconstruction on one subject.
* `convert_freesurfer.py` Converts some important FreeSurfer files
  into Nifti format and places them in the anatomy directory.
* `reg_freesurfer.py` If you had multiple highres scans that you merged using merge_anat.sh,
  run this to place the main FreeSurfer outputs into the spaces of the original highres
  scans. Then when running prep_fieldmap.py and epi_reg_run.py, you can then use any of the
  highres scans as a registration target (it's generally best to use the scan taken closest
  in time to the functional scan you're registering).
* `prep_fieldmap.py` Prepares a fieldmap for use with unwarping.
* `epi_reg_run.py` Determines how to unwarp the functional data, and aligns 
  functional data to structural scans.
* `reg_unwarp_bold_run.py` Calculates alignment of each unwarped average
  functional scan to an unwarped average reference scan, then applies
  motion correction, unwarping, co-registration, and mean bias correction
  to a raw functional scan.

## Processing all your data

All scripts are designed to do the minimum amount of processing; for example, prep_bold_run.sh only processes a single run. This allows you to run processing in whatever way makes the most sense for you. If you want to run everything in serial, you can write a script with for loops to process all your functional scans. For example:

```bash
for subject in bender_02 bender_04 bender_05; do
    for run in study_1 study_2 study_3 study_4 study_5 study_6; do
    	prep_bold_run.sh $WORK/bender/$subject/BOLD/$run
    done
done
```

## Setting up your environment

Some scripts in the toolbox use environment variables so you don't have to specify the same options every time (they can usually be specified on the commandline also):

* `STUDY` - name of the study (e.g. `bender`)
* `STUDYDIR` - path to the main study directory, where the subject
  directories are (e.g. `/work/03206/mortonne/lonestar/bender`)
* `BATCHDIR` - path to the directory where batch scripts should be
  stored. Your work directory might be a good place for this. It may
  also be helpful to have a directory that is specific to the study
  you're currently working
  on. (e.g. `/work/03206/mortonne/batch/bender`)
* `PATH` and `PYTHONPATH` must be set to include `fat/utils` and
  `fat/preproc`.

See
[this sample profile](https://github.com/prestonlab/bender/blob/master/bender_profile)
for an example of how to set these environment variables correctly.

## Testing and batch processing

Each of the python preprocessing scripts listed above has standard
options, which you can view by typing `[scriptname] -h`. Each of them
supports a `--dry-run` flag, which just displays the commands that
will be executed without running anything. This is handy for testing
the script out before running it. Once you've confirmed that the
commands make sense, you can easily submit a job by typing:

`submit_job.sh '[scriptname] [subject ID] [other arguments]' [options for launch]`

For example, to test out `convert_dicom.py` on `bender_01`:

`convert_dicom.py bender_01 --dry-run`

To actually submit a job to run the DICOM conversion:

`submit_job.sh 'convert_dicom.py bender_01' -r 00:30:00 -N 1 -n 1`

This will automatically create a script with the command and use
`launch` to submit it to the cluster. The job will be automatically
given a (sequentially ordered) name, and the submitted script will be
in `$BATCHDIR/Job[job number].sh`. When the job finishes, the
output will be placed in
`$BATCHDIR/Job[job number].out`.

More information about each job will be placed in the subject's `logs`
directory. The `preproc.log` file stores summary information about the
preprocessing steps run so far, while step-specific logs contain
details about the commands run and their output.

If you are processing multiple subjects at once and lose track of
which jobs are running, you can use `running_jobs.sh` to list all the
commands being run by jobs currently on the queue:

	login6.ls4(670)$ running_jobs.sh 
	Job50:
	reg_unwarp_bold.py bender_2 study_1
	Job53:
	bender_epi_reg.py bender_3
	Job54:
	bender_reg_days.py bender_5

# Installation

## Getting a copy of a project from GitHub

* Get an account on GitHub
* Send Neal your username so you can be added to the prestonlab group
* To install using the GitHub app (does not work on TACC or on older
Macs):
  * Install the app from the GitHub website
  * Sign into your account
  * Click on the + icon in the upper left; go to the clone tab
  * You should see the repository if you have access to it
  * Select the one you want and click the Clone button, then select
    where you want to place the repository
* To install using ssh (does not require entering a password when
installing code or making changes):
  * Set up an SSH key with GitHub (you only need to do this once for
  each computer, and then it will work for other code repositories).
  See the section "Adding an SSH key" below.
  * On GitHub, go to the page of the project you want. In the lower
right, click on SSH so that the SSH clone URL is displayed. This is
the URL you need to clone the repository.
  * On the computer where you want the code, type `git clone
  [SSH clone URL]`, for example `git clone
  git@github.com:prestonlab/fat.git` to download the repository.
* To install using HTTPS (requires entering a password when making any
changes):
  * On GitHub, go to the page of the project you want. In the lower
    right, click on HTTPS so that the HTTPS clone URL is
    displayed. This is the URL you need to clone the repository.
  * On the computer where you want the code, type `git clone
    [HTTPS clone URL]`, for example `git clone
    https://github.com/prestonlab/fat.git`.
  * Enter your GitHub username and password to download the
    repository.

## Adding an SSH key

Follow these steps to add an SSH key to GitHub so you can push and
pull from git projects without having to enter your password.

* On the computer where you want the code, check if there is a file in
`~/.ssh/id_rsa.pub`. If not, in the terminal run `ssh-keygen`. Hit
enter through all the options to create a passwordless key.
* Type `cat ~/.ssh/id_rsa.pub`; this will display the public key that
you just created. Go to your account page on GitHub and click the
settings icon in the upper right. Click on the "SSH keys" tab, then
"Add SSH Key".
* Copy the public key into the box; give the key a title so you will
know what computer it corresponds to. You will need to generate and
add a different key for each computer you use.
