m68k-unknown-elf-as -mc68000 -o test.o test.s
m68k-unknown-elf-ld -T test.ld -o test.elf test.o
m68k-unknown-elf-objcopy -S -O binary test.elf test.bin
m68k-unknown-elf-objcopy -S -O srec test.elf test.srec
m68k-unknown-elf-objcopy -S -O ihex test.elf test.hex
