/* The combos study (combos.c). */
#ifndef COMBOS_H
#define COMBOS_H
#include "run.h"

int combos_main(int argc, char **argv);
RunResult *run_batch(int player, int runs, uint64_t seed, int jobs, int want_log, double *secs);

#endif
