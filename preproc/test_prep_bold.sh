module use /work/IRC/ls5/opt/modules # makes official IRC software available
module load launcher/3.0.2 # TACC program for running many tasks in one job
module load python # language used by many scripts
module load fsl/5.0.9 # main fMRI analysis package
module load fslview
module load ircpy # setup packages like nibabel and pymvpa
module load ants # used for registration and template generation

export PATH=$PATH:/work/IRC/ls5/opt/local/apps/mricron # make correct version of dcm2nii available
export PATH=$PATH:/work/IRC/ls5/opt/local/apps/c3d # make c3d_affine_tool available

fatdir=$HOME/analysis/fat # path to cloned fat project
qadir=$HOME/analysis/fmriqa # path to clone fmriqa project
srcdir=$HOME/analysis/bender # path to cloned bender project

export PATH=$PATH:$fatdir/preproc:$fatdir/utils:$fatdir/model:$fatdir/anatomy:$qadir
export PATH=$PATH:$srcdir/preproc
export PYTHONPATH=$PYTHONPATH:$fatdir/utils:$fatdir/preproc:$qadir

export ANTSPATH=/work/IRC/ls5/opt/apps/ants/bin

mkdir -p temp
cp /corral-repl/utexas/prestonlab/preproc/part6/bender_03/BOLD/prex_1/bold.nii.gz temp

launch -J prep_bold -o prep_bold.o%j -A ANTS -b interleaved -N 1 -n 1 -r 02:00:00 -a 24 -p development "prep_bold_run.sh -k $PWD/temp"
