/* The combos studies (main.c --study NAME ...):

   lift    which items and charms win together. Each "part" (an item not in the starting kit,
           or a charm) is given from fight 1, its slot locked so no card replaces it, alone
           and in every pair (and the best pairs with a third); the rest of the run drafted as
           usual, the same seeds for every cell. A pair's lift is its win rate's log-odds less
           what its parts give apart: logit(AB) - logit(A) - logit(B) + logit(none). Positive:
           they win together more than the parts say.
   swings  the natural runs (swings.c): the turns that did the most with three systems or
           more touching, told; how often a run sets a pair up and plays it in one turn.
   picks   every pick forced in turn (study.c). */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "combos.h"

int study_picks(int player, int runs, uint64_t seed, int jobs);
extern FILE *STUDY_OUT;
extern int STUDY_ONLY;
int study_swings(int player, int runs, uint64_t seed, int jobs, int show);
int study_luck(int player, int runs, uint64_t seed, int jobs);

int combo_parts(Part *out) {
    int n = 0;
    for (int row = 0; row < ITEM_COUNT; row++) {
        if (row == HAIRBALL)
            continue;
        int start = 0;
        for (int s = 0; s < 6; s++)
            start |= STARTING_ITEMS[s] == row;
        if (start)
            continue;
        out[n].item = row;
        out[n].charm = -1;
        n++;
    }
    for (int c = 0; c < CHARM_COUNT; c++) {
        out[n].item = -1;
        out[n].charm = c;
        n++;
    }
    return n;
}

const char *part_name(const Part *p) {
    return p->item >= 0 ? ITEMS[p->item].name : CHARMS[p->charm].name;
}

static void kit_add(Kit *k, const Part *p) {
    if (p->item >= 0) {
        int slot = ITEMS[p->item].slot;
        k->items[slot] = (uint8_t)p->item;
        k->locked |= (uint8_t)(1 << slot);
    } else {
        k->charms[k->ncharms++] = (uint8_t)p->charm;
    }
}

static int clash(const Part *a, const Part *b) {
    if (a->item >= 0 && b->item >= 0)
        return ITEMS[a->item].slot == ITEMS[b->item].slot;
    return a->charm >= 0 && a->charm == b->charm;
}

/* the share of runs won with this start kit */
static double cell(int player, int runs, uint64_t seed, int jobs, const Kit *k) {
    START_KIT = k;
    RunResult *r = run_batch(player, runs, seed, jobs, 0, NULL);
    START_KIT = NULL;
    int won = 0;
    for (int i = 0; i < runs; i++)
        won += r[i].won;
    free(r);
    return (double)won / runs;
}

static double logit(double p, int n) {
    double q = (p * n + 0.5) / (n + 1.0);
    return log(q / (1 - q));
}

typedef struct {
    int a, b;
    double win, lift;
} PairOut;

static int by_lift(const void *x, const void *y) {
    const PairOut *p = x, *q = y;
    return p->lift < q->lift ? 1 : p->lift > q->lift ? -1 : 0;
}

static double pair_lift(const PairOut *pairs, int np, int a, int b) {
    for (int i = 0; i < np; i++)
        if ((pairs[i].a == a && pairs[i].b == b) || (pairs[i].a == b && pairs[i].b == a))
            return pairs[i].lift;
    return -9;
}

static void print_pair(const PairOut *p, const Part *parts, const double *solo) {
    printf("  %+.2f  %s + %s (won %.0f%%; apart %.0f%%, %.0f%%)\n", p->lift,
           part_name(&parts[p->a]), part_name(&parts[p->b]), 100 * p->win, 100 * solo[p->a],
           100 * solo[p->b]);
}

static int study_lift(int player, int runs, uint64_t seed, int jobs, int top) {
    Part parts[64];
    int n = combo_parts(parts);
    Kit base;
    kit_start(&base);
    double w0 = cell(player, runs, seed, jobs, &base);
    printf("lift: %s, %d runs a cell, parts given from fight 1 (slot locked)\n",
           PLAYER_NAME[player], runs);
    printf("  none: won %.1f%%\n", 100 * w0);
    double solo[64];
    for (int i = 0; i < n; i++) {
        Kit k = base;
        kit_add(&k, &parts[i]);
        solo[i] = cell(player, runs, seed, jobs, &k);
        printf("  %-18s won %5.1f%%  (%+.2f log-odds)\n", part_name(&parts[i]), 100 * solo[i],
               logit(solo[i], runs) - logit(w0, runs));
        fflush(stdout);
    }
    PairOut *pairs = malloc(sizeof(PairOut) * n * n);
    int np = 0;
    for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
            if (clash(&parts[i], &parts[j]))
                continue;
            Kit k = base;
            kit_add(&k, &parts[i]);
            kit_add(&k, &parts[j]);
            double w = cell(player, runs, seed, jobs, &k);
            PairOut *p = &pairs[np++];
            p->a = i;
            p->b = j;
            p->win = w;
            p->lift = logit(w, runs) - logit(solo[i], runs) - logit(solo[j], runs) + logit(w0, runs);
            printf("  pair %s + %s: won %.1f%%, lift %+.2f\n", part_name(&parts[i]),
                   part_name(&parts[j]), 100 * w, p->lift);
            fflush(stdout);
        }
    }
    qsort(pairs, np, sizeof *pairs, by_lift);
    printf("\nthe pairs, by lift (log-odds over the parts apart):\n");
    for (int i = 0; i < np && i < top; i++)
        print_pair(&pairs[i], parts, solo);
    printf("the pairs that win worse together:\n");
    for (int i = np - 1; i >= 0 && i >= np - 10; i--)
        print_pair(&pairs[i], parts, solo);
    printf("triples (the best pairs and a third that lifts with both):\n");
    for (int t = 0; t < 8 && t < np; t++) {
        int a = pairs[t].a, b = pairs[t].b;
        for (int c = 0; c < n; c++) {
            if (c == a || c == b || clash(&parts[c], &parts[a]) || clash(&parts[c], &parts[b]))
                continue;
            if (pair_lift(pairs, np, a, c) < 0.3 || pair_lift(pairs, np, b, c) < 0.3)
                continue;
            Kit k = base;
            kit_add(&k, &parts[a]);
            kit_add(&k, &parts[b]);
            kit_add(&k, &parts[c]);
            double w = cell(player, runs, seed, jobs, &k);
            printf("  %s + %s + %s: won %.0f%% (the pair %.0f%%, %s alone %.0f%%)\n",
                   part_name(&parts[a]), part_name(&parts[b]), part_name(&parts[c]), 100 * w,
                   100 * pairs[t].win, part_name(&parts[c]), 100 * solo[c]);
            fflush(stdout);
        }
    }
    free(pairs);
    return 0;
}

int combos_main(int argc, char **argv) {
    const char *what = argc > 0 ? argv[0] : "";
    int player = P_SEARCH, runs = 256, jobs = 8, top = 30;
    uint64_t seed = 31;
    for (int i = 1; i + 1 < argc; i += 2) {
        if (!strcmp(argv[i], "--runs"))
            runs = atoi(argv[i + 1]);
        else if (!strcmp(argv[i], "--seed"))
            seed = strtoull(argv[i + 1], 0, 10);
        else if (!strcmp(argv[i], "--jobs"))
            jobs = atoi(argv[i + 1]);
        else if (!strcmp(argv[i], "--top"))
            top = atoi(argv[i + 1]);
        else if (!strcmp(argv[i], "--only"))
            STUDY_ONLY = atoi(argv[i + 1]);
        else if (!strcmp(argv[i], "--out"))
            STUDY_OUT = fopen(argv[i + 1], "w");
        else if (!strcmp(argv[i], "--player"))
            for (int p = 0; p < P_COUNT; p++)
                if (!strcmp(argv[i + 1], PLAYER_NAME[p]))
                    player = p;
    }
    if (!strcmp(what, "picks")) {
        int rc = study_picks(player, runs, seed, jobs);
        if (STUDY_OUT)
            fclose(STUDY_OUT);
        return rc;
    }
    if (!strcmp(what, "lift"))
        return study_lift(player, runs, seed, jobs, top);
    if (!strcmp(what, "luck"))
        return study_luck(player, runs, seed, jobs);
    if (!strcmp(what, "swings"))
        return study_swings(player, runs, seed, jobs, top);
    fprintf(stderr, "studies: picks, lift, swings\n");
    return 2;
}
