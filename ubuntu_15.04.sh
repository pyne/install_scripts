#!/bin/bash
# This script builds the repo version of PyNE (with the MOAB optional 
# dependency) from scratch on Ubuntu 15.04. The folder $HOME/opt is created 
# and PyNE is installed within.
#
# Run this script from any directory by issuing the command:
# $ ./ubuntu_15.04.sh
# After the build finishes run:
#  $ source ~/.bashrc
# or open a new terminal.

# Use package manager for as many packages as possible
package_list="software-properties-common python-software-properties wget \
             build-essential python-numpy python-scipy cython \
             python-nose git cmake vim emacs gfortran libblas-dev \
             liblapack-dev libhdf5-dev gfortran python-tables  \
             python-matplotlib python-jinja2 autoconf libtool"
hdf5_libdir=/usr/lib/x86_64-linux-gnu/hdf5/serial


source ubuntu_mint.sh
