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

static void forced_line(int player, int runs, uint64_t seed, int jobs, const char *what,
                        double share) {
    RunResult *r = run_batch(player, runs, seed, jobs, 0, NULL);
    Summary s;
    summary(r, runs, &s);
    double boss = 0;
    int nb = 0;
    for (int i = 0; i < runs; i++) {
        if (r[i].nfights == FIGHT_COUNT) {
            boss += r[i].fights[FIGHT_COUNT - 1].hp_in;
            nb++;
        }
    }
    printf("    %-22s won %5.1f%%  hp at the boss %4.1f  end %4.1f  (taken %3.0f%%)\n", what,
           100 * s.win, nb ? boss / nb : 0, s.hp_end, 100 * share);
    if (STUDY_OUT)
        fprintf(STUDY_OUT, "%d %d %d %.4f\n", FORCE.kind, FORCE.after, FORCE.a, s.win);
    fflush(stdout);
    free(r);
}

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

int STUDY_ONLY = 0; /* --only N: just the picks after fight N */

int study_picks(int player, int runs, uint64_t seed, int jobs) {
    double secs;
    RunResult *base = run_batch(player, runs, seed, jobs, 0, &secs);
    Summary s;
    summary(base, runs, &s);
    printf("%s, %d runs a line, unforced: won %.1f%% (%.0f s)\n", PLAYER_NAME[player], runs,
           100 * s.win, secs);
    char buf[64];
    for (int row = 0; row < FIGHT_ROWS; row++) {
        if (row == FIGHT_COUNT - 1)
            continue; /* the boss: no reward */
        int after = row >= FIGHT_COUNT ? FIGHT_COUNT - 1 : row + 1;
        const FightRow *fr = &FIGHTS[row];
        if (STUDY_ONLY && after != STUDY_ONLY)
            continue;
        if (fr->other != NOTHING) {
            printf("  door at fight %d:\n", row + 1);
            for (int d = 0; d < 2; d++) {
                int idx = d ? fr->other : row;
                FORCE = (Force){1, FORCE_DOOR, row, idx};
                forced_line(player, runs, seed, jobs, KINDS[FIGHTS[idx].enemies[0]].name,
                            share_of(base, runs, FORCE_DOOR, row, idx));
            }
        }
        printf("  after fight %d%s:\n", after, row >= FIGHT_COUNT ? " (the other door)" : "");
        /* a door's own cards: that door taken too */
        DOOR_FORCE.on = 0;
        for (int d = 0; d < FIGHT_ROWS; d++)
            if (FIGHTS[d].other != NOTHING && (d == row || FIGHTS[d].other == row))
                DOOR_FORCE = (Force){1, FORCE_DOOR, d, row};
        for (int i = 0; i < 3; i++) {
            int c = fr->cards[i];
            FORCE = (Force){1, FORCE_CARD, after, c};
            forced_line(player, runs, seed, jobs, card_name(c, buf),
                        share_of(base, runs, FORCE_CARD, after, c));
        }
        for (int i = 0; i < fr->ncharms; i++) {
            int c = fr->charms[i];
            FORCE = (Force){1, FORCE_CHARM, after, c};
            snprintf(buf, sizeof buf, "charm %s", CHARMS[c].name);
            forced_line(player, runs, seed, jobs, buf, share_of(base, runs, FORCE_CHARM, after, c));
        }
        if (fr->nap) {
            FORCE = (Force){1, FORCE_NAP, after, NOTHING};
            forced_line(player, runs, seed, jobs, "nap: heal",
                        share_of(base, runs, FORCE_NAP, after, NOTHING));
            for (int sl = 0; sl < 6; sl++) {
                FORCE = (Force){1, FORCE_NAP, after, sl};
                snprintf(buf, sizeof buf, "nap: +1 %s", SLOT_UP[sl]);
                forced_line(player, runs, seed, jobs, buf, share_of(base, runs, FORCE_NAP, after, sl));
            }
        }
    }
    FORCE.on = 0;
    DOOR_FORCE.on = 0;
    free(base);
    return 0;
}
