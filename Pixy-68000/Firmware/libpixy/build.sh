#!/bin/sh

PREFIX=~/.m68k-elf-gcc/

CFLAGS_FOR_TARGET="-mc68000 -O2 -fomit-frame-pointer -fno-exceptions"

#------------------------------------------------------

echo ""
echo "============================================================"
echo "Build libpixy.a"
echo ""

rm -f libpixy.a *.o

for src in *.c
do
    m68k-elf-gcc ${CFLAGS_FOR_TARGET} -c -o ${src}.o ${src}
done

m68k-elf-ar r libpixy.a *.o

echo ""
echo "============================================================"
echo "Install libpixy.a"
echo ""

cp pixy-68000.h ${PREFIX}/m68k-elf/include
cp pixy-68000-0.ld libpixy.a ${PREFIX}/m68k-elf/lib/
