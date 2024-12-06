DUKTAPE_SOURCES=src/duktape.c

CC=m68k-elf-gcc
CCOPTS=-mc68000 -std=gnu99 -O2 -Wall -Wextra -fstrict-aliasing -fomit-frame-pointer -I./src
CCLIBS=-lm -T pixy-68000-0.ld

duktape: $(DUKTAPE_SOURCES) examples/hello/hello.c
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $(CCOPTS) $(DUKTAPE_SOURCES) examples/hello/hello.c $(CCLIBS)
	m68k-elf-objcopy -S -O binary duktape duktape.bin
	m68k-elf-objcopy -S -O srec duktape duktape.mot
	m68k-elf-objcopy -S -O ihex duktape duktape.hex
