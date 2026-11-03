/* The studies (filled in below). */
#include <stdio.h>
#include <stdlib.h>

#include "study.h"

void free_runs(RunResult *r, int n) {
    for (int i = 0; i < n; i++)
        free(r[i].log);
    free(r);
}

int study_main(int argc, char **argv) {
    (void)argc;
    (void)argv;
    return 0;
}
