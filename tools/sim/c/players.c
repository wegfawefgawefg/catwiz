/* The reference players, ports of tools/sim/policy.py (same choices, same random numbers):

   random  plays a random playable die on a random enemy until none is left; re-rolls or
           ends at random when stuck. A player mashing keys.
   greedy  each step plays the one die and target that leaves the best position after the
           enemies' shown moves; ends when no die helps; re-rolls when stuck.
   strong  searches the whole turn (every order of dice and targets, merged where they lead
           to the same position, at most NODE_CAP positions), then the enemies' moves; and
           whether to play the plan's first few dice and re-roll the rest, by sampling the
           re-roll SAMPLES times. */
#include <stdlib.h>

#include "players.h"
#include "tell.h"

const char *const PLAYER_NAME[P_COUNT] = {"random", "greedy", "strong", "search"};

/* the distinct plays now: one slot for each face shown, each enemy for a face that picks */
int options(const Battle *b, Play *out) {
    int n = 0;
    uint8_t seen[ITEM_COUNT] = {0};
    for (int s = 0; s < b->hand_n; s++) {
        if (!b_can_play(b, s))
            continue;
        int row = b->hand[s];
        if (seen[row])
            continue;
        seen[row] = 1;
        if (ITEMS[row].aim == A_foe) {
            for (int t = 1; t < ACTORS; t++) {
                if (b->alive[t]) {
                    out[n].s = (uint8_t)s;
                    out[n].t = (uint8_t)t;
                    n++;
                }
            }
        } else {
            out[n].s = (uint8_t)s;
            out[n].t = NOTHING;
            n++;
        }
    }
    return n;
}

static void random_turn(Player *p, Battle *b) {
    while (!b_turn_over(b)) {
        int slots[MAX_HAND], n = 0;
        for (int s = 0; s < b->hand_n; s++)
            if (b_can_play(b, s))
                slots[n++] = s;
        if (n) {
            int s = slots[mt_below(p->rng, n)];
            int live[ACTORS], nl = 0;
            for (int t = 1; t < ACTORS; t++)
                if (b->alive[t])
                    live[nl++] = t;
            int t = live[mt_below(p->rng, nl)];
            b_play(b, s, t);
            continue;
        }
        if (b->rerolls > 0 && mt_random(p->rng) < 0.5) {
            b_reroll(b);
            continue;
        }
        break;
    }
}

static void greedy_turn(Player *p, Battle *b) {
    (void)p;
    while (!b_turn_over(b)) {
        double best = judge_after_turn(b);
        int pick = -1;
        Play opts[24];
        int n = options(b, opts);
        for (int i = 0; i < n; i++) {
            Battle c = *b;
            c.tell = NULL;
            b_play(&c, opts[i].s, opts[i].t);
            double v = judge_after_turn(&c);
            if (v > best + 1e-9) {
                best = v;
                pick = i;
            }
        }
        if (pick >= 0) {
            b_play(b, opts[pick].s, opts[pick].t);
            continue;
        }
        if (b->rerolls > 0 && b_any_unplayed(b)) {
            b_reroll(b);
            continue;
        }
        break;
    }
}

/* ---- strong: the turn search with a memo of positions (policy.py Strong.key) */

#define SAMPLES 6
#define NODE_CAP 1500
#define MEMO_SIZE 8192

typedef struct {
    uint8_t played[MAX_HAND];
    uint8_t alive[ACTORS], kind[ACTORS];
    uint8_t held[MAX_HAND];
    int32_t hp[ACTORS];
    int32_t st[ACTORS][NS];
} Key;

typedef struct {
    Key key;
    uint32_t gen;
    double value;
    uint8_t nplan;
    Play plan[MAX_HAND];
} Entry;

typedef struct {
    Entry *e;
    uint32_t gen;
    int count;
} Memo;

static _Thread_local Memo memo;

static void make_key(const Battle *b, Key *k) {
    memset(k, 0, sizeof *k);
    memcpy(k->played, b->played, b->hand_n);
    memcpy(k->alive, b->alive, ACTORS);
    memcpy(k->kind, b->kind, ACTORS);
    memcpy(k->held, b->held, b->ndice);
    memcpy(k->hp, b->hp, sizeof k->hp);
    memcpy(k->st, b->st, sizeof k->st);
}

static uint64_t hash_key(const Key *k) {
    const uint8_t *p = (const uint8_t *)k;
    uint64_t h = 1469598103934665603ull;
    for (size_t i = 0; i < sizeof *k; i++) {
        h ^= p[i];
        h *= 1099511628211ull;
    }
    return h;
}

static void memo_clear(void) {
    if (!memo.e)
        memo.e = calloc(MEMO_SIZE, sizeof(Entry));
    memo.gen++;
    memo.count = 0;
}

/* the entry for key k: found (its gen is now) or the empty one to fill */
static Entry *memo_find(const Key *k) {
    uint64_t h = hash_key(k);
    for (uint32_t i = (uint32_t)h & (MEMO_SIZE - 1);; i = (i + 1) & (MEMO_SIZE - 1)) {
        Entry *e = &memo.e[i];
        if (e->gen != memo.gen)
            return e;
        if (memcmp(&e->key, k, sizeof *k) == 0)
            return e;
    }
}

/* the best value of the turn from b with no more re-rolls, and its plays */
static Entry *strong_search(const Battle *b) {
    Key k;
    make_key(b, &k);
    Entry *e = memo_find(&k);
    if (e->gen == memo.gen)
        return e;
    double best = judge_after_turn(b);
    Play plan[MAX_HAND];
    int nplan = 0;
    if (b->result == R_NONE && memo.count < NODE_CAP) {
        Play opts[24];
        int n = options(b, opts);
        for (int i = 0; i < n; i++) {
            Battle c = *b;
            c.tell = NULL;
            b_play(&c, opts[i].s, opts[i].t);
            Entry *ce = strong_search(&c);
            if (ce->value > best + 1e-9) {
                best = ce->value;
                plan[0] = opts[i];
                memcpy(plan + 1, ce->plan, ce->nplan * sizeof(Play));
                nplan = 1 + ce->nplan;
            }
        }
    }
    if (memo.count > MEMO_SIZE * 3 / 4)
        tell_fail("strong: memo full");
    e = memo_find(&k); /* the table did not move, but children may have filled this one */
    e->key = k;
    e->gen = memo.gen;
    e->value = best;
    e->nplan = (uint8_t)nplan;
    memcpy(e->plan, plan, nplan * sizeof(Play));
    memo.count++;
    return e;
}

static double strong_best(const Battle *b, Play *plan, int *nplan) {
    memo_clear();
    Entry *e = strong_search(b);
    if (plan) {
        memcpy(plan, e->plan, e->nplan * sizeof(Play));
        *nplan = e->nplan;
    }
    return e->value;
}

/* b re-rolled: the mean best value over sampled rolls (the player's own random numbers: the
   dice the hero will really get are not known) */
static double reroll_value(Player *p, const Battle *b) {
    double total = 0.0;
    for (int i = 0; i < SAMPLES; i++) {
        Battle c = *b;
        c.tell = NULL;
        c.rng = p->rng;
        b_reroll(&c);
        total += strong_best(&c, NULL, NULL);
    }
    return total / SAMPLES;
}

static void strong_turn(Player *p, Battle *b) {
    while (!b_turn_over(b)) {
        Play plan[MAX_HAND];
        int nplan;
        double v0 = strong_best(b, plan, &nplan);
        if (b->rerolls > 0) {
            /* play the plan's first j dice, then re-roll the rest: the best j */
            int best_j = -1;
            double best_v = v0;
            Battle c = *b;
            c.tell = NULL;
            for (int j = 0; j <= nplan; j++) {
                if (j > 0) {
                    b_play(&c, plan[j - 1].s, plan[j - 1].t);
                    if (c.result != R_NONE)
                        break;
                }
                if (!b_any_unplayed(&c))
                    break;
                double v = reroll_value(p, &c);
                if (v > best_v + 0.5) {
                    best_v = v;
                    best_j = j;
                }
            }
            if (best_j >= 0) {
                for (int j = 0; j < best_j; j++)
                    b_play(b, plan[j].s, plan[j].t);
                if (b->result == R_NONE)
                    b_reroll(b);
                continue;
            }
        }
        if (!nplan)
            break;
        for (int j = 0; j < nplan; j++) {
            b_play(b, plan[j].s, plan[j].t);
            if (b->result != R_NONE)
                break;
        }
        break;
    }
}

void player_turn(Player *p, Battle *b) {
    switch (p->kind) {
    case P_RANDOM:
        random_turn(p, b);
        break;
    case P_GREEDY:
        greedy_turn(p, b);
        break;
    case P_STRONG:
        strong_turn(p, b);
        break;
    default:
        search_turn(p, b);
    }
}
