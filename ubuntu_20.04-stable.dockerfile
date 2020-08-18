FROM ubuntu:20.04

ENV HOME /root

RUN apt-get -y  update
RUN apt-get install -y  \
    software-properties-common wget

# pyne specific dependencies (excluding python libraries)
RUN apt-get install -y build-essential git cmake gfortran libblas-dev \
                       python3-pip liblapack-dev libeigen3-dev libhdf5-dev \
                       libpython3-dev python3-dev libhdf5-serial-dev hdf5-tools

# need to put libhdf5.so on LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu
ENV LIBRARY_PATH /usr/lib/x86_64-linux-gnu

# switch to python 3
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10; \
    update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 10;

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
  && git clone --branch Version5.1.0 --single-branch https://bitbucket.org/fathomteam/moab moab \
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
ENV PYTHONPATH=$HOME/opt/moab/lib/python3.8/site-packages/

RUN cd /root \
    && git clone --branch develop --single-branch https://github.com/svalinn/DAGMC.git DAGMC \
    && mkdir build \
    && cd build \
    && cmake ../DAGMC \
            -DMOAB_DIR=$HOME/opt/moab \
            -DBUILD_STATIC_LIBS=OFF \
            -DCMAKE_INSTALL_PREFIX=$HOME/opt/dagmc \
    && make \
    && make install \
    && cd .. \
    && rm -rf build DAGMC


# Install PyNE
RUN cd $HOME/opt \
    && git clone https://github.com/pyne/pyne.git \
    && cd pyne \
    && TAG=$(git describe --abbrev=0 --tags) \
    && git checkout origin/0.7.0-rc -b 0.7.0-rc \
    && python setup.py install --user \
                               --moab $HOME/opt/moab \
                               --dagmc $HOME/opt/dagmc \
                               --clean

RUN echo "export PATH=$HOME/.local/bin:\$PATH" >> ~/.bashrc \
    && echo "export LD_LIBRARY_PATH=$HOME/.local/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc \
    && echo "alias build_pyne='python setup.py install --user -- -DMOAB_LIBRARY=\$HOME/opt/moab/lib -DMOAB_INCLUDE_DIR=\$HOME/opt/moab/include'" >> ~/.bashrc

ENV LD_LIBRARY_PATH $HOME/.local/lib:$LD_LIBRARY_PATH

RUN cd $HOME && nuc_data_make

RUN cd $HOME/opt/pyne/tests \
    && ./travis-run-tests.sh \
    && echo "PyNE build complete. PyNE can be rebuilt with the alias 'build_pyne' executed from $HOME/opt/pyne"
