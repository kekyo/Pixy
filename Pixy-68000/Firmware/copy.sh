#!/bin/sh

PREFIX=~/.m68k-elf-gcc/

CFLAGS_FOR_TARGET="-mc68000 -O2 -fomit-frame-pointer"

#------------------------------------------------------

echo ""
echo "============================================================"
echo "Copy"
echo ""

m68k-elf-gcc ${CFLAGS_FOR_TARGET} -c -o pixy-68000-0.o pixy-68000-0.c
m68k-elf-ar r libpixy.a pixy-68000-0.o
cp pixy-68000-0.ld libpixy.a ${PREFIX}/m68k-elf/lib/
