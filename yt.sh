#!/bin/bash
# This script builds the repo version of yt, after PyNE has already been
# installed with the ubuntu_14.04.sh script.
# Run this script from any directory by issuing the command:
# $ ./yt.sh
#
set -euo pipefail
IFS=$'\n\t'
sudo apt-get install -y mercurial python-setuptools python-h5py python-sympy
cd $HOME/opt
hg clone https://bitbucket.org/yt_analysis/yt
cd yt
python setup.py install --user
