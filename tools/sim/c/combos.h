/* The studies (combos.c, swings.c, study.c). */
#ifndef COMBOS_H
#define COMBOS_H
#include "run.h"

/* a part of a combo: an item row (in its slot) or a charm row; the other is -1 */
typedef struct {
    int item, charm;
} Part;

int combos_main(int argc, char **argv);
int combo_parts(Part *out);
const char *part_name(const Part *p);
RunResult *run_batch(int player, int runs, uint64_t seed, int jobs, int want_log, double *secs);

#endif
