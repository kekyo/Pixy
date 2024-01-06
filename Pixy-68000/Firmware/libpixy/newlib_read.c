#include "internal.h"

extern uint8_t __inbyte();
extern bool __havebyte();

ssize_t read(int __fd, void *__buf, size_t __nbyte) {
    uint8_t* p = __buf;
    size_t size = 0;
    while ((size < __nbyte) && __havebyte()) {
        *p++ = __inbyte();
        size++;
    }
    return size;
}
