/* The reference players (tools/sim/c/players.c, for this engine):

   random  plays a random playable die on a random enemy until none is left; re-rolls or
           ends at random when stuck. A player mashing keys.
   greedy  each step plays the one die and target that leaves the best position after the
           enemies' shown moves (judge.c); ends when no die helps; re-rolls when stuck.
   strong  searches the whole turn (every order of dice and targets, merged where they lead
           to the same position, NODE_CAP positions at most), then the enemies' moves; and
           whether to play the plan's first few dice and re-roll the rest, by sampling. */
#include <stdlib.h>

#include "players.h"
#include "tell.h"

const char *const PLAYER_NAME[P_COUNT] = {"random", "greedy", "strong", "search"};

double BLUNDER_PLAY = 0.0, BLUNDER_PICK = 0.0;
_Thread_local int FLIP_ROOM = 0;

void pos_hash(const Battle *b, uint64_t *h1, uint64_t *h2) {
    const uint8_t *p = (const uint8_t *)b + POS_BEGIN;
    size_t n = POS_END - POS_BEGIN;
    uint64_t a = 1469598103934665603ull, z = 0x9E3779B97F4A7C15ull;
    for (size_t i = 0; i < n; i++) {
        a = (a ^ p[i]) * 1099511628211ull;
        z = (z + p[i] + 1) * 0xFF51AFD7ED558CCDull;
        z ^= z >> 29;
    }
    *h1 = a;
    *h2 = z;
}

/* whether face id's steps take a random number (a coin, a hat, a pick at random) */
int face_random(int id) {
    static _Thread_local int8_t known[FACE_COUNT];
    if (known[id])
        return known[id] > 0;
    int r = 0;
    for (int pc = ROW_AT[id];; pc += 2) {
        int op = STEP_BYTES[pc], a = STEP_BYTES[pc + 1];
        if (op == OP_COIN || op == OP_HAT || (op == OP_NEXT && a == 1))
            r = 1;
        if (op == OP_STOP)
            break;
    }
    known[id] = r ? 1 : -1;
    return r;
}

int blunder(Player *p, Battle *b) {
    if (BLUNDER_PLAY <= 0.0 || mt_random(p->rng) >= BLUNDER_PLAY)
        return 0;
    Play opts[MAX_OPTIONS];
    int n = options(b, opts);
    int m = 0;
    for (int i = 0; i < n; i++)
        if (!(opts[i].t != NOTHING && (opts[i].t & FLIP)))
            opts[m++] = opts[i];
    if (!m)
        return 0;
    Play o = opts[mt_below(p->rng, m)];
    b_play(b, o.s, o.t);
    b->blunders++;
    return 1;
}

/* the distinct plays now: a die for each row shown, each enemy for a face that picks one (a
   hat trick picks the enemy its face goes to); after a paw flip, each unplayed die (one of
   each face shown) turned to each other face that is not a hairball */
int options(const Battle *b, Play *out) {
    int n = 0;
    uint8_t seen[8] = {0};
    for (int d = 0; d < DICE_MOST; d++) {
        if (!b_can_play(b, d))
            continue;
        int row = b->hand[d];
        if (seen[row])
            continue;
        seen[row] = 1;
        int id = row_id(b, row);
        int pick = FACES[id].aim == A_foe || id == ID_HAT_TRICK;
        if (pick) {
            for (int t = 1; t < ACTORS; t++) {
                if (b->alive[t] && n < MAX_OPTIONS) {
                    out[n].s = (uint8_t)d;
                    out[n].t = (uint8_t)t;
                    n++;
                }
            }
        } else if (n < MAX_OPTIONS) {
            out[n].s = (uint8_t)d;
            out[n].t = NOTHING;
            n++;
        }
    }
    if (her(b, ST_flip) > 0 && b->flips_used < FLIP_ROOM) {
        uint8_t face_seen[6] = {0};
        for (int d = 0; d < DICE_MOST; d++) {
            if (d < b->flip_next || b->played[d] || (b->back >> d & 1) || face_seen[b->face_of[d]])
                continue;
            face_seen[b->face_of[d]] = 1;
            for (int f = 0; f < 6; f++) {
                if (f == b->face_of[d] || b->clogged[f] || n >= MAX_OPTIONS)
                    continue;
                out[n].s = (uint8_t)d;
                out[n].t = (uint8_t)(FLIP | f);
                n++;
            }
        }
    }
    return n;
}

static void random_turn(Player *p, Battle *b) {
    while (!b_turn_over(b)) {
        int dice[MAX_HAND], n = 0;
        for (int d = 0; d < DICE_MOST; d++)
            if (b_can_play(b, d))
                dice[n++] = d;
        if (n) {
            int d = dice[mt_below(p->rng, n)];
            int live[ACTORS], nl = 0;
            for (int t = 1; t < ACTORS; t++)
                if (b->alive[t])
                    live[nl++] = t;
            b_play(b, d, live[mt_below(p->rng, nl)]);
            continue;
        }
        if (b_can_reroll(b) && mt_random(p->rng) < 0.5) {
            b_reroll(b);
            continue;
        }
        break;
    }
}

static void greedy_turn(Player *p, Battle *b) {
    b->srng = mt_u32(p->rng) | 1;
    while (!b_turn_over(b)) {
        double best = judge_after_turn(b);
        int pick = -1;
        Play opts[MAX_OPTIONS];
        int n = options(b, opts);
        for (int i = 0; i < n; i++) {
            if (opts[i].t != NOTHING && (opts[i].t & FLIP))
                continue; /* greedy never turns a die */
            Battle c = *b;
            c.tell = NULL;
            c.rng = NULL;
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
        if (b_can_reroll(b)) {
            b_reroll(b);
            continue;
        }
        break;
    }
}

/* ---- strong: the turn search with a memo of positions */

#define SAMPLES 6
#define NODE_CAP 1500
#define MEMO_SIZE 8192

typedef struct {
    uint64_t h1, h2;
    uint32_t gen;
    double value;
    uint8_t nplan;
    Play plan[MAX_PLAYS];
} Entry;

static _Thread_local struct {
    Entry *e;
    uint32_t gen;
    int count, depth;
} M;

static void memo_clear(void) {
    if (!M.e)
        M.e = calloc(MEMO_SIZE, sizeof(Entry));
    M.gen++;
    M.count = 0;
}

static Entry *memo_find(uint64_t h1, uint64_t h2) {
    for (uint32_t i = (uint32_t)h1 & (MEMO_SIZE - 1);; i = (i + 1) & (MEMO_SIZE - 1)) {
        Entry *e = &M.e[i];
        if (e->gen != M.gen || (e->h1 == h1 && e->h2 == h2))
            return e;
    }
}

static Entry *strong_search(const Battle *b) {
    uint64_t h1, h2;
    pos_hash(b, &h1, &h2);
    Entry *e = memo_find(h1, h2);
    if (e->gen == M.gen)
        return e;
    double best = judge_after_turn(b);
    Play plan[MAX_PLAYS];
    int nplan = 0;
    if (b->result == R_NONE && !b->back && M.count < NODE_CAP && M.depth < MAX_PLAYS - 1) {
        Play opts[MAX_OPTIONS];
        int n = options(b, opts);
        for (int i = 0; i < n; i++) {
            Battle c = *b;
            c.tell = NULL;
            c.rng = NULL;
            b_play(&c, opts[i].s, opts[i].t);
            M.depth++;
            Entry *ce = strong_search(&c);
            M.depth--;
            if (ce->value > best + 1e-9 && ce->nplan < MAX_PLAYS - 1) {
                best = ce->value;
                plan[0] = opts[i];
                memcpy(plan + 1, ce->plan, ce->nplan * sizeof(Play));
                nplan = 1 + ce->nplan;
            }
        }
    }
    if (M.count > MEMO_SIZE * 3 / 4)
        tell_fail("strong: memo full");
    e = memo_find(h1, h2);
    e->h1 = h1;
    e->h2 = h2;
    e->gen = M.gen;
    e->value = best;
    e->nplan = (uint8_t)nplan;
    memcpy(e->plan, plan, nplan * sizeof(Play));
    M.count++;
    return e;
}

static double strong_best(const Battle *b, Play *plan, int *nplan) {
    memo_clear();
    FLIP_ROOM = plan ? FLIP_MOST : 0;
    Entry *e = strong_search(b);
    FLIP_ROOM = 0;
    if (plan) {
        memcpy(plan, e->plan, e->nplan * sizeof(Play));
        *nplan = e->nplan;
    }
    return e->value;
}

static double reroll_value(Player *p, const Battle *b) {
    double total = 0.0;
    for (int i = 0; i < SAMPLES; i++) {
        Battle c = *b;
        c.tell = NULL;
        c.rng = p->rng;
        b_reroll(&c);
        c.rng = NULL;
        total += strong_best(&c, NULL, NULL);
    }
    return total / SAMPLES;
}

static void strong_turn(Player *p, Battle *b) {
    while (!b_turn_over(b)) {
        b->srng = mt_u32(p->rng) | 1;
        Play plan[MAX_PLAYS];
        int nplan;
        double v0 = strong_best(b, plan, &nplan);
        if (b_can_reroll(b)) {
            int best_j = -1;
            double best_v = v0;
            Battle c = *b;
            c.tell = NULL;
            c.rng = NULL;
            for (int j = 0; j <= nplan; j++) {
                if (j > 0) {
                    b_play(&c, plan[j - 1].s, plan[j - 1].t);
                    if (c.result != R_NONE || c.back)
                        break;
                }
                if (!b_can_reroll(&c))
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
                if (b_can_reroll(b))
                    b_reroll(b);
                continue;
            }
        }
        if (!nplan)
            break;
        int fresh = 0;
        for (int j = 0; j < nplan; j++) {
            int before = b->refreshes;
            b_play(b, plan[j].s, plan[j].t);
            if (b->result != R_NONE)
                break;
            if (b->refreshes != before) {
                fresh = 1; /* dice came back: plan again */
                break;
            }
        }
        if (!fresh)
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
