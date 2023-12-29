    .align 4
    .text
    .extern main

    .global _start
_start:
    eorl %d0,%d0
    eorl %d1,%d1
    eorl %d2,%d2
    eorl %d3,%d3
    movel %d0,%a0
    movel %d0,%a1
    movel %d0,%a2
    movel %d0,%a3
    movel %d0,%a5
    movel #0x00100000,%d4
    movel #32,%d5
.clrloop:
    moveml %d0-%d3/%a0-%a3,(%a5)
    addl %d5,%a5
    subl %d5,%d4            /* Each 4byte * 8 = 32byte */
	bnes .clrloop

    movel #__init_vec,%a4   /* src */
    movel #__vec,%a5        /* dest */
    movew #0x0400,%d4
.vecloop:
    movel (%a4)+,(%a5)+
    movel (%a4)+,(%a5)+
    movel (%a4)+,(%a5)+
    movel (%a4)+,(%a5)+
    movel (%a4)+,(%a5)+
    movel (%a4)+,(%a5)+
    movel (%a4)+,(%a5)+
    movel (%a4)+,(%a5)+
	subw %d5,%d4            /* Each 4byte * 8 = 32byte */
	bnes .vecloop

    movel %ssp,%fp

    andiw #0xa000,%sr        /* Enable interrupts */
    jmp main

    .global __cli
__cli:
    oriw #0x0700,%sr         /* Disable interrupts */
    rts
    
    .global __sti
__sti:
    andiw #0xa0ff,%sr        /* Enable interrupts */
    rts
