#!/bin/bash
# This script builds the repo version of PyNE (with the MOAB optional 
# dependency) from scratch on Ubuntu 14.04. The folder $HOME/opt is created 
# and PyNE is installed within.
#
# Run this script from any directory by issuing the command:
# $ ./ubuntu_14.04.sh
# After the build finishes run:
#  $ source ~/.bashrc
# or open a new terminal.
set -euo pipefail
IFS=$'\n\t'
# Use package manager for as many packages as possible
sudo apt-get install -y build-essential python-numpy python-scipy cython \
                        python-nose git cmake vim emacs gfortran libblas-dev \
                        liblapack-dev libhdf5-dev gfortran python-tables \
                        python-matplotlib
# need to put libhdf5.so on LD_LIBRARY_PATH
export LD_LIBARY_PATH=/usr/lib/x86_64-linux-gnu
echo "export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu" >> ~/.bashrc
cd $HOME
mkdir opt
cd opt
# Install MOAB
mkdir moab
cd moab
wget http://ftp.mcs.anl.gov/pub/fathom/moab-4.6.2.tar.gz
tar zxvf moab-4.6.2.tar.gz
rm moab-4.6.2.tar.gz
mkdir build
cd build
../moab-4.6.2/configure --enable-shared --prefix=$HOME/.local
make
make install
export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH
export LIBRARY_PATH=$HOME/.local/lib:\$LIBRARY_PATH
echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
echo "export LIBRARY_PATH=$HOME/.local/lib:\$LIBRARY_PATH" >> ~/.bashrc
echo "export CPLUS_INCLUDE_PATH=$HOME/.local/include:\$CPLUS_INCLUDE_PATH" >> ~/.bashrc
echo "export C_INCLUDE_PATH=$HOME/.local/include:\$C_INCLUDE_PATH" >> ~/.bashrc
cd ../../
# Install PyTAPS
wget https://pypi.python.org/packages/source/P/PyTAPS/PyTAPS-1.4.tar.gz
tar zxvf PyTAPS-1.4.tar.gz
rm PyTAPS-1.4.tar.gz
cd PyTAPS-1.4/
python setup.py --iMesh-path=$HOME/.local/ install --user
cd ..
# Install PyNE
git clone https://github.com/pyne/pyne.git
cd pyne
python setup.py install --hdf5=$HOME/opt/hdf5 --user
echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
# Generate nuclear data file
cd scripts
./nuc_data_make
cd ..
# Run all the tests
cd tests
nosetests
