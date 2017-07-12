#!/bin/bash
# This script contains common code for building PyNE on various Debian-derived systems
#

function system_update {
    
    # Use package manager for as many packages as possible
}

function build_moab {

    # Install MOAB
    mkdir -p moab
    cd moab
    if [ -d moab-repo ] ; then
        read -p "Delete the existing moab-repo directory and all contents? (y/n) " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]] ; then
            rm -rf moab-repo
        fi
    fi  
    git clone --branch Version4.9.1 --single-branch https://bitbucket.org/fathomteam/moab moab-repo
    cd moab-repo
    autoreconf -fi
    cd ..
    mkdir -p build
    cd build
    ../moab/configure --enable-shared --enable-dagmc --with-hdf5=$hdf_libdir --prefix=$HOME/opt/moab
    make
    make install
    export LD_LIBRARY_PATH=$HOME/opt/moab/lib:$LD_LIBRARY_PATH
    export LIBRARY_PATH=$HOME/opt/moab/lib:$LIBRARY_PATH
    echo "export LD_LIBRARY_PATH=$HOME/opt/moab/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
    echo "export LIBRARY_PATH=$HOME/opt/moab/lib:\$LIBRARY_PATH" >> ~/.bashrc
    echo "export CPLUS_INCLUDE_PATH=$HOME/opt/moab/include:\$CPLUS_INCLUDE_PATH" >> ~/.bashrc
    echo "export C_INCLUDE_PATH=$HOME/opt/moab/include:\$C_INCLUDE_PATH" >> ~/.bashrc
    cd ../../
}


function build_pytaps {

    # Install PyTAPS
    wget https://pypi.python.org/packages/source/P/PyTAPS/PyTAPS-1.4.tar.gz
    tar zxvf PyTAPS-1.4.tar.gz
    rm PyTAPS-1.4.tar.gz
    cd PyTAPS-1.4/
    python setup.py --iMesh-path=$HOME/opt/moab --without-iRel --without-iGeom install --user
    cd ..

}

function install_pyne {

# Install PyNE
    git clone https://github.com/pyne/pyne.git
    cd pyne
    python setup.py install --user -- -DMOAB_LIBRARY=$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=$HOME/opt/moab/include
    echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc
    echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
    echo "alias build_pyne='python setup.py install --user -- -DMOAB_LIBRARY=\$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=\$HOME/opt/moab/include'" >> ~/.bashrc

}

function nuc_data_make {

    # Generate nuclear data file
    export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH
    ./scripts/nuc_data_make
    
}

function test_pyne {

    # Run all the tests
    cd tests
    . ./travis-run-tests.sh

}


set -euo pipefail
IFS=$'\n\t'

# system update
eval apt-get install -y $package_list

# need to put libhdf5.so on LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$hdf5_libdir
export LIBRARY_PATH=$hdf5_libdir
echo "export LD_LIBRARY_PATH=$hdf5_libdir" >> ~/.bashrc

cd $HOME
mkdir -p opt
cd opt

build_moab

build_pytaps

install_pyne

echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $HOME/opt/pyne"
