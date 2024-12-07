DUKTAPE_SOURCES=src/duktape.c
DUK_SOURCES=duk.c examples/cmdline/duk_cmdline_lowmem.c extras/alloc-pool/duk_alloc_pool.c

CC=m68k-elf-gcc
CCOPTS=-mc68000 -std=gnu99 -O2 -Wall -Wextra -fstrict-aliasing -fomit-frame-pointer -I./src -I./examples/cmdline -I./extras/alloc-pool -DDUK_CMDLINE_LOWMEM -DDUK_USE_HEAPPTR16
CCLIBS=-lm -T pixy-68000-0.ld

duk: $(DUKTAPE_SOURCES) $(DUK_SOURCES)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) -o $@ $(CCOPTS) $(DUKTAPE_SOURCES) $(DUK_SOURCES) $(CCLIBS)
	m68k-elf-objcopy -S -O binary $@ $@.bin
	m68k-elf-objcopy -S -O srec $@ $@.mot
	m68k-elf-objcopy -S -O ihex $@ $@.hex
