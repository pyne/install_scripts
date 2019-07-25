FROM ubuntu:18.04

ENV HOME /root

RUN apt-get -y --force-yes update
RUN apt-get install -y --force-yes \
    software-properties-common python-software-properties wget

# pyne specific dependencies (excluding python libraries)
RUN apt-get install -y build-essential git cmake vim emacs gfortran libblas-dev \
                       python-pip liblapack-dev libhdf5-dev autoconf libtool

# need to put libhdf5.so on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu
ENV LIBRARY_PATH /usr/lib/x86_64-linux-gnu

# upgrade pip and install python dependencies
ENV PATH $HOME/.local/bin:$PATH
RUN python -m pip install --user --upgrade pip
RUN pip install --user numpy scipy cython nose tables matplotlib jinja2 \
                       setuptools

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
  && ../moab/configure --enable-shared --enable-dagmc --enable-pymoab --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial --prefix=$HOME/opt/moab \
  && make \
  && make install \
  && cd .. \
  && rm -rf build moab

# put MOAB on the path
ENV LD_LIBRARY_PATH $HOME/opt/moab/lib:$LD_LIBRARY_PATH
ENV LIBRARY_PATH $HOME/opt/moab/lib:$LIBRARY_PATH

# Install PyNE
RUN cd $HOME/opt \
    && git clone https://github.com/pyne/pyne.git \
    && cd pyne \
    && TAG=$(git describe --abbrev=0 --tags) \
    && git checkout tags/`echo $TAG` -b `echo $TAG` \
    && python setup.py install --user -- -DMOAB_LIBRARY=$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=$HOME/opt/moab/include

RUN echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc \
    && echo "alias build_pyne='python setup.py install --user -- -DMOAB_LIBRARY=\$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=\$HOME/opt/moab/include'" >> ~/.bashrc

ENV LD_LIBRARY_PATH $HOME/.local/lib:$LD_LIBRARY_PATH

RUN cd $HOME/opt/pyne && ./scripts/nuc_data_make \
    && cd tests \
    && ./travis-run-tests.sh python2 \
    && echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $HOME/opt/pyne"
