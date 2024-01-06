#include "internal.h"

__attribute__((noreturn))
void _exit(int v) {
    println("Exited.");
    while (1);
}
