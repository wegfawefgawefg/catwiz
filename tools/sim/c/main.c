#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
/* catwiz-sim: the C balance sim. Runs a batch of whole runs and prints the report, or the
   runs one line each (--dump, for checking against the Python sim), or readable logs.

     ./catwiz-sim --player strong --runs 400            (random, greedy, strong, search, all)
     ./catwiz-sim --player search --runs 1 --log 1      the run told turn by turn
     ./catwiz-sim --player greedy --runs 50 --dump      a line a run (tools/sim/c/check.py)
     ./catwiz-sim --combos ...                          the combos study (combos.c)

   Seeds: run n of --seed s is seed s * 100000 + n, as the Python sim. --jobs (8 at most).
   Rules: the sixth toe rolls a sixth die and a waiting times stacks to x16 at most (the rule
   changes in docs/balance.md); --no-toe-fix --mult-cap 0 plays the Python sim's old rules. */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "combos.h"
#include "pool.h"
#include "report.h"
#include "value.h"

typedef struct {
    int player, want_log;
    uint64_t seed;
    RunResult *out;
} Batch;

static void one(int i, void *ctx) {
    Batch *b = ctx;
    run_one(b->player, b->seed * 100000 + (uint64_t)i, &b->out[i], b->want_log && i < b->want_log);
}

static double now(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

RunResult *run_batch(int player, int runs, uint64_t seed, int jobs, int want_log, double *secs) {
    Batch b = {player, want_log, seed, calloc(runs, sizeof(RunResult))};
    double t0 = now();
    parallel_for(runs, jobs, one, &b);
    if (secs)
        *secs = now() - t0;
    return b.out;
}

static void dump(const RunResult *r, int n, uint64_t seed) {
    char buf[80];
    for (int i = 0; i < n; i++) {
        printf("%llu %d %d |", (unsigned long long)(seed * 100000 + i), r[i].won, r[i].nfights);
        for (int f = 0; f < r[i].nfights; f++) {
            const FightResult *x = &r[i].fights[f];
            printf(" %d:%d:%d:%d:%d", x->index, x->won, x->hp_out, x->turns, x->lost);
        }
        printf(" |");
        for (int j = 0; j < r[i].npicks; j++)
            if (r[i].picks[j].what != PK_DOOR)
                printf(" %d:%s;", r[i].picks[j].after, pick_words(&r[i].picks[j], buf));
        printf("\n");
    }
}

static int plan_what(int kind, const char *w) {
    static const char *const up[6] = {"+1 WAND", "+1 FLUFF", "+1 STAR", "+1 BOOK", "+1 CURSE",
                                      "+1 TRICK"};
    if (w[0] >= '0' && w[0] <= '9')
        return atoi(w);
    if (kind == FORCE_CARD) {
        for (int i = 0; i < 6; i++)
            if (!strcmp(w, up[i]))
                return UP_CARD + i;
        for (int r = 0; r < ITEM_COUNT; r++)
            if (!strcmp(w, ITEMS[r].name))
                return r;
    } else if (kind == FORCE_CHARM) {
        for (int c = 0; c < CHARM_COUNT; c++)
            if (!strcmp(w, CHARMS[c].name))
                return c;
    } else if (kind == FORCE_NAP) {
        if (!strcmp(w, "heal"))
            return NOTHING;
        for (int i = 0; i < 6; i++)
            if (!strcmp(w, up[i]))
                return i;
    } else {
        for (int f = 0; f < FIGHT_ROWS; f++)
            if (!strcmp(w, KINDS[FIGHTS[f].enemies[0]].name))
                return f;
    }
    fprintf(stderr, "no such pick: %s\n", w);
    return -1;
}

static int plan_parse(const char *v) {
    char buf[1024], *save = NULL;
    snprintf(buf, sizeof buf, "%s", v);
    for (char *p = strtok_r(buf, ";", &save); p; p = strtok_r(NULL, ";", &save)) {
        char kind[16], what[64];
        int after;
        if (sscanf(p, "%15[a-z]:%d:%63[^;]", kind, &after, what) != 3 || NPLAN >= PLAN_MOST)
            return 1;
        Force *f = &PLAN[NPLAN++];
        f->on = 1;
        f->kind = !strcmp(kind, "card") ? FORCE_CARD : !strcmp(kind, "charm") ? FORCE_CHARM
                : !strcmp(kind, "nap") ? FORCE_NAP : FORCE_DOOR;
        f->after = after;
        f->a = plan_what(f->kind, what);
        if (f->a < 0)
            return 1;
    }
    return 0;
}

static int player_by_name(const char *s) {
    for (int p = 0; p < P_COUNT; p++)
        if (!strcmp(s, PLAYER_NAME[p]))
            return p;
    fprintf(stderr, "no such player: %s\n", s);
    exit(2);
}

int main(int argc, char **argv) {
    const char *player = "all";
    int runs = 300, jobs = 8, logs = 0, dumping = 0, picks = 0;
    uint64_t seed = 1;
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i];
        const char *v = i + 1 < argc ? argv[i + 1] : "";
        if (!strcmp(a, "--player")) {
            player = v;
            i++;
        } else if (!strcmp(a, "--runs")) {
            runs = atoi(v);
            i++;
        } else if (!strcmp(a, "--seed")) {
            seed = strtoull(v, 0, 10);
            i++;
        } else if (!strcmp(a, "--jobs")) {
            jobs = atoi(v);
            i++;
        } else if (!strcmp(a, "--log")) {
            logs = atoi(v);
            i++;
        } else if (!strcmp(a, "--dump")) {
            dumping = 1;
        } else if (!strcmp(a, "--picks")) {
            picks = 1;
        } else if (!strcmp(a, "--toe-fix")) {
            RULES.toe_fix = 1;
        } else if (!strcmp(a, "--kitten-rule")) {
            RULES.kitten_rule = atoi(v);
            i++;
        } else if (!strcmp(a, "--no-toe-fix")) {
            RULES.toe_fix = 0; /* the Python sim's old bag of five: the toe only a re-roll less */
        } else if (!strcmp(a, "--ahead")) {
            DRAFT.ahead = atoi(v); /* 0: the strong player's draft */
            i++;
        } else if (!strcmp(a, "--rollouts")) {
            DRAFT.rollouts = atoi(v);
            i++;
        } else if (!strcmp(a, "--roll-player")) {
            DRAFT.roll_player = player_by_name(v);
            i++;
        } else if (!strcmp(a, "--draft-kit")) {
            DRAFT.kit = atof(v);
            i++;
        } else if (!strcmp(a, "--learned")) {
            learned_load(v);
            i++;
        } else if (!strcmp(a, "--learn")) {
            DRAFT.learn = atof(v);
            i++;
        } else if (!strcmp(a, "--weights")) {
            weights_load(v);
            i++;
        } else if (!strcmp(a, "--force")) {
            /* kind:after:a, kind card, charm, nap or door (study.c's FORCE) */
            char kind[16];
            int after, x;
            if (sscanf(v, "%15[a-z]:%d:%d", kind, &after, &x) != 3)
                return 2;
            FORCE.on = 1;
            FORCE.kind = !strcmp(kind, "card") ? FORCE_CARD : !strcmp(kind, "charm") ? FORCE_CHARM
                       : !strcmp(kind, "nap") ? FORCE_NAP : FORCE_DOOR;
            FORCE.after = after;
            FORCE.a = x;
            i++;
        } else if (!strcmp(a, "--plan")) {
            /* picks forced at once, "kind:after:what;...", what a number or a name: an item,
               +1 SLOT, a charm, heal, a door's enemy */
            if (plan_parse(v))
                return 2;
            i++;
        } else if (!strcmp(a, "--mult-cap")) {
            RULES.mult_cap = atoi(v);
            i++;
        } else if (!strcmp(a, "--study")) {
            judge_init();
            search_init();
            return combos_main(argc - i - 1, argv + i + 1);
        } else {
            fprintf(stderr, "unknown argument: %s\n", a);
            return 2;
        }
    }
    judge_init();
    search_init();
    for (int p = 0; p < P_COUNT; p++) {
        if (strcmp(player, "all") && player_by_name(player) != p)
            continue;
        double secs;
        RunResult *r = run_batch(p, runs, seed, jobs, logs, &secs);
        if (dumping)
            dump(r, runs, seed);
        else
            print_report(p, r, runs, secs, picks);
        for (int i = 0; i < logs && i < runs; i++) {
            printf("\n---- run %d (seed %llu)\n%s", i, (unsigned long long)(seed * 100000 + i),
                   r[i].log ? r[i].log : "");
            free(r[i].log);
        }
        free(r);
        fflush(stdout);
    }
    return 0;
}
