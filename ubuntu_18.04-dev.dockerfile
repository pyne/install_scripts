FROM ubuntu:18.04

ENV HOME /root

RUN apt-get -y  update
RUN apt-get install -y  \
    software-properties-common wget

# pyne specific dependencies (excluding python libraries)
RUN apt-get install -y build-essential git cmake vim emacs gfortran libblas-dev \
                       python-pip liblapack-dev libeigen3-dev libhdf5-dev autoconf libtool

# need to put libhdf5.so on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu
ENV LIBRARY_PATH /usr/lib/x86_64-linux-gnu

# upgrade pip and install python dependencies
ENV PATH $HOME/.local/bin:$PATH
RUN python -m pip install --user --upgrade pip
RUN pip install --user numpy scipy cython nose tables matplotlib jinja2 \
                       setuptools future

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
  && cmake ../moab/ \
              -DCMAKE_INSTALL_PREFIX=$HOME/opt/moab \
              -DENABLE_HDF5=ON \
              -DBUILD_SHARED_LIBS=ON \
              -DENABLE_PYMOAB=ON \
              -DENABLE_BLASLAPACK=OFF \
              -DENABLE_FORTRAN=OFF \
  && make \
  && make install \
  && cd .. \
  && rm -rf build moab

# put MOAB on the path
ENV LD_LIBRARY_PATH $HOME/opt/moab/lib:$LD_LIBRARY_PATH
ENV LIBRARY_PATH $HOME/opt/moab/lib:$LIBRARY_PATH
ENV PYTHONPATH=$HOME/opt/moab/lib/python2.7/site-packages/

RUN cd /root \
    && git clone https://github.com/svalinn/DAGMC.git \
    && cd DAGMC \
    && git checkout develop \
    && mkdir bld \
    && cd bld \
    && cmake .. -DMOAB_DIR=$HOME/opt/moab \
              -DBUILD_STATIC_LIBS=OFF \
              -DCMAKE_INSTALL_PREFIX=$HOME/opt/dagmc \
    && make \
    && make install \
    && cd ../.. \
    && rm -rf DAGMC


# Install PyNE
RUN cd $HOME/opt \
    && git clone https://github.com/pyne/pyne.git \
    && cd pyne \
    && python setup.py install --user \
                               --moab $HOME/opt/moab \
                               --dagmc $HOME/opt/dagmc \
                               --clean

RUN echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc \
    && echo "alias build_pyne='python setup.py install --user -- -DMOAB_LIBRARY=\$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=\$HOME/opt/moab/include'" >> ~/.bashrc

ENV LD_LIBRARY_PATH $HOME/.local/lib:$LD_LIBRARY_PATH

RUN cd $HOME/opt/pyne && ./scripts/nuc_data_make

RUN cd $HOME/opt/pyne/tests \
    && ./travis-run-tests.sh python2 \
    && echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $HOME/opt/pyne"
