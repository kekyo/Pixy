#include "internal.h"

extern uint8_t __inbyte();
extern bool __havebyte();

static bool stdinEchoBack = false;

void setEcho(bool echoBack) {
    stdinEchoBack = echoBack;
}

ssize_t read(int __fd, void *__buf, size_t __nbyte) {
    if (__nbyte == 0) {
        return 0;
    }
    while (!__havebyte());
    uint8_t* p = __buf;
    size_t size = 0;
    do {
        const uint8_t v = __inbyte();
        if (stdinEchoBack) {
            outbyte(v);
        }
        *p++ = v;
        size++;
    } while ((size < __nbyte) && __havebyte());
    return size;
}
