STARTUP(crt0.o)
OUTPUT_FORMAT("elf32-m68k")
OUTPUT_ARCH(m68k)
ENTRY(_start)

SEARCH_DIR("=m68k-elf/lib");
SEARCH_DIR("=lib/gcc/m68k-elf/13.2.0");
GROUP(-lpixy -lc -lgcc)
__DYNAMIC = 0;

MEMORY
{
  vec (rw)    : ORIGIN = 0x000000, LENGTH = 0x00000400
  ram (rwx)   : ORIGIN = 0x000400, LENGTH = 1M - 0x000400
  initvec (r) : ORIGIN = 0xf00000, LENGTH = 0x00000400
  rom (xr)    : ORIGIN = 0xf00400, LENGTH = 1M - 0x000400
}

PROVIDE (__stack = 0x00100000);
PROVIDE (software_init_hook = 0);
PROVIDE (_software_init_hook = 0);

SECTIONS
{
  .vectors :
  {
    __init_vec = .;
    __rom_top = .;
    LONG(ORIGIN(ram) + LENGTH(ram));
    LONG(_start);
    *(.vectors)
  } > initvec

  .text :
  {
    _stext = .;
    CREATE_OBJECT_SYMBOLS
    *(.text .text.*)

    . = ALIGN(0x4);
    /* These are for running static constructors and destructors under ELF.  */
    KEEP (*crtbegin.o(.ctors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .ctors))
    KEEP (*(SORT(.ctors.*)))
    KEEP (*(.ctors))
    KEEP (*crtbegin.o(.dtors))
    KEEP (*(EXCLUDE_FILE (*crtend.o) .dtors))
    KEEP (*(SORT(.dtors.*)))
    KEEP (*(.dtors))

    *(.rodata .rodata.*)

    . = ALIGN(0x4);
    *(.gcc_except_table) 

    . = ALIGN(0x4);
    *(.eh_frame)

    . = ALIGN(0x4);
    __INIT_SECTION__ = . ;
    LONG (0x4e560000)	/* linkw %fp,#0 */
    *(.init)
    SHORT (0x4e5e)	/* unlk %fp */
    SHORT (0x4e75)	/* rts */

    . = ALIGN(0x4);
    __FINI_SECTION__ = . ;
    LONG (0x4e560000)	/* linkw %fp,#0 */
    *(.fini)
    SHORT (0x4e5e)	/* unlk %fp */
    SHORT (0x4e75)	/* rts */

    _etext = .;
    *(.lit)
  } > rom

  .data :
  {
    _sdata = .;
    __rom_data_top = LOADADDR(.data);
    *(.got.plt) *(.got)
    *(.shdata)
    *(.data .data.*)
    _edata = .;
  } > ram AT > rom

  .bss :
  {
    . = ALIGN(0x4);
    __bss_start = . ;
    *(.shbss)
    *(.bss .bss.*)
    *(COMMON)
    _end =  ALIGN (0x8);
    __end = _end;
  } > ram

  .stab 0 (NOLOAD) :
  {
    *(.stab)
  }

  .stabstr 0 (NOLOAD) :
  {
    *(.stabstr)
  }

  .vec : {
    __vec = .;
  } > vec
}
