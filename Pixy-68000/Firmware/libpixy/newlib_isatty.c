#include "internal.h"

int isatty(int file) {
    return (file == 0 || file == 1 || file == 2);
}
