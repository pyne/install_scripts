#!/bin/bash

set -e
source utils.sh

install_dir=$1

source ~/.bashrc

# pre-setup
cd ${install_dir}
check_repo moab
mkdir -p moab
cd moab

# clone and version
git clone --branch Version5.2.0 --single-branch https://bitbucket.org/fathomteam/moab moab-repo
cd moab-repo
mkdir -p build
cd build

# cmake, build and install
cmake ../ -DENABLE_HDF5=ON -DHDF5_ROOT=${hdf5_libdir} \
            -DBUILD_SHARED_LIBS=ON \
            -DENABLE_PYMOAB=ON \
            -DENABLE_BLASLAPACK=OFF \
            -DENABLE_FORTRAN=OFF \
            -DCMAKE_INSTALL_PREFIX=${install_dir}/moab
make
make install

# Adding MOAB/lib to $LD_LIBRARY_PATH and $LIBRARY_PATH
add_export_var_to_bashrc 'LD_LIBRARY_PATH' "${install_dir}/moab/lib"
add_export_var_to_bashrc 'LIBRARY_PATH' "${install_dir}/moab/lib"

# Adding MOAB/include to $CPLUS_INCLUDE_PATH and $_INCLUDE_PATH
add_export_var_to_bashrc 'CPLUS_INCLUDE_PATH' "${install_dir}/moab/include"
add_export_var_to_bashrc 'C_INCLUDE_PATH' "${install_dir}/moab/include"

# Adding pymoab to $PYTHONPATH
PYTHON_VERSION=$(python -c 'import sys; print(sys.version.split('')[0][0:3])')
add_export_var_to_bashrc 'PYTHONPATH' "$install_dir/moab/lib/python${PYTHON_VERSION}/site-packages"
