/* The studies (./catwiz-sim --study NAME [--player P] [--runs N] [--seed S] [--jobs J]
   [--learned F --learn W] ...):

     picks    every pick forced in turn, the rest drafted as the player would, the same seeds
              for every option: a face, an upgrade, a skip or a blank face at the first pick of
              each third (after fights 1, 4, 7; the value stands for the third), a charm or a
              skip, the nap's heal and levels after each elite, both doors. --out F writes the
              learned values (the draft's --learned), --table F a line an option.
     cards    natural runs: each face's and charm's offers, picks, and the runs that held it
              against those that did not, and how often it is played when it shows.
     luck     how much the offers decide a run: the runs by the learned worth of what their
              first offers brought; and the same seeds with other draws (--salts K).
     kits     random starting kits (--kits K, --runs a kit): the spread of win rates.
     domains  natural runs: how often a kit holds 3 faces or more of one domain, and how those
              runs do.
     broken, lift   broken.c. */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "report.h"
#include "study.h"

void free_runs(RunResult *r, int n) {
    for (int i = 0; i < n; i++)
        free(r[i].log);
    free(r);
}

static FILE *OUT = NULL, *TABLE = NULL;
static int PLAYER = P_SEARCH, RUNS = 256, ONLY = 0;
static uint64_t SEED = 1;
static int SALTS = 4, KITS = 64;

static const char *const SLOTS6[6] = {"wand", "fluff", "star", "book", "curse", "trick"};

static int kind_of_pick(const Pick *p) {
    return p->what == PK_DOOR ? FORCE_DOOR : p->what == PK_CHARM ? FORCE_CHARM
         : (p->what == PK_NAP_HEAL || p->what == PK_NAP_LEVEL) ? FORCE_NAP
         : (p->what == PK_SKIP && p->a == 1) ? FORCE_CHARM : FORCE_CARD;
}

static double share_of(const RunResult *r, int n, int kind, int after, int a) {
    int got = 0, took = 0;
    for (int i = 0; i < n; i++)
        for (int j = 0; j < r[i].npicks; j++) {
            const Pick *p = &r[i].picks[j];
            if (kind_of_pick(p) != kind || p->after != after)
                continue;
            got++;
            took += p->card == a;
        }
    return got ? (double)took / got : 0;
}

static void option(const RunResult *base, Force fo, const char *what, int lo, int hi) {
    FORCE = fo;
    RunResult *r = run_batch(PLAYER, RUNS, SEED, JOBS, 0, NULL);
    Summary s;
    summary(r, RUNS, &s);
    double taken = share_of(base, RUNS, fo.kind, fo.after, fo.a);
    printf("    %-24s won %5.1f%%  hp at the end %4.1f  (taken unforced %3.0f%%)\n", what,
           100 * s.win, s.hp_end, 100 * taken);
    fflush(stdout);
    for (int f = lo; f <= hi && OUT; f++)
        fprintf(OUT, "%d %d %d %.4f\n", fo.kind, f, fo.a, s.win);
    if (TABLE)
        fprintf(TABLE, "%d\t%d\t%d\t%s\t%.4f\t%.3f\t%.3f\n", fo.kind, fo.after, fo.a, what,
                s.win, s.hp_end, taken);
    if (OUT)
        fflush(OUT);
    if (TABLE)
        fflush(TABLE);
    free_runs(r, RUNS);
}

static int study_picks(void) {
    double secs;
    RunResult *base = run_batch(PLAYER, RUNS, SEED, JOBS, 0, &secs);
    Summary s;
    summary(base, RUNS, &s);
    printf("%s, %d runs a line, unforced: won %.1f%% (%.0f s)\n", PLAYER_NAME[PLAYER], RUNS,
           100 * s.win, secs);
    if (TABLE)
        fprintf(TABLE, "-1\t0\t0\tunforced\t%.4f\t%.3f\t0\n", s.win, s.hp_end);
    char buf[64], name[48];
    static const int third[3][2] = {{1, 3}, {4, 6}, {7, FIGHT_COUNT - 1}};
    for (int t = 0; t < 3; t++) {
        int at = third[t][0];
        if (ONLY && ONLY != at)
            continue;
        printf("  cards after fight %d (for fights %d-%d):\n", at, at, third[t][1]);
        for (int c = 0; c < FACE_COUNT + 6 + 2 + 6; c++) {
            int what;
            if (c < FACE_COUNT) {
                if (!FACES[c].weight)
                    continue;
                what = c;
            } else if (c < FACE_COUNT + 6) {
                what = UP_CARD + c - FACE_COUNT;
            } else if (c == FACE_COUNT + 6) {
                what = SKIP_CARD;
            } else if (c == FACE_COUNT + 7) {
                continue;
            } else {
                what = BLANK_CARD + c - FACE_COUNT - 8;
            }
            snprintf(buf, sizeof buf, "%s", card_name(what, name));
            option(base, (Force){1, FORCE_CARD, at, what}, buf, at, third[t][1]);
        }
    }
    for (int row = 0; row < FIGHT_COUNT - 1; row++) {
        const FightRow *fr = &FIGHTS[row];
        int after = row + 1;
        if (ONLY && ONLY != after && !(fr->other != NOTHING && ONLY == row))
            continue;
        if (fr->other != NOTHING) {
            printf("  door at fight %d:\n", after);
            for (int d = 0; d < 2; d++) {
                int idx = d ? fr->other : row;
                option(base, (Force){1, FORCE_DOOR, row, idx}, KINDS[FIGHTS[idx].enemies[0]].name,
                       row, row);
            }
        }
        if (fr->elite) {
            printf("  the charm after fight %d:\n", after);
            for (int c = 0; c < CHARM_COUNT; c++)
                if (CHARMS[c].weight)
                    option(base, (Force){1, FORCE_CHARM, after, c}, CHARMS[c].name, after, after);
            option(base, (Force){1, FORCE_CHARM, after, SKIP_CARD}, "skip", after, after);
            printf("  the nap after fight %d:\n", after);
            option(base, (Force){1, FORCE_NAP, after, NOTHING}, "heal", after, after);
            for (int sl = 0; sl < 6; sl++) {
                snprintf(buf, sizeof buf, "level: +1 %s", SLOTS6[sl]);
                option(base, (Force){1, FORCE_NAP, after, sl}, buf, after, after);
            }
        }
    }
    FORCE.on = 0;
    free_runs(base, RUNS);
    return 0;
}

/* ---- cards: natural runs */

static int held_ever(const RunResult *r, int id, int charm) {
    for (int f = 0; f < r->nfights; f++) {
        const Kit *k = &r->kit_at[f];
        if (charm ? kit_holds(k, id) : memchr(k->items, id, 6) != NULL)
            return 1;
    }
    const Kit *k = &r->kit;
    return charm ? kit_holds(k, id) : memchr(k->items, id, 6) != NULL;
}

static int study_cards(void) {
    double secs;
    RunResult *r = run_batch(PLAYER, RUNS, SEED, JOBS, 0, &secs);
    Summary s;
    summary(r, RUNS, &s);
    printf("cards: %s, %d runs, won %.1f%% (%.0f s)\n", PLAYER_NAME[PLAYER], RUNS, 100 * s.win,
           secs);
    printf("face\tid\tslot\tweight\toffered_runs\toffers\tpicked\tpick_rate\theld_runs\t"
           "won_held\twon_not\tdelta\tplayed_share\n");
    for (int id = 0; id < FACE_COUNT; id++) {
        long offers = 0, picked = 0, offered_runs = 0, held = 0, held_won = 0, not_won = 0;
        long seen = 0, played = 0;
        for (int i = 0; i < RUNS; i++) {
            int any = 0;
            for (int f = 0; f < FIGHT_COUNT; f++)
                for (int k = 0; k < FACES_DRAWN; k++)
                    if (r[i].offer[f][k] == id) {
                        offers++;
                        any = 1;
                    }
            offered_runs += any;
            for (int j = 0; j < r[i].npicks; j++)
                picked += r[i].picks[j].card == id && r[i].picks[j].what == PK_ITEM;
            int h = held_ever(&r[i], id, 0);
            held += h;
            if (h)
                held_won += r[i].won;
            else
                not_won += r[i].won;
            seen += r[i].seen[id];
            played += r[i].played[id];
        }
        double wh = held ? (double)held_won / held : NAN, wn = (double)not_won / (RUNS - held);
        printf("%s\t%d\t%s\t%d\t%ld\t%ld\t%ld\t%.3f\t%ld\t%.3f\t%.3f\t%.3f\t%.3f\n",
               FACES[id].name, id, FACES[id].slot < 6 ? SLOTS6[FACES[id].slot] : "junk",
               FACES[id].weight, offered_runs, offers, picked,
               offers ? (double)picked / offers : NAN, held, wh, wn, wh - wn,
               seen ? (double)played / seen : NAN);
    }
    printf("charm\tid\tkind\tweight\toffered_runs\toffers\tpicked\tpick_rate\theld_runs\t"
           "won_held\twon_not\tdelta\n");
    for (int c = 0; c < CHARM_COUNT; c++) {
        long offers = 0, picked = 0, offered_runs = 0, held = 0, held_won = 0, not_won = 0;
        for (int i = 0; i < RUNS; i++) {
            int any = 0;
            for (int f = 0; f < FIGHT_COUNT; f++)
                for (int k = 0; k < CHARMS_DRAWN; k++)
                    if (r[i].charm_offer[f][k] == c) {
                        offers++;
                        any = 1;
                    }
            offered_runs += any;
            for (int j = 0; j < r[i].npicks; j++)
                picked += r[i].picks[j].what == PK_CHARM && r[i].picks[j].a == c;
            int h = held_ever(&r[i], c, 1);
            held += h;
            if (h)
                held_won += r[i].won;
            else
                not_won += r[i].won;
        }
        double wh = held ? (double)held_won / held : NAN, wn = (double)not_won / (RUNS - held);
        printf("%s\t%d\t%s\t%d\t%ld\t%ld\t%ld\t%.3f\t%ld\t%.3f\t%.3f\t%.3f\n", CHARMS[c].name, c,
               CHARMKIND_NAME[CHARMS[c].kind], CHARMS[c].weight, offered_runs, offers, picked,
               offers ? (double)picked / offers : NAN, held, wh, wn, wh - wn);
    }
    /* skips */
    long skips = 0, cards = 0, cskips = 0, charms = 0;
    for (int i = 0; i < RUNS; i++)
        for (int j = 0; j < r[i].npicks; j++) {
            const Pick *p = &r[i].picks[j];
            if (kind_of_pick(p) == FORCE_CARD) {
                cards++;
                skips += p->what == PK_SKIP;
            } else if (kind_of_pick(p) == FORCE_CHARM) {
                charms++;
                cskips += p->what == PK_SKIP;
            }
        }
    printf("skips: %.1f%% of card picks, %.1f%% of charm picks\n", 100.0 * skips / (cards ? cards : 1),
           100.0 * cskips / (charms ? charms : 1));
    print_report(PLAYER, r, RUNS, secs, 1);
    free_runs(r, RUNS);
    return 0;
}

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

static int study_luck(void) {
    RunResult *r = run_batch(PLAYER, RUNS, SEED, JOBS, 0, NULL);
    int wins = 0;
    for (int i = 0; i < RUNS; i++)
        wins += r[i].won;
    printf("luck: %s, %d runs, won %.1f%%\n", PLAYER_NAME[PLAYER], RUNS, 100.0 * wins / RUNS);
    /* the first three offers' learned lift (every run but the ones that die before), by fifth */
    for (int upto = 2; upto <= 6; upto += 4) {
        double *q = malloc(sizeof(double) * RUNS * 2);
        int m = 0;
        for (int i = 0; i < RUNS; i++) {
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
    free_runs(r, RUNS);
    /* the same seeds (the same dice stream) with other draws */
    if (SALTS > 1) {
        int n = RUNS / SALTS > 0 ? RUNS / SALTS : 1;
        double *p = calloc(n, sizeof(double));
        for (int k = 0; k < SALTS; k++) {
            OFFER_SALT = (uint64_t)k + 1;
            RunResult *x = run_batch(PLAYER, n, SEED, JOBS, 0, NULL);
            for (int i = 0; i < n; i++)
                p[i] += x[i].won;
            free_runs(x, n);
        }
        OFFER_SALT = 0;
        double mean = 0, within = 0, between = 0;
        int all = 0, none = 0;
        for (int i = 0; i < n; i++) {
            p[i] /= SALTS;
            mean += p[i];
        }
        mean /= n;
        for (int i = 0; i < n; i++) {
            within += p[i] * (1 - p[i]) * SALTS / (SALTS - 1.0);
            between += (p[i] - mean) * (p[i] - mean);
            all += p[i] == 1.0;
            none += p[i] == 0.0;
        }
        within /= n;
        between /= n;
        printf("  %d seeds, %d draws each (the dice the same stream): won %.1f%%\n", n, SALTS,
               100 * mean);
        printf("    seeds won every time %.1f%%, never %.1f%%\n", 100.0 * all / n, 100.0 * none / n);
        printf("    the variance of a run's result: %.3f within a seed (the draws), %.3f between "
               "seeds (the dice): the draws %.0f%% of it\n", within, between,
               100 * within / (within + between));
        free(p);
    }
    return 0;
}

/* ---- kits */

static int study_kits(void) {
    Mt rng;
    mt_seed(&rng, SEED * 7 + 3);
    int pool[6][FACE_COUNT], npool[6] = {0};
    for (int id = 0; id < FACE_COUNT; id++) {
        int s = FACES[id].slot;
        if (s < 6 && (FACES[id].weight || memchr(STARTING_ITEMS, id, 6)))
            pool[s][npool[s]++] = id;
    }
    double *w = malloc(sizeof(double) * (KITS + 1));
    Kit *kits = malloc(sizeof(Kit) * (KITS + 1));
    char buf[400];
    for (int k = 0; k <= KITS; k++) {
        Kit kit;
        kit_start(&kit);
        if (k > 0)
            for (int s = 0; s < 6; s++)
                kit.items[s] = (uint8_t)pool[s][mt_below(&rng, npool[s])];
        kits[k] = kit;
        START_KIT = &kits[k];
        RunResult *r = run_batch(PLAYER, RUNS, SEED, JOBS, 0, NULL);
        int won = 0;
        for (int i = 0; i < RUNS; i++)
            won += r[i].won;
        w[k] = (double)won / RUNS;
        printf("  %s %5.1f%%  %s\n", k ? "kit" : "the game's", 100 * w[k], kit_words(&kit, buf));
        fflush(stdout);
        free_runs(r, RUNS);
    }
    START_KIT = NULL;
    double *sorted = malloc(sizeof(double) * KITS);
    memcpy(sorted, w + 1, sizeof(double) * KITS);
    qsort(sorted, KITS, sizeof(double), by_double);
    double mean = 0;
    for (int k = 0; k < KITS; k++)
        mean += sorted[k];
    mean /= KITS;
    printf("kits: %d random kits, %d runs each: mean %.1f%%, min %.1f%%, p10 %.1f%%, median "
           "%.1f%%, p90 %.1f%%, max %.1f%%; the game's kit %.1f%%\n", KITS, RUNS, 100 * mean,
           100 * sorted[0], 100 * sorted[KITS / 10], 100 * sorted[KITS / 2],
           100 * sorted[KITS * 9 / 10], 100 * sorted[KITS - 1], 100 * w[0]);
    free(sorted);
    free(w);
    free(kits);
    return 0;
}

/* ---- domains */

static int study_domains(void) {
    RunResult *r = run_batch(PLAYER, RUNS, SEED, JOBS, 0, NULL);
    long got[D_COUNT] = {0}, won[D_COUNT] = {0}, any = 0, any_won = 0, none_won = 0, wins = 0;
    long by_fight[FIGHT_COUNT] = {0}, reach[FIGHT_COUNT] = {0};
    long faces_of[D_COUNT] = {0}, charms_of[D_COUNT] = {0};
    for (int id = 0; id < FACE_COUNT; id++)
        for (int d = 0; d < D_COUNT; d++)
            faces_of[d] += FACES[id].weight && (FACES[id].domains >> d & 1);
    for (int c = 0; c < CHARM_COUNT; c++)
        for (int d = 0; d < D_COUNT; d++)
            charms_of[d] += CHARMS[c].domains >> d & 1;
    for (int i = 0; i < RUNS; i++) {
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
    printf("domains: %s, %d runs, won %.1f%%\n", PLAYER_NAME[PLAYER], RUNS, 100.0 * wins / RUNS);
    printf("  kits with 3+ faces of one domain, walking into fight n (of the runs there):");
    for (int f = 0; f < FIGHT_COUNT; f++)
        printf(" %d:%.0f%%", f + 1, reach[f] ? 100.0 * by_fight[f] / reach[f] : 0);
    printf("\n  at the last fight a run reached: %.1f%% of runs (won %.1f%%); the others won "
           "%.1f%%\n", 100.0 * any / RUNS, any ? 100.0 * any_won / any : 0,
           RUNS - any ? 100.0 * none_won / (RUNS - any) : 0);
    printf("  domain\tfaces\tcharms\truns with 3+\twon\n");
    for (int d = 0; d < D_COUNT; d++)
        printf("  %s\t%ld\t%ld\t%.1f%%\t%s%.1f%%\n", DOMAIN_NAME[d], faces_of[d], charms_of[d],
               100.0 * got[d] / RUNS, got[d] < 30 ? "(few) " : "",
               got[d] ? 100.0 * won[d] / got[d] : 0);
    free_runs(r, RUNS);
    return 0;
}

int study_main(int argc, char **argv) {
    if (argc < 1) {
        fprintf(stderr, "--study NAME\n");
        return 2;
    }
    const char *name = argv[0], *only_parts = NULL;
    for (int i = 1; i < argc; i++) {
        const char *a = argv[i], *v = i + 1 < argc ? argv[i + 1] : "";
        if (!strcmp(a, "--player")) {
            PLAYER = player_by_name(v);
            i++;
        } else if (!strcmp(a, "--runs")) {
            RUNS = atoi(v);
            i++;
        } else if (!strcmp(a, "--seed")) {
            SEED = strtoull(v, 0, 10);
            i++;
        } else if (!strcmp(a, "--jobs")) {
            JOBS = atoi(v);
            i++;
        } else if (!strcmp(a, "--learned")) {
            learned_load(v);
            i++;
        } else if (!strcmp(a, "--learn")) {
            DRAFT.learn = atof(v);
            i++;
        } else if (!strcmp(a, "--out")) {
            OUT = fopen(v, "w");
            i++;
        } else if (!strcmp(a, "--table")) {
            TABLE = fopen(v, "w");
            i++;
        } else if (!strcmp(a, "--only")) {
            ONLY = atoi(v);
            i++;
        } else if (!strcmp(a, "--salts")) {
            SALTS = atoi(v);
            i++;
        } else if (!strcmp(a, "--kits")) {
            KITS = atoi(v);
            i++;
        } else if (!strcmp(a, "--parts")) {
            only_parts = v;
            i++;
        } else if (!strcmp(a, "--blunder")) {
            BLUNDER_PLAY = atof(v);
            i++;
        } else if (!strcmp(a, "--blunder-pick")) {
            BLUNDER_PICK = atof(v);
            i++;
        } else {
            fprintf(stderr, "unknown study argument: %s\n", a);
            return 2;
        }
    }
    int rc;
    if (!strcmp(name, "picks"))
        rc = study_picks();
    else if (!strcmp(name, "cards"))
        rc = study_cards();
    else if (!strcmp(name, "luck"))
        rc = study_luck();
    else if (!strcmp(name, "kits"))
        rc = study_kits();
    else if (!strcmp(name, "domains"))
        rc = study_domains();
    else if (!strcmp(name, "broken"))
        rc = study_broken(PLAYER, RUNS, SEED);
    else if (!strcmp(name, "lift"))
        rc = study_lift(PLAYER, RUNS, SEED, only_parts);
    else {
        fprintf(stderr, "no study %s\n", name);
        return 2;
    }
    if (OUT)
        fclose(OUT);
    if (TABLE)
        fclose(TABLE);
    return rc;
}
