PyNE Install Scripts
====================

This repo contains scripts for installing PyNE on various Debian-derived
systems.

Bash Scripts (*.sh)
-------------------

These scripts will install PyNE and its dependencies on the system.
Install scripts are available for different versions of both Ubuntu and
Mint operating systems. The script used to install PyNE should correspond
to the user's operating system and version. The intention of these
scripts is that PyNE can be ready to use on a clean install of any of
the supported operating systems. Furthermore, the user should choose either
to build a stable version of PyNE or the current develop
branch of PyNE by supplying a second argument. 

Example for installing the most recent stable branch on Ubuntu 16.04:

    ./ubuntu_16.04.sh stable
    
Example for installing the develop branch on Mint 18.01:
	
	./ubuntu_16.04.sh dev

Docker Builds (*.dockerfile)
----------------------------

These dockerfiles can be used to build a docker image that has PyNE
installed. The dockerfile chosen will build on the version of Ubuntu
listed (16.04 or 17.04). Furthermore, the user may choose either
to build a stable version of PyNE ("-stable") or the current develop
branch of PyNE ("-dev") for each. Example for building a docker image
of the latest stable branch of PyNE based on Ubuntu 16.04:

    docker build -f ubuntu_16.04-stable.dockerfile -t pyne-16.04-stable .
