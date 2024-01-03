#!/bin/sh
m68k-elf-gcc -O -mc68000 -c -o c_runtime_check.o c_runtime_check.c
m68k-elf-ld -T pixy-68000-0.ld -o c_runtime_check.elf c_runtime_check.o
m68k-elf-objcopy -S -O binary c_runtime_check.elf c_runtime_check.bin
m68k-elf-objcopy -S -O srec c_runtime_check.elf c_runtime_check.mot
m68k-elf-objcopy -S -O ihex c_runtime_check.elf c_runtime_check.hex
