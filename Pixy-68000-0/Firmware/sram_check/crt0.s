    .align 4
    .text
    .global _start
_start:
    movel 0,%fp
    jsr main
    bras _start
