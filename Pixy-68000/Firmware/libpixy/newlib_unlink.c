#include "internal.h"

int unlink(const char *__path) {
    errno = ENOENT;
    return -1; 
}
