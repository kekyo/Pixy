#!/bin/sh
m68k-elf-as -o crt0.o crt0.S
m68k-elf-gcc -O -fomit-frame-pointer -mc68000 -c -o timer.o timer.c
m68k-elf-ld -T timer.ld -o timer.elf crt0.o timer.o
m68k-elf-objcopy -S -O binary timer.elf timer.bin
m68k-elf-objcopy -S -O srec timer.elf timer.mot
m68k-elf-objcopy -S -O ihex timer.elf timer.hex
