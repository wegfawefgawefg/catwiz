/* The swings study (main.c --study swings): natural runs of the player, then
   1. the turns that did the most damage with three systems or more touching (mana, kittens,
      a combo, statuses, tricks, charms), one a kind of turn, told from the run's log;
   2. for pairs of items (and an item with a charm): how many runs set them up (hold both),
      from which fight, how often a turn with both held plays both, and what those turns do
      against the other turns of the same fights. */
#include <stdio.h>
#include <stdlib.h>

#include "combos.h"

static const char *const SYS_WORD[6] = {"mana", "kittens", "combo", "status", "trick", "charm"};

static int popcount(unsigned x) {
    int n = 0;
    for (; x; x &= x - 1)
        n++;
    return n;
}

static void sys_words(int sys, char *out) {
    out[0] = 0;
    for (int i = 0; i < 6; i++)
        if (sys & (1 << i))
            sprintf(out + strlen(out), "%s%s", out[0] ? ", " : "", SYS_WORD[i]);
}

/* the start items' rows, as a mask: their faces are in every kit */
static uint64_t start_mask(void) {
    uint64_t m = 0;
    for (int s = 0; s < 6; s++)
        m |= 1ull << STARTING_ITEMS[s];
    return m;
}

/* the lines of run i's log from fight's "turn T" to the next turn or fight */
static void print_turn(int player, uint64_t seed, int i, int fight, int turn) {
    RunResult r;
    run_one(player, seed * 100000 + (uint64_t)i, &r, 1);
    if (!r.log)
        return;
    char head[32], tline[32];
    sprintf(head, "== fight %d ", fight);
    sprintf(tline, "turn %d ", turn);
    char *f = strstr(r.log, head);
    char *t = f ? strstr(f, tline) : NULL;
    if (t) {
        char *end = t + 1;
        for (;;) {
            char *nl = strchr(end, '\n');
            if (!nl || !nl[1] || !strncmp(nl + 1, "turn ", 5) || !strncmp(nl + 1, "==", 2) ||
                !strncmp(nl + 1, "   took", 7)) {
                end = nl ? nl : end + strlen(end);
                break;
            }
            end = nl + 1;
        }
        printf("%.*s\n", (int)(end - t), t);
    }
    free(r.log);
}

typedef struct {
    int run, idx;
    int dmg, sys;
    uint64_t sig;
} Swing;

/* four systems or more first, then by damage */
static int by_dmg(const void *x, const void *y) {
    const Swing *a = x, *b = y;
    int na = popcount((unsigned)a->sys) >= 4, nb = popcount((unsigned)b->sys) >= 4;
    if (na != nb)
        return nb - na;
    return b->dmg - a->dmg;
}

static void swing_turns(int player, const RunResult *r, int runs, uint64_t seed, int show) {
    uint64_t base = start_mask();
    long nt = 0, dsum = 0;
    int ns = 0, cap = 1 << 16;
    Swing *sw = malloc(sizeof(Swing) * cap);
    for (int i = 0; i < runs; i++) {
        for (int j = 0; j < r[i].nturns; j++) {
            const TurnRec *t = &r[i].turns[j];
            nt++;
            dsum += t->dmg;
            if (popcount(t->sys) >= 3 && ns < cap) {
                Swing *s = &sw[ns++];
                s->run = i;
                s->idx = j;
                s->dmg = t->dmg;
                s->sys = t->sys;
                s->sig = (t->played & ~base) ^ ((uint64_t)t->sys << 58);
            }
        }
    }
    printf("turns: %ld, %.1f damage a turn; %d (%.1f%%) touched three systems or more\n", nt,
           (double)dsum / nt, ns, 100.0 * ns / nt);
    qsort(sw, ns, sizeof *sw, by_dmg);
    uint64_t shown[64];
    int nshown = 0;
    for (int k = 0; k < ns && nshown < show; k++) {
        int dup = 0;
        for (int m = 0; m < nshown; m++)
            dup |= shown[m] == sw[k].sig;
        if (dup)
            continue;
        shown[nshown++] = sw[k].sig;
        const RunResult *x = &r[sw[k].run];
        const TurnRec *t = &x->turns[sw[k].idx];
        char words[80], kit[400];
        sys_words(t->sys, words);
        printf("\n%d damage (%s), run %d, fight %d turn %d; kit: %s\n", t->dmg, words,
               sw[k].run, t->fight, t->turn, kit_words(&x->kit_at[t->fight - 1], kit));
        print_turn(player, seed, sw[k].run, t->fight, t->turn);
    }
    free(sw);
}

static int holds(const Kit *k, int row) {
    return k->items[ITEMS[row].slot] == row;
}

static int holds_charm(const Kit *k, int c) {
    for (int i = 0; i < k->ncharms; i++)
        if (k->charms[i] == c)
            return 1;
    return 0;
}

/* a pair of parts in natural runs: runs that set it up (held both), from which fight, the
   turns with both held, those that played both (a charm counts as played), their damage */
typedef struct {
    int a, b, setup, first;
    long held, both, dheld, dboth;
} PairUse;

static int holds_part(const Kit *k, const Part *p) {
    return p->item >= 0 ? holds(k, p->item) : holds_charm(k, p->charm);
}

static void pair_use(const RunResult *r, int runs, const Part *a, const Part *b, PairUse *u) {
    for (int i = 0; i < runs; i++) {
        int f0 = 0;
        for (int f = 0; f < r[i].nfights && !f0; f++)
            if (holds_part(&r[i].kit_at[f], a) && holds_part(&r[i].kit_at[f], b))
                f0 = f + 1;
        if (!f0)
            continue;
        u->setup++;
        u->first += f0;
        for (int j = 0; j < r[i].nturns; j++) {
            const TurnRec *t = &r[i].turns[j];
            const Kit *k = &r[i].kit_at[t->fight - 1];
            if (!holds_part(k, a) || !holds_part(k, b))
                continue;
            u->held++;
            u->dheld += t->dmg;
            int pa = a->item < 0 || (t->played >> a->item & 1);
            int pb = b->item < 0 || (t->played >> b->item & 1);
            if (pa && pb) {
                u->both++;
                u->dboth += t->dmg;
            }
        }
    }
}

static double uplift(const PairUse *u) {
    if (!u->both || u->held <= u->both)
        return -99;
    return (double)u->dboth / u->both - (double)(u->dheld - u->dboth) / (u->held - u->both);
}

static int by_uplift(const void *x, const void *y) {
    double a = uplift(x), b = uplift(y);
    return a < b ? 1 : a > b ? -1 : 0;
}

int study_swings(int player, int runs, uint64_t seed, int jobs, int show) {
    double secs;
    RunResult *r = run_batch(player, runs, seed, jobs, 0, &secs);
    int won = 0;
    for (int i = 0; i < runs; i++)
        won += r[i].won;
    printf("swings: %s, %d runs (won %.1f%%, %.0f s)\n", PLAYER_NAME[player], runs,
           100.0 * won / runs, secs);
    swing_turns(player, r, runs, seed, show);
    /* every pair some run set up (at least 5% of runs), by what playing both in a turn adds */
    Part parts[64];
    int n = combo_parts(parts);
    PairUse *u = calloc((size_t)n * n, sizeof *u);
    int nu = 0;
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++) {
            if (parts[i].charm >= 0 && parts[j].charm >= 0)
                continue;
            if (parts[i].item >= 0 && parts[j].item >= 0 &&
                ITEMS[parts[i].item].slot == ITEMS[parts[j].item].slot)
                continue;
            PairUse *x = &u[nu];
            memset(x, 0, sizeof *x);
            x->a = i;
            x->b = j;
            pair_use(r, runs, &parts[i], &parts[j], x);
            if (x->setup * 20 >= runs && x->both >= 30)
                nu++;
        }
    qsort(u, nu, sizeof *u, by_uplift);
    printf("\npairs set up in 5%% of runs or more, by the damage a turn playing both does over "
           "the other turns with both held:\n");
    for (int k = 0; k < nu && k < show * 2; k++) {
        const PairUse *x = &u[k];
        printf("  %+5.1f  %s + %s: set up in %.0f%% of runs (from fight %.1f); both played in "
               "%.0f%% of the turns held, %.1f damage then (other turns %.1f)\n",
               uplift(x), part_name(&parts[x->a]), part_name(&parts[x->b]),
               100.0 * x->setup / runs, (double)x->first / x->setup, 100.0 * x->both / x->held,
               (double)x->dboth / x->both, (double)(x->dheld - x->dboth) / (x->held - x->both));
    }
    free(u);
    free(r);
    return 0;
}
