#include "internal.h"

int _rename(const char *oldpath , const char *newpath) {
    errno = ENOTDIR;
    return -1;
}
