#!/bin/sh

m68k-elf-as -o crt0.o crt0.S

# Important optimization:
#   We don't want to use any stack frames for this test because we will be doing an inspection of the SRAM overall area.
#   With the 68000, we can assign all the scratch buffers to registers by enabling optimization.
m68k-elf-gcc -O -fomit-frame-pointer -mc68000 -c -o strict_sram_check.o strict_sram_check.c

m68k-elf-ld -T strict_sram_check.ld -o strict_sram_check.elf crt0.o strict_sram_check.o
m68k-elf-objcopy -S -O binary strict_sram_check.elf strict_sram_check.bin
m68k-elf-objcopy -S -O srec strict_sram_check.elf strict_sram_check.mot
m68k-elf-objcopy -S -O ihex strict_sram_check.elf strict_sram_check.hex
