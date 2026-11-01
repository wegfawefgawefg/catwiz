/* The owner's targets as an assertion (main.c --check-targets): the reference players and the
   skill ladder (the searching player with blunders, players.c), each target PASS or FAIL with
   its numbers; the exit is 1 on any FAIL.

   The ladder: at each play a blunder is a random legal play instead of the player's own, at
   each pick between fights a random option, each at its own chance (LEVELS). The targets:
   random 0%; greedy a few % at most; the expert 60-75%; the ladder falls level by level, a
   blunder a turn well under half the expert; for the expert the king kills the most runs,
   and every elite kills some of the runs that reach it. */
#include <stdio.h>
#include <stdlib.h>

#include "report.h"

RunResult *run_batch(int player, int runs, uint64_t seed, int jobs, int want_log, double *secs);

typedef struct {
    const char *name;
    double play, pick;
} Level;

const Level LEVELS[] = {
    {"expert", 0.0, 0.0},
    {"a slip a fight", 0.055, 0.1},
    {"a blunder a turn", 0.22, 0.25},
    {"two a turn", 0.45, 0.5},
};
#define NLEVELS (int)(sizeof LEVELS / sizeof LEVELS[0])

#define RANDOM_MOST 0.005   /* random: 0% (under half a percent) */
#define GREEDY_MOST 0.05    /* greedy: a few % at most */
#define EXPERT_LEAST 0.60
#define EXPERT_MOST 0.75
#define TURN_SHARE 0.45     /* a blunder a turn: under this share of the expert */
#define ELITE_LEAST 0.02    /* an elite kills at least this share of the runs reaching it */
#define ELITE_RUNS 100      /* (counted when this many runs reach it) */

static int fails = 0;

static void verdict(int ok, const char *what) {
    printf("  %s  %s\n", ok ? "PASS" : "FAIL", what);
    fails += !ok;
}

static double won_share(const RunResult *r, int n) {
    int w = 0;
    for (int i = 0; i < n; i++)
        w += r[i].won;
    return (double)w / n;
}

static void deaths_line(const RunResult *r, int n) {
    Summary s;
    summary(r, n, &s);
    printf("    lost in fight:");
    for (int f = 1; f <= FIGHT_COUNT; f++)
        printf(" %d:%.1f%%", f, 100.0 * s.deaths[f] / n);
    printf("\n");
}

int check_targets(int runs, uint64_t seed, int jobs) {
    char buf[200];
    printf("targets: %d runs a line, seed %llu\n", runs, (unsigned long long)seed);
    RunResult *r = run_batch(P_RANDOM, runs, seed, jobs, 0, NULL);
    double w = won_share(r, runs);
    snprintf(buf, sizeof buf, "random wins %.1f%% (under %.1f%%)", 100 * w, 100 * RANDOM_MOST);
    verdict(w < RANDOM_MOST, buf);
    free(r);
    r = run_batch(P_GREEDY, runs, seed, jobs, 0, NULL);
    w = won_share(r, runs);
    snprintf(buf, sizeof buf, "greedy wins %.1f%% (%.0f%% at most)", 100 * w, 100 * GREEDY_MOST);
    verdict(w <= GREEDY_MOST, buf);
    deaths_line(r, runs);
    free(r);
    double lw[NLEVELS];
    for (int l = 0; l < NLEVELS; l++) {
        BLUNDER_PLAY = LEVELS[l].play;
        BLUNDER_PICK = LEVELS[l].pick;
        r = run_batch(P_SEARCH, runs, seed, jobs, 0, NULL);
        lw[l] = won_share(r, runs);
        long bl = 0, turns = 0, fights = 0;
        for (int i = 0; i < runs; i++) {
            bl += r[i].blunders;
            fights += r[i].nfights;
            for (int f = 0; f < r[i].nfights; f++)
                turns += r[i].fights[f].turns;
        }
        printf("  %-18s wins %5.1f%%  (a play %.3f, a pick %.2f: %.2f blunders a turn, %.2f a "
               "fight)\n", LEVELS[l].name, 100 * lw[l], LEVELS[l].play, LEVELS[l].pick,
               (double)bl / turns, (double)bl / fights);
        deaths_line(r, runs);
        if (l == 0) {
            snprintf(buf, sizeof buf, "the expert wins %.1f%% (%.0f-%.0f%%)", 100 * lw[0],
                     100 * EXPERT_LEAST, 100 * EXPERT_MOST);
            verdict(lw[0] >= EXPERT_LEAST && lw[0] <= EXPERT_MOST, buf);
            Summary s;
            summary(r, runs, &s);
            int king = s.deaths[FIGHT_COUNT], most = 1;
            for (int f = 1; f < FIGHT_COUNT; f++)
                most &= s.deaths[f] < king;
            snprintf(buf, sizeof buf, "the king kills the most expert runs (%.1f%%)",
                     100.0 * king / runs);
            verdict(most, buf);
            /* every elite row: the share of the runs that reached it that it killed */
            for (int row = 0; row < FIGHT_ROWS; row++) {
                if (!FIGHTS[row].nap)
                    continue;
                int reach = 0, lost = 0;
                for (int i = 0; i < runs; i++)
                    for (int f = 0; f < r[i].nfights; f++)
                        if (r[i].fights[f].index == row) {
                            reach++;
                            lost += !r[i].fights[f].won;
                        }
                if (reach < ELITE_RUNS) {
                    printf("        (%s: %d runs reach it, too few to judge)\n",
                           KINDS[FIGHTS[row].enemies[0]].name, reach);
                    continue;
                }
                snprintf(buf, sizeof buf, "%s kills %.1f%% of the %d expert runs reaching it "
                         "(%.0f%% at least)", KINDS[FIGHTS[row].enemies[0]].name,
                         100.0 * lost / reach, reach, 100 * ELITE_LEAST);
                verdict((double)lost / reach >= ELITE_LEAST, buf);
            }
        }
        free(r);
    }
    for (int l = 1; l < NLEVELS; l++) {
        snprintf(buf, sizeof buf, "%s (%.1f%%) wins less than %s (%.1f%%)", LEVELS[l].name,
                 100 * lw[l], LEVELS[l - 1].name, 100 * lw[l - 1]);
        verdict(lw[l] < lw[l - 1], buf);
    }
    snprintf(buf, sizeof buf, "a blunder a turn wins %.1f%%, under %.0f%% of the expert's (%.1f%%)",
             100 * lw[2], 100 * TURN_SHARE, 100 * TURN_SHARE * lw[0]);
    verdict(lw[2] < TURN_SHARE * lw[0], buf);
    BLUNDER_PLAY = BLUNDER_PICK = 0.0;
    printf("%s: %d failed\n", fails ? "FAIL" : "PASS", fails);
    return fails ? 1 : 0;
}
