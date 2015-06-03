fat
===

Functional analysis toolbox: scripts for analysis of fMRI data

# Installation

* Get an account on GitHub
* Send an owner (currently Neal, Mike, or Evan) your username so they
can add you to the prestonlab group
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
  each computer, and then it will work for other code repositories):
  * On the computer where you want the code, check if there is a file
    in `~/.ssh/id_rsa.pub`. If not, in the terminal run
    `ssh-keygen`. Hit enter through all the options to create a
    passwordless key.
    * Type `cat ~/.ssh/id_rsa.pub`; this will display the public key
	  that you just created. Go to your account page on GitHub and
	  click the settings icon in the upper right. Click on the "SSH
	  keys" tab, then "Add SSH Key".
    * Copy the public key into the box; give the key a title so you
      will know what computer it corresponds to. You will need to
      generate and add a different key for each computer you use.
    * On GitHub, go to the page of the project you want. In the lower
      right, click on SSH so that the SSH clone URL is displayed. This
      is the URL you need to clone the repository.
  * On the computer where you want the code, type `git clone
  [SSH clone URL]`, for example `git clone
  https://github.com/prestonlab/fat.git` to download the repository.
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
