FROM ubuntu:17.04

ENV HOME /root

RUN apt-get -y --force-yes update && \
  apt-get install -y --force-yes \
    software-properties-common python-software-properties wget \
    build-essential python3-numpy python3-scipy cython \
    python3-nose git cmake vim emacs gfortran libblas-dev \
    liblapack-dev libhdf5-dev gfortran python3-tables \
    python3-matplotlib python3-jinja2 autoconf libtool && \
  apt-get clean -y

# need to put libhdf5.so on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu
ENV LIBRARY_PATH /usr/lib/x86_64-linux-gnu

# make starting directory
RUN mkdir -p $HOME/opt
RUN echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc \
    && echo "alias build_pyne='python setup.py install --user -j 3 -DMOAB_LIBRARY=\$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=\$HOME/opt/moab/include'" >> ~/.bashrc \
    && echo "alias python=python3" >> ~/.bashrc \
    && echo "alias nosetests=nosetests3" >> ~/.bashrc

# build MOAB
RUN cd $HOME/opt \
  && mkdir moab \
  && cd moab \
  && git clone https://bitbucket.org/fathomteam/moab \
  && cd moab \
  && git checkout -b Version4.9.1 origin/Version4.9.1 \
  && autoreconf -fi \
  && cd .. \
  && mkdir build \
  && cd build \
  && ../moab/configure --enable-shared --enable-dagmc --with-hdf5=/usr/lib/x86_64-linux-gnu/hdf5/serial --prefix=$HOME/opt/moab \
  && make -j 3 \
  && make install \
  && cd .. \
  && rm -rf build moab

# put MOAB on the path
ENV LD_LIBRARY_PATH $HOME/opt/moab/lib:$LD_LIBRARY_PATH
ENV LIBRARY_PATH $HOME/opt/moab/lib:$LIBRARY_PATH

# build PyTAPS
RUN cd $HOME/opt \
  && wget https://pypi.python.org/packages/source/P/PyTAPS/PyTAPS-1.4.tar.gz \
  && tar zxvf PyTAPS-1.4.tar.gz \
  && rm PyTAPS-1.4.tar.gz \
  && cd PyTAPS-1.4/ \
  && python setup.py --iMesh-path=$HOME/opt/moab --without-iRel --without-iGeom install --user \
  && cd .. \
  && rm -rf PyTAPS-1.4

# Install PyNE
RUN cd $HOME/opt \
    && git clone https://github.com/pyne/pyne.git \
    && cd pyne \
    && python setup.py install --user -DMOAB_LIBRARY=$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=$HOME/opt/moab/include -j 3

ENV LD_LIBRARY_PATH $HOME/.local/lib:$LD_LIBRARY_PATH

RUN cd $HOME/opt/pyne && ./scripts/nuc_data_make \
    && cd tests \
    && . ./travis-run-tests.sh \
    && echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $HOME/opt/pyne"
