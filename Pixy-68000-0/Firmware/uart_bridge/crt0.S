    .align 4
    .text
    .extern main

    .global _start
_start:
    movew	#0x2600,%sr
    movel #0x00000400,%a5
    /* eorl %d0,%d0 */
    /* movel #0x00100000,%d4 */
    movel #0x00000100,%d4
    movel #32,%d5
.clrloop:
    movel %d0,(%a5)+
    movel %d0,(%a5)+
    movel %d0,(%a5)+
    movel %d0,(%a5)+
    movel %d0,(%a5)+
    movel %d0,(%a5)+
    movel %d0,(%a5)+
    movel %d0,(%a5)+
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

    movel %d0,%fp

/*    andiw #0xf8ff,%sr        /* Enable interrupts */
    jmp main

    .global irq_handler_timer_reached
irq_handler_timer_reached:
    movel %d0,%sp@-
    movew 0x0010000a,%d0
    movel %sp@+,%d0
    rte
