#include "internal.h"

#define TABSIZE 4

// TODO: Will improve into ioctl(TCGETS/TCSETS)
static bool stdoutCookedMode = true;

void setStdOutCookedMode(bool cookedMode) {
    stdoutCookedMode = cookedMode;
}

ssize_t write(int __fd, const void *__buf, size_t __nbyte) {
    if (__fd != 1 && __fd != 2) {
        errno = EBADF;
        return 0;
    }
    const uint8_t* p = __buf;
    if (stdoutCookedMode) {
        const uint8_t* pv = p;
        short displayColumn = 0;
        for (size_t todo = 0; todo < __nbyte; todo++) {
            const uint8_t v = *p++;
            if (v == 0x08 || v == 0x7f) {  // BS, DEL
                if (displayColumn >= 1) {
                    const uint8_t tabStop = (*p == 0x09 ? TABSIZE : 1);  // TAB
                    const uint8_t shift = (displayColumn - 1) % tabStop + 1;
                    for (uint8_t i = 0; i < shift; i++) {
                        outbyte(0x08);
                        outbyte(' ');
                        outbyte(0x08);
                        displayColumn--;
                    }
                    pv--;
                }
            } else if (v == 0x0a) {  // LF
                outbyte(0x0d);   // CR/LF
                outbyte(0x0a);
                displayColumn = 0;
            } else if (v == 0x0d || v == 0x0c) {  // CR, FF
                outbyte(v);
                displayColumn = 0;
            } else if (v == 0x09) {  // TAB
                const uint8_t curr = displayColumn % TABSIZE;
                for (uint8_t i = curr; i < TABSIZE; i++) {
                    outbyte(' ');
                    displayColumn++;
                }
            } else if (v == 0x07) {  // BEL (^G)
                outbyte(0x07);  // BEL
            } else if (v < 0x20) {
                outbyte(0xe2);  // UTF8 Control Pictures (U+2400 + v)
                outbyte(0x90);
                outbyte(0x80 + v);
                displayColumn++;
            } else {
                outbyte(v);
                displayColumn++;
            }
        }
    } else {
        for (size_t todo = 0; todo < __nbyte; todo++) {
            outbyte(*p++);
        }
    }
    return __nbyte;
}
