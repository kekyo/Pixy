OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_start)

MEMORY
{
	ROM (xr): ORIGIN = 0xf00000, LENGTH = 1M
	RAM (xw): ORIGIN = 0x000000, LENGTH = 1M
}

SECTIONS
{
	.text : {
		. = ALIGN(4);
		LONG(ORIGIN(RAM) + LENGTH(RAM));
		LONG(_start);
		*(.text)
		*(.text*)
		*(.rodata)
		*(.rodata.*)
	} > ROM
	.data : {
		. = ALIGN(4);
		LONG(0);
		LONG(0);
		*(.data)
		*(.data*)
	} > RAM AT > ROM
}
