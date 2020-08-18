#!/bin/bash
# This script contains common code for building PyNE on various Debian-derived systems
#

# system update
eval sudo apt-get -y update
eval sudo apt-get install -y ${apt_package_list}
eval python -m pip install --user --upgrade pip
eval pip install --user ${pip_package_list}

install_dir=${HOME}/opt
mkdir -p ${install_dir}

# need to put libhdf5.so on LD_LIBRARY_PATH
echo "export LD_LIBRARY_PATH=${hdf5_libdir}" >> ~/.bashrc
echo "export LIBRARY_PATH=${hdf5_libdir}" >> ~/.bashrc

./install_moab ${install_dir}

./install_dagmc ${install_dir}

echo "Run 'source ~/.bashrc' to update environment variables. PyNE may not function correctly without doing so."
