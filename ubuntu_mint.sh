#!/bin/bash
# This script contains common code for building PyNE on various Debian-derived systems
#

function build_dagmc {

    # Install DAGMC
    cd ${install_dir}
    check_repo dagmc
    mkdir -p dagmc
    cd dagmc
    git clone https://github.com/svalinn/DAGMC.git dagmc-repo
    cd dagmc-repo
    git checkout develop
    mkdir build
    cd build
    cmake .. -DMOAB_DIR=${install_dir}/moab \
             -DBUILD_STATIC_LIBS=OFF \
             -DCMAKE_INSTALL_PREFIX=${install_dir}/dagmc
    make
    make install
}

function install_pyne {

}

function nuc_data_make {

    # Generate nuclear data file
    export LD_LIBRARY_PATH=${HOME}/.local/lib:${LD_LIBRARY_PATH}
    cd ${HOME}
    nuc_data_make

}

function test_pyne {

    cd tests

    # check which python version to run correct tests
    version=`python -c 'import sys; print(sys.version_info[:][0])'`

    # Run all the tests
    if [ ${version} == '2' ] ; then
        source ./travis-run-tests.sh python2
    elif [ ${version} == '3' ] ; then
        source ./travis-run-tests.sh python3
    fi
}


set -euo pipefail
IFS=$'\n\t'

# system update
eval sudo apt-get -y update
eval sudo apt-get install -y ${apt_package_list}
export PATH="${HOME}/.local/bin:${PATH}"
eval python -m pip install --user --upgrade pip
eval pip install --user ${pip_package_list}

install_dir=${HOME}/opt
mkdir -p ${install_dir}

# need to put libhdf5.so on LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${hdf5_libdir}
export LIBRARY_PATH=${hdf5_libdir}
echo "export LD_LIBRARY_PATH=${hdf5_libdir}" >> ~/.bashrc

build_moab

build_dagmc

install_pyne $1

nuc_data_make

test_pyne

echo "Run 'source ~/.bashrc' to update environment variables. PyNE may not function correctly without doing so."
echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from ${install_dir}/pyne"
