#!/bin/sh
m68k-elf-as -o crt0.o crt0.S
m68k-elf-gcc -O -fomit-frame-pointer -mc68000 -c -o uart_bridge.o uart_bridge.c
m68k-elf-ld -T uart_bridge.ld -o uart_bridge.elf crt0.o uart_bridge.o
m68k-elf-objcopy -S -O binary uart_bridge.elf uart_bridge.bin
m68k-elf-objcopy -S -O srec uart_bridge.elf uart_bridge.mot
m68k-elf-objcopy -S -O ihex uart_bridge.elf uart_bridge.hex
