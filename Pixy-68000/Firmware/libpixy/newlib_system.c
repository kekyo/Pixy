#include "internal.h"

int _system(const char *command) {
    errno = EINVAL;
    return -1;
}
