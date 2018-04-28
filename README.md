FAT pipeline
============

Functional analysis toolbox: a set of scripts defining a pipeline for analysis of fMRI data. The pipeline uses FSL, ANTs, and FreeSurfer. It's designed to improve registration between functional images and high-resolution structural images, co-registration between functional images, and to deal with scan distortions caused by nonlinearities in field gradients.

Scripts are written in Bash in Python, with a high-performance cluster environment in mind. Scripts are optimized for using resources of the Texas Advanced Computing Center (TACC), but should work on any Linux or Unix system. 

See the [Wiki](https://github.com/prestonlab/fat/wiki) for detailed documentation. The [Preprocessing Tutorial](https://github.com/prestonlab/fat/wiki/Tutorial) is a good place to start.
