#!/bin/bash
# This script builds the repo version of PyNE (with the MOAB optional
# dependency) from scratch on Ubuntu 18.04. The folder $HOME/opt is created
# and PyNE is installed within.
#
# Run this script from any directory by issuing the command where <version>
# is either "dev" or "stable":
# $ ./ubuntu_18.04.sh <version>
# After the build finishes run:
#  $ source ~/.bashrc
# or open a new terminal.

# Use package manager for as many packages as possible
apt_package_list="software-properties-common wget \
             build-essential git cmake gfortran libblas-dev libpython3-dev python3-dev \
             liblapack-dev libeigen3-dev libhdf5-serial-dev libhdf5-dev autoconf libtool hdf5-tools "

pip_package_list="numpy scipy cython nose tables matplotlib jinja2 \
                  setuptools future"

hdf5_libdir=/usr/lib/x86_64-linux-gnu/hdf5/serial


source ubuntu_mint.sh $1
