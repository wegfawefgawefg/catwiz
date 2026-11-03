#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
/* catwiz-sim (the catalog sim): runs a batch of whole runs and prints the report, or a run told
   turn by turn, or a study (study.c, broken.c).

     ./catwiz-sim --player search --runs 400 --learned learned.txt   (random, greedy, strong,
                                                                     search, all)
     ./catwiz-sim --player search --runs 1 --log 1 --seed 7          one run told
     ./catwiz-sim --study picks --runs 256 --out learned.txt         every pick forced; learns
     ./catwiz-sim --study cards|luck|kits|domains|broken|lift|blank ...  (study.c says)
     ./catwiz-sim --replay SEED [--player P]                         one run of that seed, told

   Seeds: run n of --seed s is seed s * 100000 + n. --jobs: threads (MOST_JOBS at most). */
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "pool.h"
#include "report.h"
#include "study.h"
#include "value.h"

typedef struct {
    int player, want_log;
    uint64_t seed;
    RunResult *out;
} Batch;

static double now(void);

static void one(int i, void *ctx) {
    Batch *b = ctx;
    double t0 = now();
    run_one(b->player, b->seed * 100000 + (uint64_t)i, &b->out[i], b->want_log && i < b->want_log);
    if (getenv("CATWIZ_SLOW") && now() - t0 > atof(getenv("CATWIZ_SLOW")))
        fprintf(stderr, "slow run: seed %llu %.1f s\n",
                (unsigned long long)(b->seed * 100000 + (uint64_t)i), now() - t0);
}

static double now(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return t.tv_sec + t.tv_nsec * 1e-9;
}

int JOBS = 8;

RunResult *run_batch(int player, int runs, uint64_t seed, int jobs, int want_log, double *secs) {
    Batch b = {player, want_log, seed, calloc(runs, sizeof(RunResult))};
    double t0 = now();
    parallel_for(runs, jobs, one, &b);
    if (secs)
        *secs = now() - t0;
    return b.out;
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
        for (int r = 0; r < FACE_COUNT; r++)
            if (!strcmp(w, FACES[r].name))
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

int player_by_name(const char *s) {
    for (int p = 0; p < P_COUNT; p++)
        if (!strcmp(s, PLAYER_NAME[p]))
            return p;
    fprintf(stderr, "no such player: %s\n", s);
    exit(2);
}

/* a kit by names, "FACE,FACE,FACE,FACE,FACE,FACE[;CHARM...]" (--kit) */
static Kit START;
static int kit_parse(const char *v) {
    kit_start(&START);
    char buf[512];
    snprintf(buf, sizeof buf, "%s", v);
    char *charms = strchr(buf, ';');
    if (charms)
        *charms++ = 0;
    char *save = NULL;
    for (char *p = strtok_r(buf, ",", &save); p; p = strtok_r(NULL, ",", &save)) {
        int id = plan_what(FORCE_CARD, p);
        if (id < 0 || id >= FACE_COUNT)
            return 1;
        START.items[FACES[id].slot] = (uint8_t)id;
    }
    for (char *p = charms ? strtok_r(charms, ",", &save) : NULL; p; p = strtok_r(NULL, ",", &save)) {
        int c = plan_what(FORCE_CHARM, p);
        if (c < 0)
            return 1;
        int hp = START.hp_max;
        Pick pk = {PK_CHARM, (uint8_t)c, 0, (uint8_t)c};
        pick_apply(&START, &hp, &pk);
    }
    START_KIT = &START;
    return 0;
}

int main(int argc, char **argv) {
    const char *player = "all";
    int runs = 300, logs = 0, picks = 0;
    uint64_t seed = 1, replay = 0;
    int replaying = 0;
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
            JOBS = atoi(v);
            i++;
        } else if (!strcmp(a, "--log")) {
            logs = atoi(v);
            i++;
        } else if (!strcmp(a, "--picks")) {
            picks = 1;
        } else if (!strcmp(a, "--ahead")) {
            DRAFT.ahead = atoi(v);
            i++;
        } else if (!strcmp(a, "--rollouts")) {
            DRAFT.rollouts = atoi(v);
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
        } else if (!strcmp(a, "--plan")) {
            if (plan_parse(v))
                return 2;
            i++;
        } else if (!strcmp(a, "--kit")) {
            if (kit_parse(v))
                return 2;
            i++;
        } else if (!strcmp(a, "--blunder")) {
            BLUNDER_PLAY = atof(v);
            i++;
        } else if (!strcmp(a, "--blunder-pick")) {
            BLUNDER_PICK = atof(v);
            i++;
        } else if (!strcmp(a, "--replay")) {
            replay = strtoull(v, 0, 10);
            replaying = 1;
            i++;
        } else if (!strcmp(a, "--study")) {
            judge_init();
            return study_main(argc - i - 1, argv + i + 1);
        } else {
            fprintf(stderr, "unknown argument: %s\n", a);
            return 2;
        }
    }
    judge_init();
    if (replaying) {
        RunResult r;
        run_one(player_by_name(strcmp(player, "all") ? player : "search"), replay, &r, 1);
        printf("%s", r.log ? r.log : "");
        printf("run %s\n", r.won ? "won" : "lost");
        free(r.log);
        return 0;
    }
    for (int p = 0; p < P_COUNT; p++) {
        if (strcmp(player, "all") && player_by_name(player) != p)
            continue;
        double secs;
        RunResult *r = run_batch(p, runs, seed, JOBS, logs, &secs);
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
