#!/bin/bash
# This script builds the repo version of PyNE (with the MOAB optional
# dependency) from scratch on MacOS 10.15.6. The folder $HOME/opt is created
# and PyNE is installed within.
#
# Run this script from any directory by issuing the command where <version>
# is either "dev" or "stable":
# $ ./osx_10.15.6.sh <version>
# After the build finishes run:
#  $ source ~/.bashrc
# or open a new terminal.

# Use package manager for as many packages as possible
brew_package_list="glib python3 wget eigen \
             git cmake vim emacs gcc openblas \
             lapack autoconf libtool make hdf5"

pip_package_list="numpy scipy cython nose tables matplotlib jinja2 \
                  setuptools h5py"

hdf5_libdir=/usr/lib/x86_64-linux-gnu/hdf5/serial


source macosx.sh $1
