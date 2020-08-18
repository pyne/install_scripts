#!/bin/bash
# list of package installed through apt-get 
# (required to run this scripts and/or as dependancies for PyNE and its depedancies)
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
                  hdf5-tools"

# list of python package required for PyNE and its depedencies (installed using pip3 python package manager)
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

# need to put libhdf5.so on LD_LIBRARY_PATH (Making sure that LD_LIBRARY_PATH is defined first)
if [ -z $LD_LIBRARY_PATH ]; then
  export LD_LIBRARY_PATH="${hdf5_libdir}"
else
  export LD_LIBRARY_PATH="${hdf5_libdir}:$LD_LIBRARY_PATH"
fi


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
export LD_LIBRARY_PATH="${install_dir}/moab/lib:$LD_LIBRARY_PATH"

# Adding pymoab to $PYTHONPATH
PYTHON_VERSION=$(python -c 'import sys; print(sys.version.split('')[0][0:3])')
if [ -z $PYTHONPATH ]; then
  export PYTHONPATH="$install_dir/moab/lib/python${PYTHON_VERSION}/site-packages"
else
  export PYTHONPATH="$install_dir/moab/lib/python${PYTHON_VERSION}/site-packages:$PYTHONPATH"
fi


#############
### DAGMC ###
#############
# pre-setup check that the directory we need are in place
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
export LD_LIBRARY_PATH="${install_dir}/dagmc/lib:$LD_LIBRARY_PATH"

# Adding dagmc/bin to $PATH
if [ -z ${PATH} ]; then
  export PATH="${install_dir}/dagmc/bin"
else
  export PATH="${install_dir}/dagmc/bin:$PATH"
fi

############
### PyNE ###
############

# pre-setup
cd ${install_dir}
check_repo pyne
mkdir -p pyne
cd pyne
# clone and version
git clone https://github.com/pyne/pyne.git pyne-repo
cd pyne-repo
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
export LD_LIBRARY_PATH="${HOME}/.local/lib:$LD_LIBRARY_PATH"
# Adding .local//bin to $PATH
export PATH="${HOME}/.local/bin:$PATH"

# Make Pyne Nuclear Data
cd  # cd without argument will take you back to your $HOME directory
nuc_data_make

# Run tests
cd ${install_dir}/pyne/tests
./travis-run-tests.sh


echo " \
# Add HDF5 \n
if [ -z \$LD_LIBRARY_PATH ]; then \n
  export LD_LIBRARY_PATH=\"${hdf5_libdir}\" \n
else \n
  export LD_LIBRARY_PATH=\"\${hdf5_libdir}:\$LD_LIBRARY_PATH\" \n
fi \n
# Adding MOAB/lib to $LD_LIBRARY_PATH and $LIBRARY_PATH
export LD_LIBRARY_PATH="${install_dir}/moab/lib:$LD_LIBRARY_PATH"

# Adding pymoab to \$PYTHONPATH
PYTHON_VERSION=\$(python -c 'import sys; print(sys.version.split('')[0][0:3])')
if [ -z $PYTHONPATH ]; then
  export PYTHONPATH="$install_dir/moab/lib/python${PYTHON_VERSION}/site-packages"
else
  export PYTHONPATH="$install_dir/moab/lib/python${PYTHON_VERSION}/site-packages:$PYTHONPATH"
fi

export LD_LIBRARY_PATH=\"\${install_dir}/dagmc/lib:\$LD_LIBRARY_PATH\" \n
# Adding dagmc/bin to \$PATH \n
=if [ -z \${PATH} ]; then \n
  export PATH=\"\${install_dir}/dagmc/bin\" \n
else \n
  export PATH=\"\${install_dir}/dagmc/bin:\$PATH\" \n
fi \n
" >> .bashrc
echo "Run 'source ~/.bashrc' to update environment variables. PyNE may not function correctly without doing so."
