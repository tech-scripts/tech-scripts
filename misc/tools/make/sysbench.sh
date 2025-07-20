#!/usr/bin/env bash

pkg update -y
pkg install -y git make clang binutils automake autoconf libtool pkg-config

git clone https://github.com/akopytov/sysbench.git
cd sysbench

./autogen.sh
./configure \
    --prefix=$PREFIX \
    --without-mysql \
    --with-pgsql=no \
    AR=$(command -v ar) \
    RANLIB=$(command -v ranlib)

make -j$(nproc)
make install

cd ..
rm -rf sysbench

hash -r
