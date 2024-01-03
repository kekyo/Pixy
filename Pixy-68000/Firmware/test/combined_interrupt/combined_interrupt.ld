OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_start)

MEMORY
{
	VEC (rw)    : ORIGIN = 0x000000, LENGTH = 0x00000400
  	RAM (rwx)   : ORIGIN = 0x000400, LENGTH = 1M - 0x000400
	INITVEC (r) : ORIGIN = 0xf00000, LENGTH = 0x00000400
	ROM (xr)    : ORIGIN = 0xf00400, LENGTH = 1M - 0x000400
}

SECTIONS
{
	.vectors : {
	    __init_vec = .;
		LONG(ORIGIN(RAM) + LENGTH(RAM));
		LONG(_start);
		*(.vectors)
	} > INITVEC
	.text : {
		__text_top = .;
		*(.text)
		*(.text*)
		*(.rodata)
		*(.rodata.*)
	} > ROM
	.data : {
		__data_top = .;
		*(.data)
		*(.data*)
	} > RAM AT > ROM
	.vec : {
		__vec = .;
	} > VEC
}
