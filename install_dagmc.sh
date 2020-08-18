#!/bin/bash

set -e
source utils.sh

echo $LD_LIBRARY_PATH

# Making sure MOAB is in the LD_LIBRARY_PATH
source ~/.bashrc

install_dir=$1

# pre-setup
cd ${install_dir}
check_repo dagmc
mkdir -p dagmc
cd dagmc

# clone and version
git clone https://github.com/svalinn/DAGMC.git dagmc-repo
cd dagmc-repo
git checkout develop
mkdir build
cd build

# cmake, build and install
cmake .. -DMOAB_DIR=${install_dir}/moab \
            -DBUILD_STATIC_LIBS=OFF \
            -DCMAKE_INSTALL_PREFIX=${install_dir}/dagmc
make
make install

# Adding DAGMC/lib to $LD_LIBRARY_PATH and $LIBRARY_PATH
add_export_var_to_bashrc "\$LD_LIBRARY_PATH" "${install_dir}/dagmc/lib"
add_export_var_to_bashrc "\$LIBRARY_PATH" "${install_dir}/dagmc/lib"

# Adding dagmc/bin to $PATH
add_export_var_to_bashrc "\$PATH" "${install_dir}/dagmc/bin"
