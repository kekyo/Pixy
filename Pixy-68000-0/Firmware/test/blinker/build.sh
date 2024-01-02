#!/bin/sh
m68k-elf-as -o crt0.o crt0.S
m68k-elf-gcc -O -fomit-frame-pointer -mc68000 -c -o blinker.o blinker.c
m68k-elf-ld -T blinker.ld -o blinker.elf crt0.o blinker.o
m68k-elf-objcopy -S -O binary blinker.elf blinker.bin
m68k-elf-objcopy -S -O srec blinker.elf blinker.mot
m68k-elf-objcopy -S -O ihex blinker.elf blinker.hex
