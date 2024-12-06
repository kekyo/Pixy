#include "internal.h"

#define TABSIZE 4

extern uint8_t __inbyte();
extern bool __havebyte();

// TODO: Will improve into ioctl(TCGETS/TCSETS)
static bool stdinEchoBack = true;
static bool stdinCookedMode = true;

void setStdInEchoBack(bool echoBack) {
    stdinEchoBack = echoBack;
}

void setStdInCookedMode(bool cookedMode) {
    stdinCookedMode = cookedMode;
}

ssize_t read(int __fd, void *__buf, size_t __nbyte) {
    if (__fd != 0) {
        errno = EBADF;
        return 0;
    }
    if (__nbyte == 0) {
        return 0;
    }
    __nbyte--;

    uint8_t* p = __buf;
    size_t size = 0;
    if (stdinCookedMode) {
        short displayColumn = 0;
        while (size < __nbyte) {
            const uint8_t v = inbyte();
            if (v == 0x08 || v == 0x7f) { // BS, DEL
                if (size >= 1) {
                    p--;
                    size--;
                    if (stdinEchoBack) {
                        const uint8_t tabStop = (*p == 0x09 ? TABSIZE : 1);  // TAB
                        const uint8_t shift = (displayColumn - 1) % tabStop + 1;
                        for (uint8_t i = 0; i < shift; i++) {
                            outbyte(0x08);
                            outbyte(' ');
                            outbyte(0x08);
                            displayColumn--;
                        }
                    }
                }
            } else if (v == 0x0d || v == 0x0a) { // CR, LF
                *p++ = 0x0a;   // LF
                size++;
                if (stdinEchoBack) {
                    displayColumn = 0;
                    outbyte(0x0d);
                    outbyte(0x0a);
                }
                break;  // Finished
            } else if (v == 0x09) { // TAB
                *p++ = v;
                size++;
                if (stdinEchoBack) {
                    const uint8_t curr = displayColumn % TABSIZE;
                    for (uint8_t i = curr; i < TABSIZE; i++) {
                        outbyte(' ');
                        displayColumn++;
                    }
                }
            } else if (v == 0x04) { // EOT (^D)
                break;  // Finished
            } else if (v < 0x20) {
                if (stdinEchoBack) {
                    outbyte(0x07);  // BEL
                }
            } else {
                *p++ = v;
                size++;
                if (stdinEchoBack) {
                    outbyte(v);
                    displayColumn++;
                }
            }
        }
        *p = 0x00;
        return size;
    } else {
        if (size < __nbyte) {
            while (!__havebyte());
            while (size < __nbyte) {
                const uint8_t v = __inbyte();
                if (stdinEchoBack) {
                    outbyte(v);
                }
                *p++ = v;
                size++;
                if (!__havebyte()) {
                    break;
                }
            }
        }
        *p = 0x00;
        return size;
    }
}
