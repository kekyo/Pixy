#!/bin/sh
m68k-elf-g++ -T pixy-68000-0.ld -O -mc68000 -fno-exceptions -o cpp_runtime_check.elf cpp_runtime_check.cpp
m68k-elf-objcopy -S -O binary cpp_runtime_check.elf cpp_runtime_check.bin
m68k-elf-objcopy -S -O srec cpp_runtime_check.elf cpp_runtime_check.mot
m68k-elf-objcopy -S -O ihex cpp_runtime_check.elf cpp_runtime_check.hex
