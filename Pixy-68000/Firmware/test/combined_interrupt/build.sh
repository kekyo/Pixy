#!/bin/sh
m68k-elf-as -o crt0.o crt0.S
m68k-elf-gcc -O -fomit-frame-pointer -mc68000 -c -o combined_interrupt.o combined_interrupt.c
m68k-elf-ld -T combined_interrupt.ld -o combined_interrupt.elf crt0.o combined_interrupt.o
m68k-elf-objcopy -S -O binary combined_interrupt.elf combined_interrupt.bin
m68k-elf-objcopy -S -O srec combined_interrupt.elf combined_interrupt.mot
m68k-elf-objcopy -S -O ihex combined_interrupt.elf combined_interrupt.hex
