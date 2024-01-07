#include "internal.h"

extern uint8_t __inbyte();
extern bool __havebyte();

ssize_t read(int __fd, void *__buf, size_t __nbyte) {
    if (__nbyte == 0) {
        return 0;
    }
    while (!__havebyte());
    uint8_t* p = __buf;
    size_t size = 0;
    do {
        *p++ = __inbyte();
        size++;
    } while ((size < __nbyte) && __havebyte());
    return size;
}
