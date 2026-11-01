/* The chain and combo cards' study (main.c --study chains): natural runs of the player, then

   1. every card and charm of the pools: taken when offered, the runs that held it, won;
   2. the chains, on the turns of fights where the card was held: dice back by red dot, big
      stretch and second wind, finishing swat's dice come back, re-rolls got from lucky paw
      and sunbeam (median, top tenth, most a turn), and every refresh a turn;
   3. how big a card's turns are: the turns that played its face (a charm: the turns of the
      fights that held it), their damage (mean, top tenth, most) and the share that touched
      three systems or more (combos.c's swings counts them the same way). */
#include <stdio.h>
#include <stdlib.h>

#include "combos.h"

RunResult *run_batch(int player, int runs, uint64_t seed, int jobs, int want_log, double *secs);

static int by_int(const void *a, const void *b) {
    return *(const int *)a - *(const int *)b;
}

static int bits(int x) {
    int n = 0;
    for (; x; x >>= 1)
        n += x & 1;
    return n;
}

/* the median, top tenth and most of n numbers (sorted in place) */
static void spread(int *v, int n, int *med, int *p90, int *most) {
    qsort(v, n, sizeof *v, by_int);
    *med = n ? v[n / 2] : 0;
    *p90 = n ? v[n * 9 / 10] : 0;
    *most = n ? v[n - 1] : 0;
}

static int held_item(const RunResult *r, int fight, int row) {
    return r->kit_at[fight - 1].items[ITEMS[row].slot] == row;
}

static int held_charm(const RunResult *r, int fight, int c) {
    const Kit *k = &r->kit_at[fight - 1];
    for (int i = 0; i < k->ncharms; i++)
        if (k->charms[i] == c)
            return 1;
    return 0;
}

static void takes(const RunResult *r, int runs) {
    printf("  card: taken when offered (times offered), runs that held it (won)\n");
    for (int pass = 0; pass < 2; pass++) {
        int count = pass ? CHARM_OFFER_COUNT : OFFER_COUNT;
        for (int o = 0; o < count; o++) {
            const OfferRow *of = pass ? &CHARM_OFFERS[o] : &OFFERS[o];
            int c = of->what;
            if (!of->weight || (!pass && c >= ITEM_COUNT))
                continue;
            int offered = 0, taken = 0, held = 0, hw = 0;
            for (int i = 0; i < runs; i++) {
                int h = 0;
                for (int f = 1; f <= FIGHT_COUNT; f++) {
                    const uint8_t *in = pass ? r[i].charm_offer[f - 1] : r[i].offer[f - 1];
                    if (in[0] != c && in[1] != c && in[2] != c)
                        continue;
                    offered++;
                    for (int j = 0; j < r[i].npicks; j++) {
                        const Pick *pk = &r[i].picks[j];
                        int kind_ok = pass ? pk->what == PK_CHARM
                                           : pk->what == PK_ITEM || pk->what == PK_LEVEL;
                        if (kind_ok && pk->after == f && pk->card == c)
                            taken++;
                    }
                }
                for (int f = 1; f <= r[i].nfights; f++)
                    h |= pass ? held_charm(&r[i], f, c) : held_item(&r[i], f, c);
                held += h;
                hw += h && r[i].won;
            }
            printf("    %-18s %3.0f%% (%5d)  %5.1f%% of runs (won %5.1f%%)\n",
                   pass ? CHARMS[c].name : ITEMS[c].name, offered ? 100.0 * taken / offered : 0,
                   offered, 100.0 * held / runs, held ? 100.0 * hw / held : 0);
        }
    }
}

/* a chain count of a turn: 0 red dot, 1 big stretch, 2 second wind, 3 swat, 4 re-rolls got,
   5 every refresh */
static int chain_of(const TurnRec *t, int what) {
    switch (what) {
    case 0: return t->dot;
    case 1: return t->stretch;
    case 2: return t->nine;
    case 3: return t->swat;
    case 4: return t->gain;
    }
    return t->dot + t->stretch + t->nine;
}

static void chains(const RunResult *r, int runs, int *buf) {
    static const char *const NAME[] = {"RED DOT", "BIG STRETCH", "SECOND WIND",
                                       "FINISHING SWAT", "LUCKY PAW", "SUNBEAM"};
    static const char *const WHAT[] = {"refreshes", "refreshes", "refreshes", "dice back",
                                       "re-rolls got", "re-rolls got"};
    printf("  chains, a turn of a fight that held it: median, top tenth, most (turns)\n");
    for (int c = 0; c < 6; c++) {
        int row = -1, charm = -1;
        for (int q = 0; q < ITEM_COUNT; q++)
            if (!strcmp(ITEMS[q].name, NAME[c]))
                row = q;
        for (int q = 0; q < CHARM_COUNT; q++)
            if (!strcmp(CHARMS[q].name, NAME[c]))
                charm = q;
        if (row < 0 && charm < 0)
            continue;
        int what = c < 4 ? c : 4, n = 0, any = 0;
        for (int i = 0; i < runs; i++)
            for (int j = 0; j < r[i].nturns; j++) {
                const TurnRec *t = &r[i].turns[j];
                if (row >= 0 ? !held_item(&r[i], t->fight, row) : !held_charm(&r[i], t->fight, charm))
                    continue;
                int v = chain_of(t, what);
                buf[n++] = v;
                any += v > 0;
            }
        int med, p90, most;
        spread(buf, n, &med, &p90, &most);
        printf("    %-18s %-12s %d, %d, %d (%d turns; %.0f%% with one)\n", NAME[c], WHAT[c], med,
               p90, most, n, n ? 100.0 * any / n : 0);
    }
    int n = 0, capped = 0;
    for (int i = 0; i < runs; i++)
        for (int j = 0; j < r[i].nturns; j++) {
            int v = chain_of(&r[i].turns[j], 5);
            if (v) {
                buf[n++] = v;
                capped += v >= (RULES.refresh_most ? RULES.refresh_most : 255);
            }
        }
    int med, p90, most;
    spread(buf, n, &med, &p90, &most);
    printf("    turns with a refresh: %d; refreshes then %d, %d, %d; at the cap %d\n", n, med, p90,
           most, capped);
}

static void swings(const RunResult *r, int runs, int *buf) {
    printf("  turns: the card's face played (a charm: held): turns, damage mean, top tenth, "
           "most; three systems or more\n");
    for (int pass = 0; pass < 2; pass++) {
        int count = pass ? CHARM_COUNT : ITEM_COUNT;
        for (int c = 0; c < count; c++) {
            int n = 0, multi = 0;
            double sum = 0;
            for (int i = 0; i < runs; i++)
                for (int j = 0; j < r[i].nturns; j++) {
                    const TurnRec *t = &r[i].turns[j];
                    if (pass ? !held_charm(&r[i], t->fight, c) : !(t->played >> c & 1))
                        continue;
                    buf[n++] = t->dmg;
                    sum += t->dmg;
                    multi += bits(t->sys) >= 3;
                }
            if (n < 20)
                continue;
            int med, p90, most;
            spread(buf, n, &med, &p90, &most);
            printf("    %-18s %7d  %5.1f %4d %4d  %4.0f%%\n", pass ? CHARMS[c].name : ITEMS[c].name,
                   n, sum / n, p90, most, 100.0 * multi / n);
        }
    }
}

int study_chains(int player, int runs, uint64_t seed, int jobs) {
    double secs = 0;
    RunResult *r = run_batch(player, runs, seed, jobs, 0, &secs);
    int won = 0, nt = 0;
    for (int i = 0; i < runs; i++) {
        won += r[i].won;
        nt += r[i].nturns;
    }
    printf("chains: %s, %d runs, won %.1f%% (%.1f s, %.0f runs/s)\n", PLAYER_NAME[player], runs,
           100.0 * won / runs, secs, secs > 0 ? runs / secs : 0);
    int *buf = malloc(sizeof(int) * (nt + 1));
    takes(r, runs);
    chains(r, runs, buf);
    swings(r, runs, buf);
    free(buf);
    free(r);
    return 0;
}
