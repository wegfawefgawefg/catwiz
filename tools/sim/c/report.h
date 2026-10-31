/* The report of a batch of runs (report.c). */
#ifndef REPORT_H
#define REPORT_H
#include "run.h"

typedef struct {
    double reached, won, hp_in, lost, healed, net, turns;
    int turns_max;
    int lost_p90; /* hit points lost by the worst tenth of the runs that reached it (a death:
                     all she had) */
} FightRowSum;

typedef struct {
    FightRowSum rows[FIGHT_COUNT];
    int deaths[FIGHT_COUNT + 1];
    double win, hp_end;
} Summary;

void summary(const RunResult *r, int n, Summary *s);
void print_report(int player, const RunResult *r, int n, double seconds, int by_fight);

#endif
