#!/bin/bash

function check_repo() {

    repo_name=$1

    if [ -d ${repo_name} ] ; then
        read -p "Delete the existing ${repo_name} directory and all contents? (y/n) " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]] ; then
            rm -rf ${repo_name}
        fi
    fi

}

function add_export_var_to_bashrc(){
# $1 is the ENVIRONEMENT variable to add, $2 the PATH to append

echo "if [ -z $1 ]" >> ~/.bashrc
echo "then" >> ~/.bashrc
echo "  export $1=$2" >> ~/.bashrc
echo "else" >> ~/.bashrc
echo "  export $1=$2:\$${1}" >> ~/.bashrc
echo "fi" >> ~/.bashrc

}