    .align 4
    .text
    .extern main
    .global _start
_start:
    eor %d0,%d0
    movel %d0,%fp
    jmp main
/*
    .global irq_handler_timer_reached
irq_handler_timer_reached:
    movel %d0,%sp@-
    movew 0x0010000a,%d0
    movel %sp@+,%d0
    rte
*/