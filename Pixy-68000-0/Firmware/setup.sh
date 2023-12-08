#!/bin/sh

echo ""
echo "============================================================"
echo "Install the requirements"
echo ""

sudo apt-get install -y wget build-essential texinfo

echo ""
echo "============================================================"
echo "Fetch gcc and related source tar-balls"
echo ""

if ! [ -d artifacts ] ; then
    mkdir artifacts
    cd artifacts
    wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz
    wget https://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.xz
    wget https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
    wget https://www.mpfr.org/mpfr-current/mpfr-4.2.1.tar.xz
    wget https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
    cd ..
fi

#------------------------------------------------------

rm -rf stage
mkdir stage
cd stage

echo ""
echo "============================================================"
echo "Extracts tar-balls"
echo ""

tar -xf ../artifacts/binutils-2.41.tar.xz
tar -xf ../artifacts/gcc-13.2.0.tar.xz
cd gcc-13.2.0
tar -xf ../../artifacts/gmp-6.3.0.tar.xz
mv gmp-6.3.0 gmp
tar -xf ../../artifacts/mpfr-4.2.1.tar.xz
mv mpfr-4.2.1 mpfr
tar -xf ../../artifacts/mpc-1.3.1.tar.gz
mv mpc-1.3.1 mpc
cd ..

#------------------------------------------------------

echo ""
echo "============================================================"
echo "Build binutils"
echo ""

mkdir binutils
cd binutils
../binutils-2.41/configure --target=m68k-unknown-elf
make -j
sudo make install
cd ..

echo ""
echo "============================================================"
echo "Build gcc"
echo ""

mkdir gcc
cd gcc
../gcc-13.2.0/configure --target=m68k-unknown-elf --enable-languages=c --disable-libssp --enable-obsolete --disable-shared --disable-multilib --disable-libstdcxx --without-headers
make -j
sudo make install
cd ..
