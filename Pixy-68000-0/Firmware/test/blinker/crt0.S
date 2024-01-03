    .align 4
    .text
    .extern main
    .global _start
_start:
    eor %d0,%d0
    movel %d0,%fp
    jmp main
