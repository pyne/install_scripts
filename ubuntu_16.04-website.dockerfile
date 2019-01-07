FROM pyne/pyne_ubuntu_16.04:latest

RUN apt-get install -y python-pip

RUN pip install sphinx cloud_sptheme prettytable sphinxcontrib_bibtex numpydoc nbconvert 
RUN apt-get update
RUN apt-get install -y doxygen

