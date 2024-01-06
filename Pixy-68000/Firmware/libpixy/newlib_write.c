#include "internal.h"

ssize_t write(int __fd, const void *__buf, size_t __nbyte) {
    const uint8_t* p = __buf;
    for (size_t todo = 0; todo < __nbyte; todo++) {
        outbyte(*p++);
    }
    return __nbyte;
}
