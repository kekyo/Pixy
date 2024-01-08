#include "internal.h"

//int execve(const char *__path, char * const __argv[], char * const __envp[]) {
//    errno = ENOMEM;
//    return -1;
//}

//int fork(void) {
//    errno = EAGAIN;
//    return -1;
//}

//int link(const char *__path1, const char *__path2) {
//    errno = EMLINK;
//    return -1;
//}

//int stat(const char *__restrict __path, struct stat *__restrict __sbuf) {
//    __sbuf->st_mode = S_IFCHR;
//    return 0;
//}

//int wait(int *status) {
//    errno = ECHILD;
//    return -1;
//}
