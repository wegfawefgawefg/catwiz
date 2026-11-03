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
static int ONLY = 0;
int S_PLAYER = P_SEARCH, S_RUNS = 256, S_SALTS = 4, S_KITS = 64;
uint64_t S_SEED = 1;
#define PLAYER S_PLAYER
#define RUNS S_RUNS
#define SEED S_SEED
#define SALTS S_SALTS
#define KITS S_KITS

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
