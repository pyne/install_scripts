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
    git clone --branch Version5.1.0 --single-branch https://bitbucket.org/fathomteam/moab moab-repo
    cd moab-repo
    autoreconf -fi
    mkdir -p build
    cd build
    ../configure --enable-shared --enable-dagmc --enable-pymoab --with-hdf5=$hdf5_libdir --prefix=$install_dir/moab
    make
    make install
    export LD_LIBRARY_PATH=$install_dir/moab/lib:$LD_LIBRARY_PATH
    export LIBRARY_PATH=$install_dir/moab/lib:$LIBRARY_PATH
    echo "export LD_LIBRARY_PATH=$install_dir/moab/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
    echo "export LIBRARY_PATH=$install_dir/moab/lib:\$LIBRARY_PATH" >> ~/.bashrc
    echo "export CPLUS_INCLUDE_PATH=$install_dir/moab/include:\$CPLUS_INCLUDE_PATH" >> ~/.bashrc
    echo "export C_INCLUDE_PATH=$install_dir/moab/include:\$C_INCLUDE_PATH" >> ~/.bashrc

    PYTHON_VERSION= $(python -c 'import sys; print(sys.version.split('')[0][0:3])')
    echo "if [ -z \$PYTHONPATH ]" >> ~/.bashrc
    echo "then" >> ~/.bashrc >> ~/.bashrc
    echo "  export PYTHONPATH=$install_dir/moab/lib/python${PYTHON_VERSION}/site-packages" >> ~/.bashrc
    echo "else" >> ~/.bashrc
    echo "  export PYTHONPATH=$install_dir/moab/lib/python${PYTHON_VERSION}/site-packages:\$PYTHONPATH" >> ~/.bashrc
    echo "fi" >> ~/.bashrc
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

    cd tests

    # check which python version to run correct tests
    version=`python -c 'import sys; print(sys.version_info[:][0])'`

    # Run all the tests
    if [ $version == '2' ] ; then
        source ./travis-run-tests.sh python2
    elif [ $version == '3' ] ; then
        source ./travis-run-tests.sh python3
    fi
}


set -euo pipefail
IFS=$'\n\t'

# system update
eval brew update
eval brew install $brew_package_list
export PATH="$HOME/.local/bin:$PATH"
eval pip3 install --user --upgrade pip3
eval pip3 install --user $pip_package_list

install_dir=$HOME/opt
mkdir -p $install_dir

# need to put libhdf5.so on LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$hdf5_libdir
export LIBRARY_PATH=$hdf5_libdir
echo "export LD_LIBRARY_PATH=$hdf5_libdir" >> ~/.bashrc

build_moab

install_pyne $1

nuc_data_make

test_pyne $1

echo "Run 'source ~/.bashrc' to update environment variables. PyNE may not function correctly without doing so."
echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $install_dir/pyne"
