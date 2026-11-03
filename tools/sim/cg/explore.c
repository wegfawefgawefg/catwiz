/* The studies of the run's range (study.c says how to run them): luck (what the offers
   decide), kits (random starting kits), domains (3 faces or more of one domain). */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "report.h"
#include "study.h"

/* ---- luck */

/* the learned lift of the best card offered after fight f (over the mean of the pool) */
static double offer_lift(const RunResult *r, int f) {
    double best = -1, sum = 0;
    int n = 0;
    for (int c = 0; c < FACE_COUNT + 6; c++) {
        int what = c < FACE_COUNT ? c : UP_CARD + c - FACE_COUNT;
        if (c < FACE_COUNT && !FACES[c].weight)
            continue;
        double v = learned_value(FORCE_CARD, f, what);
        if (!isnan(v)) {
            sum += v;
            n++;
        }
    }
    if (!n)
        return 0;
    for (int k = 0; k < FACES_DRAWN; k++) {
        int c = r->offer[f - 1][k];
        if (c == NOTHING)
            continue;
        double v = learned_value(FORCE_CARD, f, c);
        if (!isnan(v) && v > best)
            best = v;
    }
    return best < 0 ? 0 : best - sum / n;
}

static int by_double(const void *a, const void *b) {
    double x = *(const double *)a, y = *(const double *)b;
    return x < y ? -1 : x > y;
}

int study_luck(void) {
    RunResult *r = run_batch(S_PLAYER, S_RUNS, S_SEED, JOBS, 0, NULL);
    int wins = 0;
    for (int i = 0; i < S_RUNS; i++)
        wins += r[i].won;
    printf("luck: %s, %d runs, won %.1f%%\n", PLAYER_NAME[S_PLAYER], S_RUNS, 100.0 * wins / S_RUNS);
    /* the first three offers' learned lift (every run but the ones that die before), by fifth */
    for (int upto = 2; upto <= 6; upto += 4) {
        double *q = malloc(sizeof(double) * S_RUNS * 2);
        int m = 0;
        for (int i = 0; i < S_RUNS; i++) {
            if (r[i].nfights <= upto)
                continue;
            double l = 0;
            for (int f = 1; f <= upto; f++)
                l += offer_lift(&r[i], f);
            q[2 * m] = l;
            q[2 * m + 1] = r[i].won;
            m++;
        }
        qsort(q, m, sizeof(double) * 2, by_double);
        printf("  runs that won fight %d, by the learned worth of the best card in each of the "
               "first %d offers (fifths, worst first):\n", upto, upto);
        for (int k = 0; k < 5; k++) {
            int lo = m * k / 5, hi = m * (k + 1) / 5, w = 0;
            for (int j = lo; j < hi; j++)
                w += (int)q[2 * j + 1];
            printf("    fifth %d: lift %+.3f to %+.3f, won %.1f%% (%d runs)\n", k + 1, q[2 * lo],
                   q[2 * (hi - 1)], 100.0 * w / (hi - lo > 0 ? hi - lo : 1), hi - lo);
        }
        free(q);
    }
    free_runs(r, S_RUNS);
    /* the same seeds (the same dice stream) with other draws */
    if (S_SALTS > 1) {
        int n = S_RUNS / S_SALTS > 0 ? S_RUNS / S_SALTS : 1;
        double *p = calloc(n, sizeof(double));
        for (int k = 0; k < S_SALTS; k++) {
            OFFER_SALT = (uint64_t)k + 1;
            RunResult *x = run_batch(S_PLAYER, n, S_SEED, JOBS, 0, NULL);
            for (int i = 0; i < n; i++)
                p[i] += x[i].won;
            free_runs(x, n);
        }
        OFFER_SALT = 0;
        double mean = 0, within = 0, between = 0;
        int all = 0, none = 0;
        for (int i = 0; i < n; i++) {
            p[i] /= S_SALTS;
            mean += p[i];
        }
        mean /= n;
        for (int i = 0; i < n; i++) {
            within += p[i] * (1 - p[i]) * S_SALTS / (S_SALTS - 1.0);
            between += (p[i] - mean) * (p[i] - mean);
            all += p[i] == 1.0;
            none += p[i] == 0.0;
        }
        within /= n;
        between /= n;
        between -= within / S_SALTS; /* a seed's mean of S_SALTS draws is itself that noisy */
        if (between < 0)
            between = 0;
        printf("  %d seeds, %d draws each (a seed's dice start the same, then drift as the kits "
               "differ): won %.1f%%\n", n, S_SALTS,
               100 * mean);
        printf("    seeds won every time %.1f%%, never %.1f%%\n", 100.0 * all / n, 100.0 * none / n);
        printf("    the variance of a run's result: %.3f within a seed (the draws), %.3f between "
               "seeds (the start and the dice): the draws %.0f%% of it\n", within, between,
               100 * within / (within + between));
        free(p);
    }
    return 0;
}

/* ---- kits */

int study_kits(void) {
    Mt rng;
    mt_seed(&rng, S_SEED * 7 + 3);
    int pool[6][FACE_COUNT], npool[6] = {0};
    for (int id = 0; id < FACE_COUNT; id++) {
        int s = FACES[id].slot;
        if (s < 6 && (FACES[id].weight || memchr(STARTING_ITEMS, id, 6)))
            pool[s][npool[s]++] = id;
    }
    double *w = malloc(sizeof(double) * (S_KITS + 1));
    Kit *kits = malloc(sizeof(Kit) * (S_KITS + 1));
    char buf[400];
    for (int k = 0; k <= S_KITS; k++) {
        Kit kit;
        kit_start(&kit);
        if (k > 0)
            for (int s = 0; s < 6; s++)
                kit.items[s] = (uint8_t)pool[s][mt_below(&rng, npool[s])];
        kits[k] = kit;
        START_KIT = &kits[k];
        RunResult *r = run_batch(S_PLAYER, S_RUNS, S_SEED, JOBS, 0, NULL);
        int won = 0;
        for (int i = 0; i < S_RUNS; i++)
            won += r[i].won;
        w[k] = (double)won / S_RUNS;
        printf("  %s %5.1f%%  %s\n", k ? "kit" : "the game's", 100 * w[k], kit_words(&kit, buf));
        fflush(stdout);
        free_runs(r, S_RUNS);
    }
    START_KIT = NULL;
    double *sorted = malloc(sizeof(double) * S_KITS);
    memcpy(sorted, w + 1, sizeof(double) * S_KITS);
    qsort(sorted, S_KITS, sizeof(double), by_double);
    double mean = 0;
    for (int k = 0; k < S_KITS; k++)
        mean += sorted[k];
    mean /= S_KITS;
    printf("kits: %d random kits, %d runs each: mean %.1f%%, min %.1f%%, p10 %.1f%%, median "
           "%.1f%%, p90 %.1f%%, max %.1f%%; the game's kit %.1f%%\n", S_KITS, S_RUNS, 100 * mean,
           100 * sorted[0], 100 * sorted[S_KITS / 10], 100 * sorted[S_KITS / 2],
           100 * sorted[S_KITS * 9 / 10], 100 * sorted[S_KITS - 1], 100 * w[0]);
    free(sorted);
    free(w);
    free(kits);
    return 0;
}

/* ---- domains */

int study_domains(void) {
    RunResult *r = run_batch(S_PLAYER, S_RUNS, S_SEED, JOBS, 0, NULL);
    long got[D_COUNT] = {0}, won[D_COUNT] = {0}, any = 0, any_won = 0, none_won = 0, wins = 0;
    long by_fight[FIGHT_COUNT] = {0}, reach[FIGHT_COUNT] = {0};
    long faces_of[D_COUNT] = {0}, charms_of[D_COUNT] = {0};
    for (int id = 0; id < FACE_COUNT; id++)
        for (int d = 0; d < D_COUNT; d++)
            faces_of[d] += FACES[id].weight && (FACES[id].domains >> d & 1);
    for (int c = 0; c < CHARM_COUNT; c++)
        for (int d = 0; d < D_COUNT; d++)
            charms_of[d] += CHARMS[c].domains >> d & 1;
    for (int i = 0; i < S_RUNS; i++) {
        wins += r[i].won;
        for (int f = 0; f < r[i].nfights; f++) {
            const Kit *k = &r[i].kit_at[f];
            int top = 0;
            for (int d = 0; d < D_COUNT; d++) {
                int n = 0;
                for (int s = 0; s < 6; s++)
                    n += FACES[k->items[s]].domains >> d & 1;
                if (n > top)
                    top = n;
            }
            reach[f]++;
            by_fight[f] += top >= 3;
        }
        const Kit *k = r[i].nfights ? &r[i].kit_at[r[i].nfights - 1] : &r[i].kit;
        int has = 0;
        for (int d = 0; d < D_COUNT; d++) {
            int n = 0;
            for (int s = 0; s < 6; s++)
                n += FACES[k->items[s]].domains >> d & 1;
            if (n >= 3) {
                got[d]++;
                won[d] += r[i].won;
                has = 1;
            }
        }
        any += has;
        if (has)
            any_won += r[i].won;
        else
            none_won += r[i].won;
    }
    printf("domains: %s, %d runs, won %.1f%%\n", PLAYER_NAME[S_PLAYER], S_RUNS, 100.0 * wins / S_RUNS);
    printf("  kits with 3+ faces of one domain, walking into fight n (of the runs there):");
    for (int f = 0; f < FIGHT_COUNT; f++)
        printf(" %d:%.0f%%", f + 1, reach[f] ? 100.0 * by_fight[f] / reach[f] : 0);
    printf("\n  at the last fight a run reached: %.1f%% of runs (won %.1f%%); the others won "
           "%.1f%%\n", 100.0 * any / S_RUNS, any ? 100.0 * any_won / any : 0,
           S_RUNS - any ? 100.0 * none_won / (S_RUNS - any) : 0);
    printf("  domain\tfaces\tcharms\truns with 3+\twon\n");
    for (int d = 0; d < D_COUNT; d++)
        printf("  %s\t%ld\t%ld\t%.1f%%\t%s%.1f%%\n", DOMAIN_NAME[d], faces_of[d], charms_of[d],
               100.0 * got[d] / S_RUNS, got[d] < 30 ? "(few) " : "",
               got[d] ? 100.0 * won[d] / got[d] : 0);
    free_runs(r, S_RUNS);
    return 0;
}

