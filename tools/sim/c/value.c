/* What a position is worth to the searching player (search.c): the strong player's judge
   (judge.c) with what it misses. Enemies threaten by their next moves, not the average of
   their cycle (the roomba's bump in 2, the king's flop); a waiting boost is worth what it
   will add, once (a stacked times is not worth more and more); a shown hit that would take
   more than the hero has is a danger; a spook or wet on her costs her next turn's dice.
   The weights are WEIGHTS below, tuned by win rate (main.c --tune). */
#include <stdio.h>
#include <stdlib.h>

#include "players.h"
#include "value.h"

Weights WEIGHTS = {
    .hp = 2.0,
    .danger = 3.0,
    .mana = 1.2,
    .plus = 0.8,
    .mult = 1.5,
    .wish = 1.5,
    .ward = 0.6,
    .kitten = 2.5,
    .keep = 0.67,
    .held = 3.0,
    .clog = 2.0,
    .foe_hp = 1.0,
    .foe_shield = 0.8,
    .foe_ward = 0.5,
    .brand = 1.5,
    .wet = 0.5,
    .fleas = 0.9,
    .threat = 1.15,
    .decay = 0.7,
    .spook = 2.5,
    .hero_wet = 2.0,
    .hero_fleas = 2.0,
};

const char *const WEIGHT_NAME[] = {
    "hp", "danger", "mana", "plus", "mult", "wish", "ward", "kitten", "keep", "held",
    "clog", "foe_hp", "foe_shield", "foe_ward", "brand", "wet", "fleas", "threat", "decay",
    "spook", "hero_wet", "hero_fleas",
};

double *weight_ref(Weights *w, int i) {
    return &((double *)w)[i];
}

/* what a move costs the hero, before her shield: its hit and strength, or a guess for the
   rest (the strong player's table) */
static double move_cost(const Battle *b, int i, int row) {
    const MoveRow *m = &MOVES[row];
    int strength = b->st[i][ST_STRENGTH];
    switch (m->effect) {
    case E_hit:
        return m->amount + strength;
    case E_hit2:
        return 2.0 * (m->amount + strength);
    case E_fleas:
        return m->amount * 2.5;
    case E_wet:
    case E_spook:
    case E_steal:
        return 2.0;
    case E_summon:
        return 3.0 * m->amount;
    case E_cheer:
    case E_mend:
    case E_shield:
    case E_reflect:
    case E_grow:
    case E_junk:
    case E_heal:
        return 1.0;
    }
    return 0.0;
}

/* the damage enemy i's next move does if nothing stops it (wet halves it) */
static int next_hit(const Battle *b, int i) {
    if (b->st[i][ST_FRESH])
        return 0;
    const MoveRow *m = &MOVES[b->move[i]];
    int d = 0;
    if (m->effect == E_hit)
        d = m->amount + b->st[i][ST_STRENGTH] + b->st[i][ST_CHEER];
    else if (m->effect == E_hit2)
        d = 2 * (m->amount + b->st[i][ST_STRENGTH]);
    if (b->st[i][ST_WET] > 0)
        d >>= 1;
    return d;
}

/* the next three moves, the nearer counting more */
static double threat(const Battle *b, int i) {
    const KindRow *kind = &KINDS[b->kind[i]];
    double t = 0.0, w = 1.0;
    int made = b->made[i];
    if (b->st[i][ST_FRESH])
        w = WEIGHTS.decay; /* it skips its next move */
    for (int j = 0; j < 3; j++) {
        int row = kind->first + (made + j) % kind->count;
        t += w * move_cost(b, i, row);
        w *= WEIGHTS.decay;
    }
    return t;
}

/* a position at the start of the hero's turn (after the enemies moved), or the fight's end */
double value_of(const Battle *b) {
    const Weights *W = &WEIGHTS;
    if (b->result == R_LOST)
        return -100000.0;
    const int32_t *h = b->st[HERO];
    double v = W->hp * b->hp[HERO];
    if (b->result == R_WON)
        return v + 1000.0;
    /* mana up to what her book costs is worth more than mana past it: a bank for a cast (a
       book without its mana is a dud) */
    int mana = h[ST_MANA] < MOST_MANA ? h[ST_MANA] : MOST_MANA;
    int cost = ITEMS[b->k->items[S_book]].cost + (BADMILK_FLEAS ? 0 : b->k->charm_n[K_badmilk]);
    if (mana <= cost)
        v += 1.5 * W->mana * mana;
    else
        v += 1.5 * W->mana * cost + 0.5 * W->mana * (mana - cost);
    if (h[ST_PLUS_LEFT])
        v += W->plus * h[ST_PLUS] * h[ST_PLUS_LEFT];
    if (h[ST_MULT] > 1)
        v += W->mult * (h[ST_MULT] > 4 ? 3 : h[ST_MULT] - 1);
    v += W->wish * (h[ST_WISH] > 0);
    v += W->ward * h[ST_WARD];
    v -= W->hero_fleas * h[ST_POISON] * h[ST_FLEA_TURNS];
    v -= W->spook * h[ST_SPOOK];
    v -= W->hero_wet * (h[ST_WET] > 0);
    for (int d = 0; d < b->ndice; d++)
        if (b->held[d] != NOTHING)
            v -= W->held;
    v -= W->clog * b->nclogged;
    int sh = h[ST_SHIELD] < 6 ? h[ST_SHIELD] : 6;
    v += W->kitten * h[ST_KITTENS] + W->keep * h[ST_KEEP] * sh;
    int incoming = 0;
    for (int i = 1; i < ACTORS; i++) {
        if (!b->alive[i])
            continue;
        const int32_t *s = b->st[i];
        int k = b->kind[i];
        v -= W->foe_hp * (b->hp[i] + KIND_CHAIN[k]);
        v -= W->foe_shield * s[ST_SHIELD] + W->foe_ward * s[ST_WARD];
        v += W->brand * s[ST_BRAND] + W->wet * s[ST_WET];
        v -= W->threat * threat(b, i);
        if (s[ST_FLEA_TURNS]) {
            int f = s[ST_POISON] * s[ST_FLEA_TURNS];
            v += W->fleas * (f < b->hp[i] ? f : b->hp[i]);
        }
        incoming += next_hit(b, i);
    }
    int over = incoming - b->hp[HERO] + 2;
    if (over > 0)
        v -= W->danger * over;
    return v;
}

/* b as the turn would end now: the enemies move, then the position */
double value_after_turn(const Battle *b) {
    if (b->result != R_NONE)
        return value_of(b);
    Battle c = *b;
    c.tell = NULL;
    b_end_turn(&c);
    return value_of(&c);
}

/* weights from a file of "name value" lines (main.c --weights) */
void weights_load(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) {
        fprintf(stderr, "no weights file %s\n", path);
        exit(2);
    }
    char name[64];
    double x;
    while (fscanf(f, "%63s %lf", name, &x) == 2) {
        for (int i = 0; i < WEIGHT_COUNT; i++)
            if (!strcmp(name, WEIGHT_NAME[i]))
                *weight_ref(&WEIGHTS, i) = x;
    }
    fclose(f);
}

void weights_print(FILE *f) {
    for (int i = 0; i < WEIGHT_COUNT; i++)
        fprintf(f, "%s %.3f\n", WEIGHT_NAME[i], *weight_ref(&WEIGHTS, i));
}
