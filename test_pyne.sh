#!/bin/bash

set -e
source utils.sh


# Make Pyne Nuclear Data
source ~/.bashrc
cd
nuc_data_make

# Run tests
cd ${install_dir}/pyne/tests
./travis-run-tests.sh