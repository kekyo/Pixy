#!/bin/sh
m68k-elf-as -o crt0.o crt0.S
m68k-elf-gcc -O -fomit-frame-pointer -mc68000 -c -o sram_check.o sram_check.c
m68k-elf-ld -T sram_check.ld -o sram_check.elf crt0.o sram_check.o
m68k-elf-objcopy -S -O binary sram_check.elf sram_check.bin
m68k-elf-objcopy -S -O srec sram_check.elf sram_check.mot
m68k-elf-objcopy -S -O ihex sram_check.elf sram_check.hex
