#!/usr/bin/env bash

pkg update -y && pkg upgrade -y
pkg install -y git make clang binutils automake autoconf libtool pkg-config which

git clone https://github.com/akopytov/sysbench.git
cd sysbench

./autogen.sh
export AR=$(command -v ar)
export RANLIB=$(command -v ranlib)
./configure --prefix=$PREFIX --without-mysql --with-pgsql=no

make && make install

cd ..
rm -rf sysbench

hash -r
