#define _POSIX_C_SOURCE 200809L
/* The broken study and the lift study.

     broken  natural runs and what the fights peaked at: hits that reach the byte's 255, the
             biggest turns, the elites and the King's forms beaten in one of her turns from full
             hit points (and fights won on their first turn), dice brought back to the cap,
             hat tricks three deep, runaway plays; the run seeds to replay (--replay SEED), and
             which faces and charms the 255 fights held, against all fights.
     lift    parts given from fight 1 (a face in its slot, kept there, or a charm): each alone,
             then every pair (--parts "A,B,..." the parts; the default the suspects below);
             a pair's lift is its win rate less the better of its two alone. */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "report.h"
#include "study.h"

#define EXAMPLES 6

int study_broken(int player, int runs, uint64_t seed) {
    double secs;
    RunResult *r = run_batch(player, runs, seed, JOBS, 0, &secs);
    long fights = 0, f255 = 0, runs255 = 0, turn_big = 0, back_cap = 0, hat3 = 0, runaway = 0;
    long held_all[FACE_COUNT] = {0}, held_255[FACE_COUNT] = {0};
    long ch_all[CHARM_COUNT] = {0}, ch_255[CHARM_COUNT] = {0};
    long seen_kind[KIND_COUNT] = {0}, one_turn[KIND_COUNT] = {0}, first_turn[FIGHT_ROWS] = {0},
         at_row[FIGHT_ROWS] = {0};
    int max_steps = 0;
    uint64_t ex255[EXAMPLES], exkill[KIND_COUNT][EXAMPLES], exback[EXAMPLES], exhat[EXAMPLES],
        exrun[EXAMPLES];
    int n255 = 0, nkill[KIND_COUNT] = {0}, nback = 0, nhat = 0, nrun = 0;
    int ex255_f[EXAMPLES];
    int turn_hist[8] = {0}; /* the biggest turn of each fight: 0-19, 20-49, 50-99, 100-199,
                               200-299, 300-499, 500+ */
    for (int i = 0; i < runs; i++) {
        int any255 = 0;
        for (int f = 0; f < r[i].nfights; f++) {
            const FightResult *x = &r[i].fights[f];
            const Peak *p = &x->peak;
            const Kit *k = &r[i].kit_at[f];
            fights++;
            at_row[x->index]++;
            if (x->won && x->turns == 1)
                first_turn[x->index]++;
            for (int s = 0; s < 6; s++)
                held_all[k->items[s]]++;
            for (int h = 0; h < k->ncharms; h++)
                ch_all[k->charms[h]]++;
            int t = p->turn_dmg_max;
            turn_hist[t < 20 ? 0 : t < 50 ? 1 : t < 100 ? 2 : t < 200 ? 3 : t < 300 ? 4
                      : t < 500 ? 5 : 6]++;
            turn_big += t >= 255;
            if (p->hits255) {
                f255++;
                any255 = 1;
                for (int s = 0; s < 6; s++)
                    held_255[k->items[s]]++;
                for (int h = 0; h < k->ncharms; h++)
                    ch_255[k->charms[h]]++;
                if (n255 < EXAMPLES) {
                    ex255_f[n255] = f + 1;
                    ex255[n255++] = r[i].seed_of_run;
                }
            }
            for (int kd = 0; kd < KIND_COUNT; kd++)
                seen_kind[kd] += p->seen_kinds >> kd & 1;
            for (int j = 0; j < p->n_one_turn; j++) {
                int kd = p->one_turn_kind[j];
                one_turn[kd]++;
                if (nkill[kd] < EXAMPLES)
                    exkill[kd][nkill[kd]++] = r[i].seed_of_run;
            }
            if (p->back_cap_turns) {
                back_cap++;
                if (nback < EXAMPLES)
                    exback[nback++] = r[i].seed_of_run;
            }
            if (p->hat_deep >= 3) {
                hat3++;
                if (nhat < EXAMPLES)
                    exhat[nhat++] = r[i].seed_of_run;
            }
            if (p->runaway) {
                runaway++;
                if (nrun < EXAMPLES)
                    exrun[nrun++] = r[i].seed_of_run;
            }
            if (p->max_steps > max_steps)
                max_steps = p->max_steps;
        }
        runs255 += any255;
    }
    int wins = 0;
    for (int i = 0; i < runs; i++)
        wins += r[i].won;
    printf("broken: %s, %d runs (%.0f s), won %.1f%%, %ld fights\n", PLAYER_NAME[player], runs,
           secs, 100.0 * wins / runs, fights);
    printf("  fights with a hit of 255: %ld (%.2f%% of fights; %.1f%% of runs have one)\n", f255,
           100.0 * f255 / fights, 100.0 * runs255 / runs);
    for (int j = 0; j < n255; j++)
        printf("    seed %llu fight %d\n", (unsigned long long)ex255[j], ex255_f[j]);
    printf("  fights with a turn of 255 damage or more: %ld (%.2f%%)\n", turn_big,
           100.0 * turn_big / fights);
    printf("  the biggest turn of each fight: under 20 %.1f%%, 20-49 %.1f%%, 50-99 %.1f%%, "
           "100-199 %.1f%%, 200-299 %.1f%%, 300-499 %.1f%%, 500+ %.1f%%\n",
           100.0 * turn_hist[0] / fights, 100.0 * turn_hist[1] / fights,
           100.0 * turn_hist[2] / fights, 100.0 * turn_hist[3] / fights,
           100.0 * turn_hist[4] / fights, 100.0 * turn_hist[5] / fights,
           100.0 * turn_hist[6] / fights);
    if (f255) {
        printf("  held in the 255 fights, against all fights (the most over-represented):\n");
        int order[FACE_COUNT + CHARM_COUNT];
        double lift[FACE_COUNT + CHARM_COUNT];
        int m = 0;
        for (int id = 0; id < FACE_COUNT + CHARM_COUNT; id++) {
            long a = id < FACE_COUNT ? held_all[id] : ch_all[id - FACE_COUNT];
            long b = id < FACE_COUNT ? held_255[id] : ch_255[id - FACE_COUNT];
            if (b < 3)
                continue;
            lift[id] = ((double)b / f255) / ((double)a / fights);
            int j = m++;
            while (j > 0 && lift[order[j - 1]] < lift[id]) {
                order[j] = order[j - 1];
                j--;
            }
            order[j] = id;
        }
        for (int j = 0; j < m && j < 15; j++) {
            int id = order[j];
            long b = id < FACE_COUNT ? held_255[id] : ch_255[id - FACE_COUNT];
            printf("    %-18s in %5.1f%% of them, x%.1f its share of all fights\n",
                   id < FACE_COUNT ? FACES[id].name : CHARMS[id - FACE_COUNT].name,
                   100.0 * b / f255, lift[id]);
        }
    }
    printf("  beaten in one of her turns from full hit points (of the fights it stood in):\n");
    for (int kd = 0; kd < KIND_COUNT; kd++) {
        int elite = kd == 21 || kd == 13 || kd == 14 || kd == 15 || kd == 16 ||
                    (kd >= KING && kd <= KING_3);
        if (!elite || !seen_kind[kd])
            continue;
        printf("    %-22s %5.1f%% of %ld", KINDS[kd].name, 100.0 * one_turn[kd] / seen_kind[kd],
               seen_kind[kd]);
        for (int j = 0; j < nkill[kd] && j < 3; j++)
            printf("%s%llu", j ? " " : "  e.g. seeds ", (unsigned long long)exkill[kd][j]);
        printf("\n");
    }
    printf("  fights won on their first turn:");
    for (int row = 0; row < FIGHT_ROWS; row++)
        if (at_row[row])
            printf(" %s %.1f%%", KINDS[FIGHTS[row].enemies[0]].name,
                   100.0 * first_turn[row] / at_row[row]);
    printf("\n  fights where her dice came back the most a turn (%d) at least once: %ld (%.2f%%)",
           BACK_MOST, back_cap, 100.0 * back_cap / fights);
    for (int j = 0; j < nback && j < 3; j++)
        printf("%s%llu", j ? " " : "  e.g. seeds ", (unsigned long long)exback[j]);
    printf("\n  fights with a hat trick three calls deep: %ld", hat3);
    for (int j = 0; j < nhat && j < 3; j++)
        printf("%s%llu", j ? " " : "  e.g. seeds ", (unsigned long long)exhat[j]);
    printf("\n  runaway plays (over %d steps): %ld", STEP_GUARD, runaway);
    for (int j = 0; j < nrun && j < 3; j++)
        printf("%s%llu", j ? " " : "  e.g. seeds ", (unsigned long long)exrun[j]);
    printf("; the most steps in one play: %d\n", max_steps);
    print_report(player, r, runs, secs, 0);
    free_runs(r, runs);
    return 0;
}

/* ---- lift */

typedef struct {
    int face, charm; /* one is -1 */
} Part;

static const char *const SUSPECTS[] = {
    "PAW FLIP", "ALL IN", "TIMES TWO", "DOUBLE OR NOTHING", "HAT TRICK", "SPELL ECHO", "MIMIC",
    "RED DOT", "FRESH ROLL", "COPYCAT", "STONE CAT", "HISS", "SHARPEN CLAWS", "BOX SLAM",
    "PUFFED UP", "MANA BURN", "SNOWBALL", "THUNDER PURR", "KITTEN CANNON", "MEOWCRONOMICON",
    "JACKPOT", "MANA BATTERY", "ECHO", "CHEAP TRICK", "LUCKY SEVEN", NULL};

static int part_of(const char *name, Part *p) {
    for (int id = 0; id < FACE_COUNT; id++)
        if (!strcmp(FACES[id].name, name)) {
            p->face = id;
            p->charm = -1;
            return 1;
        }
    for (int c = 0; c < CHARM_COUNT; c++)
        if (!strcmp(CHARMS[c].name, name)) {
            p->face = -1;
            p->charm = c;
            return 1;
        }
    fprintf(stderr, "no part %s\n", name);
    return 0;
}

static const char *part_name(const Part *p) {
    return p->face >= 0 ? FACES[p->face].name : CHARMS[p->charm].name;
}

static int give(Kit *k, const Part *p) {
    if (p->face >= 0) {
        int s = FACES[p->face].slot;
        if (k->locked >> s & 1)
            return 0; /* two faces of one slot */
        k->items[s] = (uint8_t)p->face;
        k->locked |= (uint8_t)(1 << s);
        return 1;
    }
    int hp = k->hp_max;
    Pick pk = {PK_CHARM, (uint8_t)p->charm, 0, (uint8_t)p->charm};
    pick_apply(k, &hp, &pk);
    return 1;
}

static double win_with(int player, int runs, uint64_t seed, const Part *a, const Part *b) {
    Kit k;
    kit_start(&k);
    if (a && !give(&k, a))
        return NAN;
    if (b && !give(&k, b))
        return NAN;
    START_KIT = &k;
    RunResult *r = run_batch(player, runs, seed, JOBS, 0, NULL);
    START_KIT = NULL;
    int w = 0;
    for (int i = 0; i < runs; i++)
        w += r[i].won;
    free_runs(r, runs);
    return (double)w / runs;
}

int study_lift(int player, int runs, uint64_t seed, const char *only) {
    Part parts[64];
    int n = 0;
    if (only) {
        char buf[1024], *save = NULL;
        snprintf(buf, sizeof buf, "%s", only);
        for (char *t = strtok_r(buf, ",", &save); t && n < 64; t = strtok_r(NULL, ",", &save))
            if (part_of(t, &parts[n]))
                n++;
    } else {
        for (int i = 0; SUSPECTS[i]; i++)
            if (part_of(SUSPECTS[i], &parts[n]))
                n++;
    }
    double none = win_with(player, runs, seed, NULL, NULL);
    printf("lift: %s, %d runs a cell; nothing given %.1f%%\n", PLAYER_NAME[player], runs,
           100 * none);
    double alone[64];
    for (int i = 0; i < n; i++) {
        alone[i] = win_with(player, runs, seed, &parts[i], NULL);
        printf("  alone %-18s %5.1f%%\n", part_name(&parts[i]), 100 * alone[i]);
        fflush(stdout);
    }
    printf("  pairs (won, lift over the better alone):\n");
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++) {
            double w = win_with(player, runs, seed, &parts[i], &parts[j]);
            if (isnan(w))
                continue;
            double best = alone[i] > alone[j] ? alone[i] : alone[j];
            printf("  pair %-18s + %-18s %5.1f%%  lift %+5.1f\n", part_name(&parts[i]),
                   part_name(&parts[j]), 100 * w, 100 * (w - best));
            fflush(stdout);
        }
    return 0;
}
