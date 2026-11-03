/* The studies (study.c: picks, cards, blank, luck, kits, domains, players; broken.c: broken,
   lift). */
#ifndef STUDY_H
#define STUDY_H
#include "run.h"

extern int JOBS;
RunResult *run_batch(int player, int runs, uint64_t seed, int jobs, int want_log, double *secs);
int player_by_name(const char *s);
int study_main(int argc, char **argv);
int study_broken(int player, int runs, uint64_t seed);
int study_lift(int player, int runs, uint64_t seed, const char *only);
void free_runs(RunResult *r, int n);

#endif
