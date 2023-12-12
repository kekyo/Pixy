#!/bin/sh
m68k-elf-as -o crt0.o crt0.S
m68k-elf-gcc -O -fomit-frame-pointer -mc68000 -c -o switch_blink.o switch_blink.c
m68k-elf-ld -T switch_blink.ld -o switch_blink.elf crt0.o switch_blink.o
m68k-elf-objcopy -S -O binary switch_blink.elf switch_blink.bin
m68k-elf-objcopy -S -O srec switch_blink.elf switch_blink.mot
m68k-elf-objcopy -S -O ihex switch_blink.elf switch_blink.hex
