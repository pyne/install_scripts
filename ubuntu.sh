#!/bin/bash
# This script builds the repo version of PyNE (with the MOAB optional
# dependency) from scratch on Ubuntu 16.04 or 18.04. The folder $HOME/opt is created
# and PyNE is installed within.
#
# Run this script from any directory by issuing the command where <version>
# is either "dev" or "stable":
# $ ./Ubuntu.sh <version> 
# You can optionnaly specify the Ubuntu version you re using either 16.04 or
# 18.4:
# $ ./Ubuntu.sh <version> <Ubuntu_version>
#
# After the build finishes run:
#  $ source ~/.bashrc
# or open a new terminal.

# Use package manager for as many packages as possible


# process the arguments
function proccess_args() {
    if [ $# -lt 2 ]
    then 
        pyne_version=$1
        detect_version
    elif [ $# -eq 2 ]
    then
        pyne_version=$1
        ubuntu_version=$2
    else
        echo "To many arguments provided. This script only accepts 2 \
optionnal arguments:
  1. the version of PyNE you wish to install: \"dev\" or \"stable\"
  2. the Ubuntu version you are using: \"16.04\" or \"18.04\""
        exit 1
    fi
}


# Dectect Ubuntu version, requires lbs_core package to be installed
function detect_version() {
    ubuntu_version=`lsb_release -r -s`
    if [ -z "$ubuntu_version" ]
    then
        echo "Can't detect your Ubuntu version, install 'lbs_core' from \
apt-get or provide your Ubuntu version as the second argument to this script \
(16.04 or 18.04)"
    fi
}


# Check if the Ubuntu version is a supported one
function validate_version() {
    local arg1=$1
    if [[ $arg1 == "" ]]
    then
        echo "Unable to determine the system Ubuntu version, using the default \
one: 18.04"    
    elif [[ $arg1 != "16.04" ]] && [[ $arg1 != "18.04" ]]
    then
        echo "Only Ubuntu 16.06 and 18.04 are supported by this script. Use at \
your own risk!"
    fi
}


# Set the base config
function set_base_config() {
    apt_package_list="software-properties-common wget \
                      build-essential git cmake vim emacs gfortran libblas-dev \
                      python-pip liblapack-dev libhdf5-dev autoconf libtool"
    pip_package_list="numpy scipy cython nose tables matplotlib jinja2 \
                      setuptools"
    hdf5_libdir="/usr/lib/x86_64-linux-gnu/hdf5/serial"
}


# Upate the configuration based on the ubuntu version
function update_config() {
    local arg1=$1
    if [[ ${arg1} == "16.04" ]]
    then
        apt_package_list="python-software-properties ${apt_package_list}"
    fi
}

## Main 
# process the arguments
proccess_args $*
# Check is the Ubuntu version is a supported one
validate_version ${ubuntu_version}

# Set the base config
set_base_config
# Upate the configuration based on the ubuntu version
update_config ${ubuntu_version}

source Ubuntu_mint.sh $pyne_version
