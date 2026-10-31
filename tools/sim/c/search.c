/* The searching player's turn. It plays the way a careful human would, seeing what she sees:
   the dice shown, every enemy's next move, her kit; never the dice to come.

   1. Every order of the dice shown and every target, merged where two orders reach the same
      position (a memo of whole positions), each ended by the enemies' moves and valued
      (value.c). That gives the best plan with no re-roll.
   2. A re-roll re-rolls every die not played, so "keep" means "play it first". For each set
      of dice she could play before re-rolling (played in the best order found for that
      set), the re-roll's worth is the mean of the best plan over the re-rolled dice: every
      outcome when two dice or fewer are re-rolled, else SAMPLES imagined rolls from her own
      random numbers, the same rolls for every set (so the sets are compared fairly). The
      best few sets are looked at again with more rolls.
   3. She re-rolls when the best set beats the plan by MARGIN, else plays the plan.

   After the re-roll her plan for the new dice may itself re-roll again (the loop). */
#include <stdlib.h>

#include "players.h"
#include "tell.h"
#include "value.h"

#define NODE_CAP 6000
#define MEMO_SIZE 32768
#define SAMPLES 10
#define MORE_SAMPLES 30
#define REFINE 3
#define MARGIN 0.25

typedef struct {
    uint64_t h1, h2;
    uint32_t gen;
    double value;
    uint8_t nplan;
    Play plan[MAX_HAND];
} Entry;

typedef struct {
    int have;
    double value;
    uint8_t npath;
    Play path[MAX_HAND];
} Cand;

static _Thread_local struct {
    Entry *e;
    uint32_t gen;
    int count;
    int collect;              /* the root search records the sets to re-roll after */
    Cand cand[1 << MAX_HAND]; /* by the mask of dice played */
    Play path[MAX_HAND];
    int depth;
} S;

static void key_of(const Battle *b, uint64_t *h1, uint64_t *h2) {
    Battle c = *b;
    c.k = NULL;
    c.rng = NULL;
    c.tell = NULL;
    c.turn = c.hero_lost = c.hero_healed = c.self_hits = c.lost_this_round = 0;
    const uint64_t *w = (const uint64_t *)&c;
    uint64_t a = 0x9E3779B97F4A7C15ull, z = 0xC2B2AE3D27D4EB4Full;
    for (size_t i = 0; i < sizeof c / 8; i++) {
        a = (a ^ w[i]) * 0x100000001B3ull;
        a ^= a >> 29;
        z = (z + w[i]) * 0xFF51AFD7ED558CCDull;
        z ^= z >> 32;
    }
    *h1 = a;
    *h2 = z;
}

static void memo_clear(void) {
    if (!S.e)
        S.e = calloc(MEMO_SIZE, sizeof(Entry));
    S.gen++;
    S.count = 0;
}

static Entry *memo_find(uint64_t h1, uint64_t h2) {
    for (uint32_t i = (uint32_t)h1 & (MEMO_SIZE - 1);; i = (i + 1) & (MEMO_SIZE - 1)) {
        Entry *e = &S.e[i];
        if (e->gen != S.gen || (e->h1 == h1 && e->h2 == h2))
            return e;
    }
}

static int played_mask(const Battle *b) {
    int m = 0;
    for (int s = 0; s < b->hand_n; s++)
        if (b->played[s] && b->tray[s] != NOTHING)
            m |= 1 << s;
    return m;
}

/* the best value of the turn from b with no re-roll, and its plays */
static Entry *search(const Battle *b) {
    uint64_t h1, h2;
    key_of(b, &h1, &h2);
    Entry *e = memo_find(h1, h2);
    if (e->gen == S.gen)
        return e;
    double best = value_after_turn(b);
    if (S.collect && b->result == R_NONE && b_any_unplayed(b)) {
        Cand *c = &S.cand[played_mask(b)];
        if (!c->have || best > c->value) {
            c->have = 1;
            c->value = best;
            c->npath = (uint8_t)S.depth;
            memcpy(c->path, S.path, S.depth * sizeof(Play));
        }
    }
    Play plan[MAX_HAND];
    int nplan = 0;
    if (b->result == R_NONE && S.count < NODE_CAP) {
        Play opts[24];
        int n = options(b, opts);
        for (int i = 0; i < n; i++) {
            Battle c = *b;
            c.tell = NULL;
            b_play(&c, opts[i].s, opts[i].t);
            S.path[S.depth++] = opts[i];
            Entry *ce = search(&c);
            S.depth--;
            if (ce->value > best + 1e-9) {
                best = ce->value;
                plan[0] = opts[i];
                memcpy(plan + 1, ce->plan, ce->nplan * sizeof(Play));
                nplan = 1 + ce->nplan;
            }
        }
    }
    if (S.count > MEMO_SIZE * 3 / 4)
        tell_fail("search: memo full");
    e = memo_find(h1, h2);
    e->h1 = h1;
    e->h2 = h2;
    e->gen = S.gen;
    e->value = best;
    e->nplan = (uint8_t)nplan;
    memcpy(e->plan, plan, nplan * sizeof(Play));
    S.count++;
    return e;
}

static double best_plan(const Battle *b, Play *plan, int *nplan, int collect) {
    memo_clear();
    S.collect = collect;
    S.depth = 0;
    if (collect)
        memset(S.cand, 0, sizeof S.cand);
    Entry *e = search(b);
    S.collect = 0;
    if (plan) {
        memcpy(plan, e->plan, e->nplan * sizeof(Play));
        *nplan = e->nplan;
    }
    return e->value;
}

/* c re-rolled with these faces (a face index for each tray spot): the best plan's value */
static double outcome(const Battle *c, const uint8_t *faces) {
    Battle d = *c;
    d.tell = NULL;
    d.rerolls--;
    items_cough(&d);
    for (int s = 0; s < d.hand_n; s++) {
        if (!d.played[s]) {
            d.face_of[s] = faces[s];
            d.hand[s] = d.faces[faces[s]];
        }
    }
    return best_plan(&d, NULL, NULL, 0);
}

/* the mean over every outcome of the dice not played (two or fewer) */
static double exact_reroll(const Battle *c) {
    int spots[MAX_HAND], k = 0;
    for (int s = 0; s < c->hand_n; s++)
        if (!c->played[s])
            spots[k++] = s;
    int total = 1;
    for (int i = 0; i < k; i++)
        total *= 6;
    uint8_t faces[MAX_HAND] = {0};
    double sum = 0.0;
    for (int o = 0; o < total; o++) {
        int x = o;
        for (int i = 0; i < k; i++) {
            faces[spots[i]] = (uint8_t)(x % 6);
            x /= 6;
        }
        sum += outcome(c, faces);
    }
    return sum / total;
}

static double sampled_reroll(const Battle *c, uint8_t (*samp)[MAX_HAND], int from, int to) {
    double sum = 0.0;
    for (int j = from; j < to; j++)
        sum += outcome(c, samp[j]);
    return sum;
}

static int unplayed_count(const Battle *b) {
    int k = 0;
    for (int s = 0; s < b->hand_n; s++)
        k += !b->played[s];
    return k;
}

static void play_path(Battle *c, const Cand *cand) {
    for (int j = 0; j < cand->npath; j++)
        b_play(c, cand->path[j].s, cand->path[j].t);
}

/* the set of dice to play before re-rolling (an index of cands), or -1 to play the plan */
static int choose_reroll(Player *p, const Battle *b, double v0, Cand *cands) {
    int n = 0;
    for (int m = 0; m < (1 << b->hand_n); m++)
        if (S.cand[m].have)
            cands[n++] = S.cand[m];
    uint8_t samp[MORE_SAMPLES][MAX_HAND];
    for (int j = 0; j < MORE_SAMPLES; j++)
        for (int s = 0; s < b->hand_n; s++)
            samp[j][s] = (uint8_t)((mt_bits(p->rng, 8) * 6) >> 8);
    double val[1 << MAX_HAND];
    int settled[1 << MAX_HAND];
    for (int i = 0; i < n; i++) {
        Battle c = *b;
        c.tell = NULL;
        play_path(&c, &cands[i]);
        settled[i] = unplayed_count(&c) <= 2;
        if (settled[i])
            val[i] = exact_reroll(&c);
        else
            val[i] = sampled_reroll(&c, samp, 0, SAMPLES) / SAMPLES;
    }
    /* the best few sampled ones again, with more rolls */
    for (int r = 0; r < REFINE; r++) {
        int top = -1;
        for (int i = 0; i < n; i++)
            if (!settled[i] && (top < 0 || val[i] > val[top]))
                top = i;
        if (top < 0)
            break;
        Battle c = *b;
        c.tell = NULL;
        play_path(&c, &cands[top]);
        double more = sampled_reroll(&c, samp, SAMPLES, MORE_SAMPLES);
        val[top] = (val[top] * SAMPLES + more) / MORE_SAMPLES;
        settled[top] = 1;
    }
    int best = -1;
    double bv = v0 + MARGIN;
    for (int i = 0; i < n; i++) {
        if (settled[i] && val[i] > bv) {
            bv = val[i];
            best = i;
        }
    }
    return best;
}

void search_turn(Player *p, Battle *b) {
    static _Thread_local Cand cands[1 << MAX_HAND];
    while (!b_turn_over(b)) {
        Play plan[MAX_HAND];
        int nplan;
        double v0 = best_plan(b, plan, &nplan, b->rerolls > 0);
        if (b->rerolls > 0) {
            int i = choose_reroll(p, b, v0, cands);
            if (i >= 0) {
                play_path(b, &cands[i]);
                if (b->result == R_NONE)
                    b_reroll(b);
                continue;
            }
        }
        for (int j = 0; j < nplan; j++) {
            b_play(b, plan[j].s, plan[j].t);
            if (b->result != R_NONE)
                break;
        }
        break;
    }
}

void search_init(void) {}
