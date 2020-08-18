#!/bin/bash
# Use package manager for as many packages as possible
apt_package_list="software-properties-common \
                  python3-pip \
                  wget \
                  build-essential \
                  git \
                  cmake \
                  gfortran \
                  libblas-dev \
                  liblapack-dev \
                  libeigen3-dev \
                  libhdf5-dev \
                  autoconf \
                  libtool \
                  hdf5-tools"

pip_package_list="numpy \
                  scipy \
                  cython \
                  nose \
                  tables \
                  matplotlib \
                  jinja2 \
                  setuptools \
                  future"

# hdf5 std directory
hdf5_libdir=/usr/lib/x86_64-linux-gnu/hdf5/serial

#!/bin/bash
# This script contains common code for building PyNE on various Debian-derived systems
#
source utils.sh

# system update
sudo apt-get -y update
sudo apt-get install -y ${apt_package_list}
pip3 install --user ${pip_package_list}

install_dir=${HOME}/opt
mkdir -p ${install_dir}

# need to put libhdf5.so on LD_LIBRARY_PATH
echo "export LD_LIBRARY_PATH=${hdf5_libdir}" >> ~/.bashrc
echo "export LIBRARY_PATH=${hdf5_libdir}" >> ~/.bashrc

source ~/.bashrc

############
### MOAB ###
############

# pre-setup
cd ${install_dir}
check_repo moab
mkdir -p moab
cd moab

# clone and version
git clone --branch Version5.1.0 --single-branch https://bitbucket.org/fathomteam/moab moab-repo
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


#############
### DAGMC ###
#############

# Making sure MOAB is in the LD_LIBRARY_PATH
source ~/.bashrc
echo "LD_LIBRARY_PATH ${LD_LIBRARY_PATH}"

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
add_export_var_to_bashrc "LD_LIBRARY_PATH" "${install_dir}/dagmc/lib"
add_export_var_to_bashrc "LIBRARY_PATH" "${install_dir}/dagmc/lib"

# Adding dagmc/bin to $PATH
add_export_var_to_bashrc "PATH" "${install_dir}/dagmc/bin"


############
### PyNE ###
############

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

echo "Run 'source ~/.bashrc' to update environment variables. PyNE may not function correctly without doing so."

