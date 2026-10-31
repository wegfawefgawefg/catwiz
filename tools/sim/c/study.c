/* The pick study: every choice between fights forced in turn (each card after each fight,
   each charm, the nap's heal and levels, both doors), the rest of the run drafted as the
   player would, the same seeds for every option. It says what each option is worth when
   taken (the run's win rate, hit points at the end of won runs) beside how often the player
   takes it unforced: a card that loses its pick by a lot needs a reason, a card that always
   wins it is too good or has weak rivals.

     ./catwiz-sim --study picks --player search --runs 256 */
#include <stdio.h>
#include <stdlib.h>

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
