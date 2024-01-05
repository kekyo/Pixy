#!/bin/sh

PREFIX=~/.m68k-elf-gcc/
PARALLEL=-j8

# https://gcc.gnu.org/install/prerequisites.html

BINUTILS_VERSION=2.41
GCC_VERSION=13.2.0
GMP_VERSION=6.3.0
MPFR_VERSION=4.2.1
MPC_VERSION=1.3.1
NEWLIB_VERSION=4.3.0.20230120

CFLAGS_FOR_TARGET="-mc68000 -O2 -fomit-frame-pointer"

echo ""
echo "============================================================"
echo "Install the requirements"
echo ""

sudo apt-get update -y
sudo apt-get install -y wget build-essential texinfo

echo ""
echo "============================================================"
echo "Fetch gcc and related source tar-balls"
echo ""

if [ ! -d artifacts ] ; then
    mkdir artifacts
    cd artifacts
    wget https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz
    wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz
    wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.xz
    wget https://www.mpfr.org/mpfr-${MPFR_VERSION}/mpfr-${MPFR_VERSION}.tar.xz
    wget https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz
    wget ftp://sourceware.org/pub/newlib/newlib-${NEWLIB_VERSION}.tar.gz
    chmod 444 *
    cd ..
fi

#------------------------------------------------------

export PATH=${PREFIX}/bin:${PATH}

rm -rf stage
mkdir stage
cd stage

STAGE_DIR=`pwd`

echo ""
echo "============================================================"
echo "Extracts tar-balls"
echo ""

echo "binutils..."
tar -xf ../artifacts/binutils-${BINUTILS_VERSION}.tar.xz
echo "gcc..."
tar -xf ../artifacts/gcc-${GCC_VERSION}.tar.xz
cd gcc-${GCC_VERSION}
echo "gmp..."
tar -xf ../../artifacts/gmp-${GMP_VERSION}.tar.xz
mv gmp-${GMP_VERSION} gmp
echo "mpfr..."
tar -xf ../../artifacts/mpfr-${MPFR_VERSION}.tar.xz
mv mpfr-${MPFR_VERSION} mpfr
echo "mpc..."
tar -xf ../../artifacts/mpc-${MPC_VERSION}.tar.gz
mv mpc-${MPC_VERSION} mpc
cd ..
echo "newlib..."
tar -xf ../artifacts/newlib-${NEWLIB_VERSION}.tar.gz

#------------------------------------------------------

echo ""
echo "============================================================"
echo "Build binutils"
echo ""

mkdir binutils
cd binutils
../binutils-${BINUTILS_VERSION}/configure \
    --prefix=${PREFIX} \
    --target=m68k-elf \
    --enable-lto \
    --disable-shared \
    --disable-multilib \
    --with-newlib \
    --with-headers=${STAGE_DIR}/newlib-${NEWLIB_VERSION}/newlib/libc/include/ \
    --with-sysroot=${PREFIX}
make ${PARALLEL}
make install
cd ..

echo ""
echo "============================================================"
echo "Build gcc [1]"
echo ""

mkdir gcc_1
cd gcc_1
../gcc-${GCC_VERSION}/configure \
    --prefix=${PREFIX} \
    --target=m68k-elf \
    --enable-languages=c \
    --enable-obsolete \
    --disable-libssp \
    --disable-shared \
    --disable-multilib \
    --disable-libstdcxx \
    --disable-bootstrap \
    --with-newlib \
    --with-headers=${STAGE_DIR}/newlib-${NEWLIB_VERSION}/newlib/libc/include/ \
    --with-sysroot=${PREFIX}
make ${PARALLEL}
make install
cd ..

echo ""
echo "============================================================"
echo "Build newlib"
echo ""

export CFLAGS_FOR_TARGET;

mkdir newlib
cd newlib
../newlib-${NEWLIB_VERSION}/configure \
    --prefix=${PREFIX} \
    --target=m68k-elf \
    --enable-newlib-nano-formatted-io \
    --enable-newlib-nano-malloc \
    --enable-lite-exit \
    --disable-libssp \
    --disable-nls \
    --disable-multilib \
    --with-sysroot=${PREFIX}
make ${PARALLEL}
make install
cd ..

echo ""
echo "============================================================"
echo "Build gcc [2]"
echo ""

mkdir gcc_2
cd gcc_2
../gcc-${GCC_VERSION}/configure \
    --prefix=${PREFIX} \
    --target=m68k-elf \
    --enable-languages=c,c++,lto \
    --enable-lto \
    --enable-obsolete \
    --disable-libssp \
    --disable-shared \
    --disable-multilib \
    --disable-bootstrap \
    --with-newlib \
    --with-headers=${STAGE_DIR}/newlib-${NEWLIB_VERSION}/newlib/libc/include/ \
    --with-sysroot=${PREFIX}
make ${PARALLEL}
make install
cd ..

cd ..

#------------------------------------------------------

echo ""
echo "============================================================"
echo "Finalize"
echo ""

cp ${PREFIX}/lib/gcc/m68k-elf/*/*.a ${PREFIX}/m68k-elf/lib/

m68k-elf-gcc ${CFLAGS_FOR_TARGET} -c -o pixy-68000-0.o pixy-68000-0.c
m68k-elf-ar r libpixy.a pixy-68000-0.o
cp pixy-68000-0.ld libpixy.a ${PREFIX}/m68k-elf/lib/
