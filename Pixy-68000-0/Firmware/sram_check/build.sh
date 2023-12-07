#!/bin/sh
m68k-unknown-elf-as -mc68000 -o crt0.o crt0.s
m68k-unknown-elf-gcc -O -mc68000 -nostdlib -c -o sram_check.o sram_check.c
m68k-unknown-elf-ld -T sram_check.ld -o sram_check.elf crt0.o sram_check.o
m68k-unknown-elf-objcopy -S -O binary sram_check.elf sram_check.bin
m68k-unknown-elf-objcopy -S -O srec sram_check.elf sram_check.mot
m68k-unknown-elf-objcopy -S -O ihex sram_check.elf sram_check.hex
