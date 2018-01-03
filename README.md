FAT
===

Functional analysis toolbox: scripts for analysis of fMRI data. See the [Wiki](https://github.com/prestonlab/fat/wiki) for detailed documentation.

## Setting up your environment

Some scripts in the toolbox use environment variables so you don't have to specify the same options every time (they can usually be specified on the commandline also):

* `STUDYDIR` - path to the main study directory, where the subject
  directories are (e.g. `/work/03206/mortonne/lonestar/bender`)
* `BATCHDIR` - path to the directory where batch scripts should be
  stored. Your work directory might be a good place for this. It may
  also be helpful to have a directory that is specific to the study
  you're currently working
  on. (e.g. `/work/03206/mortonne/batch/bender`)
* `PATH` and `PYTHONPATH` must be set to include `fat/utils` and
  `fat/preproc`.
* `SUBJIDFORMAT` - format for creating subject IDs from subject numbers. For example,
  if `SUBJIDFORMAT=bender_%02d`, then every subject ID will be `bender_` followed by a
  two-digit number. This can optionally be used by some scripts to make specifying subjects easier (e.g. run_subjs.sh; see [Running Scripts](https://github.com/prestonlab/fat/wiki/Running-Scripts)). For example:
  ```bash
  export SUBJIDFORMAT=No_%03d
  run_subjs.sh -n "convert_dicom.py {}" 3:4:5
  ```
  This will print the convert_dicom.py command for each subject (No_003, No_004, and No_005), one line per command. Remove the -n flag to actually run the commands.

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
