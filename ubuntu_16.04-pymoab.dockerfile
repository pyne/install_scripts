FROM ubuntu:16.04

ENV HOME /root

RUN apt-get -y --force-yes update
RUN apt-get install -y --force-yes \
    software-properties-common python-software-properties wget

# pyne specific dependencies
RUN apt-get install -y build-essential python-numpy python-scipy cython \
                       python-nose git cmake vim emacs gfortran libblas-dev \
                       liblapack-dev libhdf5-dev gfortran python-tables \
                       python-matplotlib python-jinja2 autoconf libtool \
                       python-setuptools

RUN easy_install pip \
  && pip install cython --user --force-reinstall --upgrade

# need to put libhdf5.so on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu
ENV LIBRARY_PATH /usr/lib/x86_64-linux-gnu

# make starting directory
RUN cd $HOME \
  && mkdir opt

# build MOAB
RUN cd $HOME/opt \
  && mkdir moab \
  && cd moab \
  && git clone https://bitbucket.org/fathomteam/moab \
  && cd moab \
  && git checkout -b Version5.1.0 origin/Version5.1.0 \
  && autoreconf -fi \
  && cd .. \
  && mkdir build \
  && cd build \
  && ../moab/configure --enable-shared --enable-pymoab --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial --prefix=$HOME/opt/moab \
  && make \
  && make install \
  && cd .. \
  && rm -rf build moab

# put MOAB on the path
ENV LD_LIBRARY_PATH $HOME/opt/moab/lib:$LD_LIBRARY_PATH
ENV LIBRARY_PATH $HOME/opt/moab/lib:$LIBRARY_PATH
ENV PYTHONPATH=/root/opt/moab/lib/python2.7/site-packages:$PYTHONPATH
RUN echo "export PYTHONPATH=/root/opt/moab/lib/python2.7/site-packages:$PYTHONPATH" >> ~/.bashrc

# build DAGMC
RUN cd $HOME/opt \
  && mkdir dagmc \
  && cd dagmc \
  && git clone https://github.com/ljacobson64/DAGMC.git \
  && cd DAGMC \
  #&& git remote add lucas https://github.com/ljacobson64/DAGMC.git \
  #&& git fetch lucas \
  && git checkout -b moab_cmake_var origin/moab_cmake_var \
  && cd .. \
  && mkdir bld \
  && cd bld \
  && cmake ../DAGMC/ -DMOAB_ROOT=$HOME/opt/moab/ -DCMAKE_INSTALL_PREFIX=$HOME/opt/dagmc \
  && make \
  && make install

# add DAGMC to path
ENV LD_LIBRARY_PATH $HOME/opt/dagmc/lib:$LD_LIBRARY_PATH
ENV LIBRARY_PATH $HOME/opt/dagmc/lib:$LIBRARY_PATH


# Install PyNE
RUN cd $HOME/opt \
    && git clone https://github.com/CNERG/pyne.git \
    && cd pyne \
    && git checkout -b pymoab_cleanup origin/pymoab_cleanup \
    && python setup.py install --user -- --moab $HOME/opt/moab/ --dagmc $HOME/opt/dagmc

RUN echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc \
    && echo "alias build_pyne='python setup.py install --user -- --moab $HOME/opt/moab/ --dagmc $HOME/opt/dagmc'" >> ~/.bashrc

ENV LD_LIBRARY_PATH $HOME/.local/lib:$LD_LIBRARY_PATH

RUN cd $HOME/opt/pyne/scripts/ && ./nuc_data_make

RUN cd $HOME/opt/pyne/tests \
    && ./travis-run-tests.sh python2 \
    && echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $HOME/opt/pyne"
