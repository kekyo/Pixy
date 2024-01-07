#include "internal.h"

void *sbrk(ptrdiff_t incr) {
    extern const uint8_t _end;		/* Defined by the linker */
    static const uint8_t* heap_end;
    const uint8_t* prev_heap_end;
    register const uint8_t* __sp asm ("sp");

    if (heap_end == 0) {
        heap_end = &_end;
    }

    prev_heap_end = heap_end;
    if (heap_end + incr > __sp) {
        errno = ENOMEM;
        return (void*)-1;
    }

    heap_end += incr;
    return (void*)prev_heap_end;
}
