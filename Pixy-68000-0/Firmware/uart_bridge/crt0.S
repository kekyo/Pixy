    .align 4
    .text
    .extern main
    .global _start
_start:
    movel #__init_vec,%a0    /* src */
    movel #__vec,%a1         /* dest */
    movel #__text_top,%d0
    subl #__init_vec,%d0
    lsrl #2,%d0             /* Each 32bit/4byte */
.loop:
	movel (%a0)+,(%a1)+
	movel (%a0)+,(%a1)+
	movel (%a0)+,(%a1)+
	movel (%a0)+,(%a1)+
	movel (%a0)+,(%a1)+
	movel (%a0)+,(%a1)+
	movel (%a0)+,(%a1)+
	movel (%a0)+,(%a1)+
	subqw #1,%d0
	jcc	.loop

    movel %ssp,%fp

    move #0x2000,%sr        /* Enable interrupts */
    jmp main

_cli:
    move #0x2700,%sr        /* Disable interrupts */
    rts
_sti:
    move #0x2000,%sr        /* Enable interrupts */
    rts
