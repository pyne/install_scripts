#!/bin/bash
# This script builds the repo version of PyNE (with the MOAB optional 
# dependency) from scratch on Mint 17.03. The folder $HOME/opt is created 
# and PyNE is installed within.
#
# Run this script from any directory by issuing the command where <version>
# is either "dev" or "stable":
# $ ./mint_17.03.sh <version>
# After the build finishes run:
#  $ source ~/.bashrc
# or open a new terminal.

# Use package manager for as many packages as possible
package_list="software-properties-common python-software-properties wget \
             build-essential python-numpy python-scipy cython \
             python-nose git cmake vim emacs gfortran libblas-dev \
             liblapack-dev libhdf5-dev gfortran python-tables  \
             python-matplotlib python-jinja2 autoconf libtool \
             automake python-setuptools libpython-dev"

hdf5_libdir=/usr/lib/x86_64-linux-gnu


source ubuntu_mint.sh $1
