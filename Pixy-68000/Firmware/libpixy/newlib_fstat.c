#include "internal.h"

int fstat(int file, struct stat *st) {
    if (file == 0 || file == 1 || file == 2) {
        st->st_mode = S_IFCHR;
        return 0;
    } else {
        errno = EBADF;
        return -1;
    }
}
