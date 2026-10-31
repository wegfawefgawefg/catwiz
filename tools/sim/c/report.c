/* The numbers a batch of runs gives (tools/sim/report.py): per fight (reached, won, hit points
   in, lost and healed, turns), how far runs get, what the winners took and what faces were
   played when rolled. */
#include <stdio.h>
#include <stdlib.h>

#include "report.h"

static int pick_key(const Pick *p) {
    return p->what * 256 + p->a;
}

static int by_count(const void *a, const void *b) {
    const int *x = a, *y = b;
    if (x[1] != y[1])
        return y[1] - x[1];
    return x[0] - y[0];
}

void summary(const RunResult *r, int n, Summary *s) {
    memset(s, 0, sizeof *s);
    for (int f = 0; f < FIGHT_COUNT; f++) {
        int here = 0, won = 0, maxt = 0;
        double hp_in = 0, lost = 0, healed = 0, net = 0, turns = 0;
        for (int i = 0; i < n; i++) {
            if (r[i].nfights <= f)
                continue;
            const FightResult *x = &r[i].fights[f];
            here++;
            hp_in += x->hp_in;
            if (!x->won)
                continue;
            won++;
            lost += x->lost;
            healed += x->healed;
            net += x->hp_in - x->hp_out;
            turns += x->turns;
            if (x->turns > maxt)
                maxt = x->turns;
        }
        FightRowSum *row = &s->rows[f];
        row->reached = (double)here / n;
        row->won = here ? (double)won / here : 0;
        row->hp_in = here ? hp_in / here : 0;
        int k = won > 0 ? won : 1;
        row->lost = lost / k;
        row->healed = healed / k;
        row->net = net / k;
        row->turns = turns / k;
        row->turns_max = maxt;
    }
    int wins = 0;
    double hp_end = 0;
    for (int i = 0; i < n; i++) {
        if (r[i].won) {
            wins++;
            hp_end += r[i].fights[r[i].nfights - 1].hp_out;
        } else {
            s->deaths[r[i].nfights]++;
        }
    }
    s->win = (double)wins / n;
    s->hp_end = wins ? hp_end / wins : 0;
}

/* the share of runs (won ones, or all when none won) that took each pick; out[k] = {key,
   count}, sorted, gives the number of kinds */
static int pick_shares(const RunResult *r, int n, int only_won, int after, int (*out)[2]) {
    static _Thread_local int count[6 * 256];
    memset(count, 0, sizeof count);
    for (int i = 0; i < n; i++) {
        if (only_won && !r[i].won)
            continue;
        uint8_t seen[6 * 256] = {0};
        for (int j = 0; j < r[i].npicks; j++) {
            const Pick *p = &r[i].picks[j];
            if (p->what == PK_DOOR || (after && p->after != after))
                continue;
            int k = pick_key(p);
            if (!seen[k]) {
                seen[k] = 1;
                count[k]++;
            }
        }
    }
    int m = 0;
    for (int k = 0; k < 6 * 256; k++) {
        if (count[k]) {
            out[m][0] = k;
            out[m][1] = count[k];
            m++;
        }
    }
    qsort(out, m, sizeof out[0], by_count);
    return m;
}

void print_report(int player, const RunResult *r, int n, double seconds, int by_fight) {
    Summary s;
    summary(r, n, &s);
    printf("\n%s: %d runs in %.1f s (%.0f runs/s)\n", PLAYER_NAME[player], n, seconds,
           n / (seconds > 1e-9 ? seconds : 1e-9));
    printf("fight  reached  won    hp in  hp lost  healed  net  turns (max)\n");
    for (int f = 0; f < FIGHT_COUNT; f++) {
        const FightRowSum *row = &s.rows[f];
        if (row->reached == 0) {
            printf("%5d  -\n", f + 1);
            continue;
        }
        printf("%5d  %6.0f%%  %4.0f%%  %5.1f  %7.1f  %6.1f  %4.1f  %5.1f (%d)\n", f + 1,
               100 * row->reached, 100 * row->won, row->hp_in, row->lost, row->healed,
               row->net, row->turns, row->turns_max);
    }
    printf("runs won: %.1f%%, hp at the end of won runs %.1f\n", 100 * s.win, s.hp_end);
    printf("runs lost in fight:");
    for (int f = 0; f <= FIGHT_COUNT; f++)
        if (s.deaths[f])
            printf(" %d: %.1f%%", f, 100.0 * s.deaths[f] / n);
    printf("\n");
    int wins = 0;
    for (int i = 0; i < n; i++)
        wins += r[i].won;
    int only_won = wins > 0;
    int base = only_won ? wins : n;
    int (*sh)[2] = malloc(sizeof(int[2]) * 6 * 256);
    int m = pick_shares(r, n, only_won, 0, sh);
    char buf[80];
    printf("taken in %s runs (share of runs):\n", only_won ? "won" : "all");
    for (int i = 0; i < m && i < 24; i++) {
        Pick p = {(uint8_t)(sh[i][0] / 256), (uint8_t)(sh[i][0] % 256), 0};
        printf("  %3.0f%%  %s\n", 100.0 * sh[i][1] / base, pick_words(&p, buf));
    }
    if (by_fight) {
        printf("taken, fight by fight (%s runs):\n", only_won ? "won" : "all");
        for (int f = 1; f < FIGHT_COUNT; f++) {
            m = pick_shares(r, n, only_won, f, sh);
            if (!m)
                continue;
            printf("  after %2d:", f);
            for (int i = 0; i < m && i < 8; i++) {
                Pick p = {(uint8_t)(sh[i][0] / 256), (uint8_t)(sh[i][0] % 256), 0};
                printf("%s %s %.0f%%", i ? "," : "", pick_words(&p, buf),
                       100.0 * sh[i][1] / base);
            }
            printf("\n");
        }
    }
    free(sh);
    int doors[FIGHT_ROWS] = {0}, nd = 0;
    for (int i = 0; i < n; i++)
        for (int j = 0; j < r[i].npicks; j++)
            if (r[i].picks[j].what == PK_DOOR) {
                doors[r[i].picks[j].a]++;
                nd++;
            }
    if (nd) {
        printf("doors taken (all runs that got there):");
        for (int f = 0; f < FIGHT_ROWS; f++)
            if (doors[f])
                printf(" %s %.0f%%", KINDS[FIGHTS[f].enemies[0]].name, 100.0 * doors[f] / nd);
        printf("\n");
    }
    printf("faces played when rolled:\n");
    int order[ITEM_COUNT];
    double share[ITEM_COUNT];
    long seen[ITEM_COUNT], played[ITEM_COUNT];
    for (int row = 0; row < ITEM_COUNT; row++) {
        seen[row] = played[row] = 0;
        for (int i = 0; i < n; i++) {
            seen[row] += r[i].seen[row];
            played[row] += r[i].played[row];
        }
        share[row] = seen[row] ? (double)played[row] / seen[row] : -1;
        int j = row;
        while (j > 0 && share[order[j - 1]] < share[row]) {
            order[j] = order[j - 1];
            j--;
        }
        order[j] = row;
    }
    for (int i = 0; i < ITEM_COUNT; i++) {
        int row = order[i];
        if (seen[row])
            printf("  %3.0f%%  %s (%ld)\n", 100 * share[row], ITEMS[row].name, seen[row]);
    }
}
