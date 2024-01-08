#include "internal.h"

int gettimeofday(struct timeval *tv, void *tz) {
    errno = EINVAL;
    return -1;
}
