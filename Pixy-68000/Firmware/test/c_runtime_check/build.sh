#!/bin/sh
m68k-elf-gcc -T pixy-68000-0.ld -O -mc68000 -o c_runtime_check.elf c_runtime_check.c
m68k-elf-objcopy -S -O binary c_runtime_check.elf c_runtime_check.bin
m68k-elf-objcopy -S -O srec c_runtime_check.elf c_runtime_check.mot
m68k-elf-objcopy -S -O ihex c_runtime_check.elf c_runtime_check.hex
