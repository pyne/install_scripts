#!/bin/bash
# This script contains common code for building PyNE on various Debian-derived systems
#

function check_repo() {

    repo_name=$1

    if [ -d $repo_name ] ; then
        read -p "Delete the existing $repo_name directory and all contents? (y/n) " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]] ; then
            rm -rf $repo_name
        fi
    fi  
    
}

function build_moab {

    # Install MOAB
    cd $install_dir
    mkdir -p moab
    cd moab
    check_repo moab-repo
    git clone --branch Version4.9.1 --single-branch https://bitbucket.org/fathomteam/moab moab-repo
    cd moab-repo
    autoreconf -fi
    mkdir -p build
    cd build
    ../configure --enable-shared --enable-dagmc --with-hdf5=$hdf5_libdir --prefix=$install_dir/moab
    make
    make install
    export LD_LIBRARY_PATH=$install_dir/moab/lib:$LD_LIBRARY_PATH
    export LIBRARY_PATH=$install_dir/moab/lib:$LIBRARY_PATH
    echo "export LD_LIBRARY_PATH=$install_dir/moab/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
    echo "export LIBRARY_PATH=$install_dir/moab/lib:\$LIBRARY_PATH" >> ~/.bashrc
    echo "export CPLUS_INCLUDE_PATH=$install_dir/moab/include:\$CPLUS_INCLUDE_PATH" >> ~/.bashrc
    echo "export C_INCLUDE_PATH=$install_dir/moab/include:\$C_INCLUDE_PATH" >> ~/.bashrc
}


function build_pytaps {

    cd $install_dir
    # Install PyTAPS
    wget https://pypi.python.org/packages/source/P/PyTAPS/PyTAPS-1.4.tar.gz
    tar zxvf PyTAPS-1.4.tar.gz
    rm PyTAPS-1.4.tar.gz
    cd PyTAPS-1.4/
    python setup.py --iMesh-path=$install_dir/moab --without-iRel --without-iGeom install --user

}

function install_pyne {

    # Install PyNE
    cd $install_dir
    check_repo pyne
    git clone https://github.com/pyne/pyne.git
    cd pyne
    if [ $1 == 'stable' ] ; then
        TAG=$(git describe --abbrev=0 --tags)
        git checkout tags/`echo $TAG` -b `echo $TAG`
    fi
    python setup.py install --user -- -DMOAB_LIBRARY=$install_dir/moab/lib -DMOAB_INCLUDE_DIR=$install_dir/moab/include
    echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc
    echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
    echo "alias build_pyne='python setup.py install --user -- -DMOAB_LIBRARY=$install_dir/moab/lib -DMOAB_INCLUDE_DIR=$install_dir/moab/include'" >> ~/.bashrc

}

function nuc_data_make {

    # Generate nuclear data file
    export LD_LIBRARY_PATH=$HOME/.local/lib:$LD_LIBRARY_PATH
    ./scripts/nuc_data_make
    
}

function test_pyne {
    
    # only test for python version if using the most recent dev branch
    if [ $1 == 'dev' ] ; then
    
        # check which python version to run correct tests
        version=`python -c 'import sys; print(sys.version_info[:][0])'`

        # Run all the tests
        cd tests
        if [ $version == '2' ] ; then
            source ./travis-run-tests.sh python2
        elif [ $version == '3' ] ; then
            source ./travis-run-tests.sh python3
        fi

    elif [ $1 == 'stable' ] ; then
        source ./travis-run-tests.sh
    fi
}


set -euo pipefail
IFS=$'\n\t'

# system update
eval apt-get install -y $package_list

install_dir=$HOME/opt
mkdir -p $install_dir

# need to put libhdf5.so on LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$hdf5_libdir
export LIBRARY_PATH=$hdf5_libdir
echo "export LD_LIBRARY_PATH=$hdf5_libdir" >> ~/.bashrc

build_moab

build_pytaps

install_pyne

nuc_data_make

test_pyne

echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $install_dir/pyne"
