#!/bin/bash

set -e
source utils.sh

# Making sure MOAB & DAGMC is in the LD_LIBRARY_PATH
source ~/.bashrc

install_dir=$1

# pre-setup
cd ${install_dir}
check_repo pyne

# clone and version
git clone https://github.com/pyne/pyne.git
cd pyne
if [ $1 == 'stable' ] ; then
    TAG=$(git describe --abbrev=0 --tags)
    git checkout tags/`echo ${TAG}` -b `echo ${TAG}`
fi

# Temp during release candidate
git checkout 0.7.0-rc

python setup.py install --user \
                            --moab ${install_dir}/moab \
                            --dagmc ${install_dir}/dagmc \
                            --clean

# Adding .local/lib to $LD_LIBRARY_PATH and $LIBRARY_PATH
add_export_var_to_bashrc "LD_LIBRARY_PATH" "${HOME}/.local/lib"
add_export_var_to_bashrc "LIBRARY_PATH" "${HOME}/.local/lib"

# Adding .local//bin to $PATH
add_export_var_to_bashrc "PATH" "${HOME}/.local/bin"

# Make Pyne Nuclear Data
source ~/.bashrc
cd
nuc_data_make

# Run tests
cd ${install_dir}/pyne/tests
./travis-run-tests.sh