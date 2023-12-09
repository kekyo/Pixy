    .align 4
    .text

    .global hardware_init_hook
hardware_init_hook:
    /* TODO: */
    rts

    .global _exit
_exit:
    stop #0x2700
    bras _exit

    .global sbrk
sbrk:
    rts

    .global read
read:
    rts

    .global write
write:
    rts

    .global lseek
lseek:
    rts

    .global close
close:
    rts
