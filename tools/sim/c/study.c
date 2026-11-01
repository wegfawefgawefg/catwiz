/* The pick study: every choice between fights forced in turn (each card after each fight,
   each charm, the nap's heal and levels, both doors), the rest of the run drafted as the
   player would, the same seeds for every option. It says what each option is worth when
   taken (the run's win rate, hit points at the end of won runs) beside how often the player
   takes it unforced: a card that loses its pick by a lot needs a reason, a card that always
   wins it is too good or has weak rivals.

     ./catwiz-sim --study picks --player search --runs 256 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "combos.h"
#include "report.h"

FILE *STUDY_OUT = NULL; /* --out: each forced option's win rate, for the draft (--learned) */

/* how often the unforced player took this option at this point (of the runs that got there) */
static double share_of(const RunResult *r, int n, int kind, int after, int a) {
    int got = 0, took = 0;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < r[i].npicks; j++) {
            const Pick *p = &r[i].picks[j];
            int k = p->what == PK_DOOR ? FORCE_DOOR : p->what == PK_CHARM ? FORCE_CHARM
                  : (p->what == PK_NAP_HEAL || p->what == PK_NAP_LEVEL) ? FORCE_NAP
                  : FORCE_CARD;
            if (k != kind || p->after != after)
                continue;
            got++;
            took += p->card == a;
        }
    }
    return got ? (double)took / got : 0;
}

static const char *const SLOT_UP[6] = {"WAND", "FLUFF", "STAR", "BOOK", "CURSE", "TRICK"};

static const char *card_name(int c, char *buf) {
    if (c >= UP_CARD)
        sprintf(buf, "+1 %s", SLOT_UP[c - UP_CARD]);
    else
        sprintf(buf, "%s", ITEMS[c].name);
    return buf;
}

int STUDY_ONLY = 0; /* --only N: just the picks after fight N (a phase's first) */

static void out_range(int kind, int lo, int hi, int a, double win) {
    for (int f = lo; f <= hi && STUDY_OUT; f++)
        fprintf(STUDY_OUT, "%d %d %d %.4f\n", kind, f, a, win);
}

/* one option forced: its line, and its learned value for the fights lo-hi */
static void option(int player, int runs, uint64_t seed, int jobs, const RunResult *base,
                   Force fo, const char *what, int lo, int hi) {
    FORCE = fo;
    FILE *keep = STUDY_OUT;
    STUDY_OUT = NULL; /* forced_line would write one fight only */
    RunResult *r = run_batch(player, runs, seed, jobs, 0, NULL);
    Summary s;
    summary(r, runs, &s);
    double boss = 0;
    int nb = 0;
    for (int i = 0; i < runs; i++)
        if (r[i].nfights == FIGHT_COUNT) {
            boss += r[i].fights[FIGHT_COUNT - 1].hp_in;
            nb++;
        }
    printf("    %-22s won %5.1f%%  hp at the boss %4.1f  end %4.1f  (taken unforced %3.0f%%)\n",
           what, 100 * s.win, nb ? boss / nb : 0, s.hp_end,
           100 * share_of(base, runs, fo.kind, fo.after, fo.a));
    fflush(stdout);
    STUDY_OUT = keep;
    out_range(fo.kind, lo, hi, fo.a, s.win);
    free(r);
}

int study_picks(int player, int runs, uint64_t seed, int jobs) {
    double secs;
    RunResult *base = run_batch(player, runs, seed, jobs, 0, &secs);
    Summary s;
    summary(base, runs, &s);
    printf("%s, %d runs a line, unforced: won %.1f%% (%.0f s)\n", PLAYER_NAME[player], runs,
           100 * s.win, secs);
    char buf[64];
    /* cards: each slipped into the offer at the first pick it can come in each third of the
       run, and taken; its value stands for that third */
    static const int third[3][2] = {{1, 3}, {4, 6}, {7, FIGHT_COUNT - 1}};
    for (int t = 0; t < 3; t++) {
        if (STUDY_ONLY && STUDY_ONLY != third[t][0])
            continue;
        printf("  cards after fights %d-%d:\n", third[t][0], third[t][1]);
        for (int i = 0; i < OFFER_COUNT; i++) {
            if (!OFFERS[i].weight)
                continue; /* not in the pool */
            int at = OFFERS[i].from > third[t][0] ? OFFERS[i].from : third[t][0];
            if (at > third[t][1])
                continue;
            snprintf(buf, sizeof buf, "%s (at %d)", card_name(OFFERS[i].what, buf + 40), at);
            option(player, runs, seed, jobs, base, (Force){1, FORCE_CARD, at, OFFERS[i].what},
                   buf, at, third[t][1]);
        }
    }
    /* after each elite: the rest's heal or dream, the charm; the doors */
    for (int row = 0; row < FIGHT_COUNT - 1; row++) {
        const FightRow *fr = &FIGHTS[row];
        int after = row + 1;
        if (STUDY_ONLY && STUDY_ONLY != after)
            continue;
        if (fr->other != NOTHING) {
            printf("  door at fight %d:\n", after);
            for (int d = 0; d < 2; d++) {
                int idx = d ? fr->other : row;
                option(player, runs, seed, jobs, base, (Force){1, FORCE_DOOR, row, idx},
                       KINDS[FIGHTS[idx].enemies[0]].name, row, row);
            }
        }
        if (fr->nap) {
            printf("  the rest after fight %d:\n", after);
            option(player, runs, seed, jobs, base, (Force){1, FORCE_NAP, after, NOTHING}, "heal",
                   after, after);
            for (int sl = 0; sl < 6; sl++) {
                snprintf(buf, sizeof buf, "dream: +1 %s", SLOT_UP[sl]);
                option(player, runs, seed, jobs, base, (Force){1, FORCE_NAP, after, sl}, buf,
                       after, after);
            }
        }
        if (fr->charm) {
            printf("  the charm after fight %d:\n", after);
            for (int i = 0; i < CHARM_OFFER_COUNT; i++) {
                if (CHARM_OFFERS[i].from > after)
                    continue;
                int c = CHARM_OFFERS[i].what;
                option(player, runs, seed, jobs, base, (Force){1, FORCE_CHARM, after, c},
                       CHARMS[c].name, after, after);
            }
        }
    }
    FORCE.on = 0;
    free(base);
    return 0;
}

/* offer luck (--study luck): how the runs did by what the offers brought them. Engines: the
   trick and wishing cards (times two, copycat, knead, wishing star, +1 trick) */
static int is_engine(int c) {
    if (c == UP_CARD + 5)
        return 1;
    if (c >= ITEM_COUNT)
        return 0;
    const char *n = ITEMS[c].name;
    return !strcmp(n, "TIMES TWO") || !strcmp(n, "COPYCAT") || !strcmp(n, "KNEAD") ||
           !strcmp(n, "WISHING STAR");
}

int study_luck(int player, int runs, uint64_t seed, int jobs) {
    RunResult *r = run_batch(player, runs, seed, jobs, 0, NULL);
    int won[8] = {0}, n[8] = {0}, all = 0;
    for (int i = 0; i < runs; i++) {
        int e = 0;
        for (int f = 0; f < 6; f++)
            for (int k = 0; k < 3; k++)
                e += r[i].offer[f][k] != NOTHING && is_engine(r[i].offer[f][k]);
        if (e > 4)
            e = 4;
        n[e]++;
        won[e] += r[i].won;
        all += r[i].won;
    }
    printf("luck: %s, %d runs, won %.1f%%\n", PLAYER_NAME[player], runs, 100.0 * all / runs);
    printf("  engine cards offered in the first six picks: runs, won\n");
    for (int e = 0; e <= 4; e++)
        if (n[e])
            printf("    %d%s: %4.1f%% of runs, won %.1f%%\n", e, e == 4 ? " or more" : "",
                   100.0 * n[e] / runs, 100.0 * won[e] / n[e]);
    /* batches of 100 runs: how far a small sample's win rate swings */
    double lo = 1, hi = 0;
    for (int b = 0; b + 100 <= runs; b += 100) {
        int w = 0;
        for (int i = b; i < b + 100; i++)
            w += r[i].won;
        lo = w / 100.0 < lo ? w / 100.0 : lo;
        hi = w / 100.0 > hi ? w / 100.0 : hi;
    }
    printf("  batches of 100 runs won %.0f%% to %.0f%%\n", 100 * lo, 100 * hi);
    free(r);
    return 0;
}

/* boost targets (--study boosts): which faces take the waiting +1 and x2, what a boost adds to
   them, and how the runs do whose main target a face was */
int study_boosts(int player, int runs, uint64_t seed, int jobs) {
    RunResult *r = run_batch(player, runs, seed, jobs, 0, NULL);
    double total = 0;
    long n[ITEM_COUNT] = {0}, gain[ITEM_COUNT] = {0}, top[ITEM_COUNT] = {0}, topwon[ITEM_COUNT] = {0};
    int none = 0, nonewon = 0;
    for (int i = 0; i < runs; i++) {
        int best = -1;
        for (int row = 0; row < ITEM_COUNT; row++) {
            n[row] += r[i].boosts[row];
            gain[row] += r[i].boost_gain[row];
            total += r[i].boosts[row];
            if (r[i].boosts[row] && (best < 0 || r[i].boosts[row] > r[i].boosts[best]))
                best = row;
        }
        if (best < 0) {
            none++;
            nonewon += r[i].won;
        } else {
            top[best]++;
            topwon[best] += r[i].won;
        }
    }
    printf("boosts: %s, %d runs, %.1f boosts a run\n", PLAYER_NAME[player], runs, total / runs);
    printf("  face: share of the boosts, what a boost added, runs whose main target it was (won)\n");
    for (int k = 0; k < ITEM_COUNT; k++) {
        int row = -1;
        for (int j = 0; j < ITEM_COUNT; j++) /* the next most boosted, a simple pick */
            if (n[j] >= 0 && (row < 0 || n[j] > n[row]))
                row = j;
        if (row < 0 || n[row] <= 0)
            break;
        printf("    %-16s %5.1f%%  +%4.1f  %5.1f%% of runs (won %5.1f%%)\n", ITEMS[row].name,
               100.0 * n[row] / total, (double)gain[row] / n[row], 100.0 * top[row] / runs,
               top[row] ? 100.0 * topwon[row] / top[row] : 0);
        n[row] = -1;
    }
    printf("    no boost taken: %.1f%% of runs (won %.1f%%)\n", 100.0 * none / runs,
           none ? 100.0 * nonewon / none : 0);
    free(r);
    return 0;
}

/* kittens (--study kittens): the most kittens a run had at once (median, top tenth, top
   hundredth), the win rate by that, and the runs that held each kitten piece */
static int by_int(const void *a, const void *b) {
    return *(const int *)a - *(const int *)b;
}

int study_kittens(int player, int runs, uint64_t seed, int jobs) {
    RunResult *r = run_batch(player, runs, seed, jobs, 0, NULL);
    int *peak = malloc(sizeof(int) * runs), won = 0;
    static const int edge[] = {0, 1, 5, 10, 20, 40, 1000};
    int bn[6] = {0}, bw[6] = {0};
    for (int i = 0; i < runs; i++) {
        peak[i] = r[i].kitten_peak;
        won += r[i].won;
        for (int k = 0; k < 6; k++)
            if (peak[i] >= edge[k] && peak[i] < edge[k + 1]) {
                bn[k]++;
                bw[k] += r[i].won;
            }
    }
    qsort(peak, runs, sizeof(int), by_int);
    printf("kittens: %s, %d runs, won %.1f%%; KITTEN_HIT %d, KITTENS_MOST %d\n",
           PLAYER_NAME[player], runs, 100.0 * won / runs, KITTEN_HIT, KITTENS_MOST);
    printf("  most kittens at once in a run: median %d, top tenth %d, top hundredth %d, most %d\n",
           peak[runs / 2], peak[runs * 9 / 10], peak[runs * 99 / 100], peak[runs - 1]);
    for (int k = 0; k < 6; k++)
        if (bn[k])
            printf("    %d-%d kittens: %5.1f%% of runs, won %5.1f%%\n", edge[k], edge[k + 1] - 1,
                   100.0 * bn[k] / runs, 100.0 * bw[k] / bn[k]);
    static const char *const piece[] = {"MEOWCRONOMICON", "KITTEN CANNON", "FEATHER TOY", "CATNIP",
                                         "CARDBOARD BOX", "LITTER STAR", "IF IT FITS"};
    for (int p = 0; p < 7; p++) {
        int row = -1;
        for (int q = 0; q < ITEM_COUNT; q++)
            if (!strcmp(ITEMS[q].name, piece[p]))
                row = q;
        if (row < 0)
            continue;
        int held = 0, hw = 0;
        for (int i = 0; i < runs; i++) {
            int h = 0;
            for (int f = 0; f < r[i].nfights; f++)
                h |= r[i].kit_at[f].items[ITEMS[row].slot] == row;
            held += h;
            hw += h && r[i].won;
        }
        int offered = 0, taken = 0;
        for (int i = 0; i < runs; i++)
            for (int j = 0; j < r[i].npicks; j++) {
                const Pick *pk = &r[i].picks[j];
                if (pk->what != PK_ITEM && pk->what != PK_LEVEL)
                    continue;
                int f = pk->after;
                if (f < 1 || f > FIGHT_COUNT)
                    continue;
                int in = 0;
                for (int k = 0; k < 3; k++)
                    in |= r[i].offer[f - 1][k] == row;
                offered += in;
                taken += in && pk->card == row;
            }
        printf("  runs that held %s: %.1f%%, won %.1f%%; taken %.0f%% of the %d times offered\n",
               piece[p], 100.0 * held / runs, held ? 100.0 * hw / held : 0,
               offered ? 100.0 * taken / offered : 0, offered);
    }
    for (int c = 0; c < CHARM_COUNT; c++) {
        if (CHARMS[c].kind != K_mother && CHARMS[c].kind != K_mittens)
            continue;
        int held = 0, hw = 0;
        for (int i = 0; i < runs; i++) {
            int h = 0;
            for (int j = 0; j < r[i].kit.ncharms; j++)
                h |= r[i].kit.charms[j] == c;
            held += h;
            hw += h && r[i].won;
        }
        printf("  runs that took %s: %.1f%%, won %.1f%%\n", CHARMS[c].name, 100.0 * held / runs,
               held ? 100.0 * hw / held : 0);
    }
    free(peak);
    free(r);
    return 0;
}

/* cards (--study cards): every card of the pool: taken when offered, the share of runs that
   held it (a +1 card: took it) and how they did; Times Two by its level; the stalls */
int study_cards(int player, int runs, uint64_t seed, int jobs) {
    RunResult *r = run_batch(player, runs, seed, jobs, 0, NULL);
    int won = 0, stall = 0;
    for (int i = 0; i < runs; i++) {
        won += r[i].won;
        int s = 0;
        for (int f = 0; f < r[i].nfights; f++)
            s |= r[i].fights[f].turns > 15;
        stall += s;
    }
    printf("cards: %s, %d runs, won %.1f%%; runs with a fight over 15 turns %.1f%%\n",
           PLAYER_NAME[player], runs, 100.0 * won / runs, 100.0 * stall / runs);
    printf("  card: taken when offered (times offered), runs that held it (won)\n");
    char buf[64];
    for (int o = 0; o < OFFER_COUNT; o++) {
        int c = OFFERS[o].what;
        if (!OFFERS[o].weight)
            continue;
        int offered = 0, taken = 0, held = 0, hw = 0;
        for (int i = 0; i < runs; i++) {
            int h = 0;
            for (int j = 0; j < r[i].npicks; j++) {
                const Pick *pk = &r[i].picks[j];
                if (pk->what != PK_ITEM && pk->what != PK_LEVEL)
                    continue;
                int f = pk->after;
                if (f < 1 || f > FIGHT_COUNT)
                    continue;
                int in = 0;
                for (int k = 0; k < 3; k++)
                    in |= r[i].offer[f - 1][k] == c;
                offered += in;
                taken += in && pk->card == c;
                h |= in && pk->card == c;
            }
            if (c < ITEM_COUNT)
                for (int f = 0; f < r[i].nfights; f++)
                    h |= r[i].kit_at[f].items[ITEMS[c].slot] == c;
            held += h;
            hw += h && r[i].won;
        }
        if (c >= UP_CARD)
            snprintf(buf, sizeof buf, "+1 %s", (const char *[]){"WAND", "FLUFF", "STAR", "BOOK",
                                                                "CURSE", "TRICK"}[c - UP_CARD]);
        else
            snprintf(buf, sizeof buf, "%s", ITEMS[c].name);
        printf("    %-16s %3.0f%% (%5d)  %5.1f%% of runs (won %5.1f%%)\n", buf,
               offered ? 100.0 * taken / offered : 0, offered, 100.0 * held / runs,
               held ? 100.0 * hw / held : 0);
    }
    int times = -1;
    for (int q = 0; q < ITEM_COUNT; q++)
        if (!strcmp(ITEMS[q].name, "TIMES TWO"))
            times = q;
    for (int lv = 0; times >= 0 && lv <= ITEM_MOST; lv++) {
        int n = 0, w = 0;
        for (int i = 0; i < runs; i++) {
            int h = 0;
            for (int f = 0; f < r[i].nfights; f++)
                h |= r[i].kit_at[f].items[S_trick] == times && r[i].kit_at[f].level[S_trick] >= lv;
            n += h;
            w += h && r[i].won;
        }
        printf("  runs that held Times Two at x%d or more: %.1f%% (won %.1f%%)\n",
               ITEMS[times].amount + lv * ITEMS[times].step, 100.0 * n / runs,
               n ? 100.0 * w / n : 0);
    }
    free(r);
    return 0;
}
