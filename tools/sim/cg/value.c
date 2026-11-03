/* What a position is worth to the searching player (search.c): the item sim's value
   (tools/sim/c/value.c) with this engine's statuses. Enemies threaten by their next three
   moves (the nearer counting more), less when the next one is turned away (scared, asleep,
   lasered, in a catfight, hypnotized, berserk) or weakened (tangled, wet); a shown hit that
   would take more than she has is a danger; her fight-long growth (sharp, habit, snowball,
   momentum) and an enemy's red dots and leech count a little. */
#include <stdio.h>
#include <stdlib.h>

#include "players.h"
#include "value.h"

Weights WEIGHTS = {
    .hp = 2.0,
    .danger = 3.0,
    .mana = 1.2,
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
    .grow = 1.0,
    .dot = 1.0,
    .leech = 0.4,
};

const char *const WEIGHT_NAME[] = {
    "hp", "danger", "mana", "ward", "kitten", "keep", "held", "clog", "foe_hp", "foe_shield",
    "foe_ward", "brand", "wet", "fleas", "threat", "decay", "spook", "hero_wet", "hero_fleas",
    "grow", "dot", "leech",
};

double *weight_ref(Weights *w, int i) {
    return &((double *)w)[i];
}

/* a move's cost to her before her shield: its hits (cheer and strength in, tangle off, wet
   halving), or a guess for the rest */
static double move_cost(const Battle *b, int i, int row, int first) {
    const MoveRow *m = &MOVES[row];
    int strength = stk(b, i, ST_strength) + (first ? stk(b, i, ST_cheer) : 0);
    double d;
    switch (m->effect) {
    case E_hit:
    case E_hit2: {
        int one = m->amount + strength - (first ? stk(b, i, ST_tangle) : 0);
        if (one < 0)
            one = 0;
        if (first && stk(b, i, ST_wet) > 0)
            one >>= 1;
        d = m->effect == E_hit2 ? 2.0 * one : one;
        break;
    }
    case E_fleas: d = m->amount * 2.5; break;
    case E_wet:
    case E_spook:
    case E_steal: d = 2.0; break;
    case E_summon: d = 3.0 * m->amount; break;
    case E_wait: d = 0.0; break;
    default: d = 1.0;
    }
    return d;
}

static int attack_turned(const Battle *b, int i) {
    if (stk(b, i, ST_scared) || stk(b, i, ST_hypno) || stk(b, i, ST_berserk))
        return 1;
    int friend = 0;
    for (int j = 1; j < ACTORS; j++)
        friend |= j != i && b->alive[j];
    return friend && (stk(b, i, ST_laser) || stk(b, i, ST_catfight));
}

double next_attack(const Battle *b, int i) {
    if (st_skips(b, i))
        return 0.0;
    int stall = KINDS[b->kind[i]].stall;
    if (stall && stk(b, i, ST_hurt) >= stall)
        return 0.0;
    const MoveRow *m = &MOVES[b->move[i]];
    if (m->effect != E_hit && m->effect != E_hit2)
        return 0.0;
    if (attack_turned(b, i))
        return 0.0;
    return move_cost(b, i, b->move[i], 1);
}

static double threat(const Battle *b, int i) {
    const KindRow *kind = &KINDS[b->kind[i]];
    double t = 0.0, w = 1.0;
    int made = b->made[i];
    for (int j = 0; j < 3; j++) {
        int row = kind->first + (made + j) % kind->count;
        double c = move_cost(b, i, row, j == 0);
        if (j == 0) {
            const MoveRow *m = &MOVES[row];
            int attack = m->effect == E_hit || m->effect == E_hit2;
            if (st_skips(b, i) || (attack && attack_turned(b, i)))
                c = 0.0;
        }
        t += w * c;
        w *= WEIGHTS.decay;
    }
    return t;
}

double value_of(const Battle *b) {
    const Weights *W = &WEIGHTS;
    if (b->result == R_LOST)
        return -100000.0;
    double v = W->hp * b->hp[HERO];
    if (b->result == R_WON)
        return v + 1000.0 + 0.5 * her(b, ST_kittens) * ch_held(b, K_litterbox);
    int most = b->k->mana_most;
    int mana = her(b, ST_mana) < most ? her(b, ST_mana) : most;
    int book = b->k->items[S_book];
    int cost = FACES[book].tags & TAG_HP ? 0 : FACES[book].cost + b->k->kind_count[K_badmilk];
    if (mana <= cost)
        v += 1.5 * W->mana * mana;
    else
        v += 1.5 * W->mana * cost + 0.5 * W->mana * (mana - cost);
    v += W->ward * her(b, ST_ward);
    v -= W->hero_fleas * her(b, ST_poison) * her(b, ST_flea_turns);
    v -= W->spook * her(b, ST_spook);
    v -= W->hero_wet * (her(b, ST_wet) > 0);
    v += W->grow * (her(b, ST_sharp) + her(b, ST_habit) + 0.5 * her(b, ST_snowball) +
                    0.5 * her(b, ST_momentum));
    for (int d = 0; d < b->dice_n; d++)
        if (b->held[d] != NOTHING)
            v -= W->held;
    for (int f = 0; f < 6; f++)
        v -= W->clog * b->clogged[f];
    int sh = her(b, ST_shield) < 6 ? her(b, ST_shield) : 6;
    v += W->kitten * her(b, ST_kittens) + W->keep * (her(b, ST_keep) > 0) * sh;
    double incoming = 0;
    for (int i = 1; i < ACTORS; i++) {
        if (!b->alive[i])
            continue;
        int k = b->kind[i];
        v -= W->foe_hp * (b->hp[i] + KIND_CHAIN[k]);
        v -= W->foe_shield * stk(b, i, ST_shield) + W->foe_ward * stk(b, i, ST_ward);
        /* a status is worth what it can still pay out, not its stack, and never more than the
           hit points it stands on: marks and wet piled on an enemy at 1 hp would be worth more
           than beating it. Its next forms' moves count while it stands (they come when it is
           beaten), so beating a weakened form does not look like a loss */
        int hp = b->hp[i], cap = hp < 4 ? hp : 4;
        int brand = stk(b, i, ST_brand), wet = stk(b, i, ST_wet), leech = stk(b, i, ST_leech);
        v += W->brand * (brand < cap ? brand : cap) + W->wet * (wet < 3 ? wet : 3) * (hp > 4);
        v += W->dot * (stk(b, i, ST_dot) > 0) + W->leech * (leech < 3 ? leech : 3) * (hp > 4);
        v -= W->threat * (threat(b, i) + CHAIN_THREAT[k] * (1 + W->decay + W->decay * W->decay));
        if (stk(b, i, ST_flea_turns)) {
            int f = stk(b, i, ST_poison) * stk(b, i, ST_flea_turns);
            v += W->fleas * (f < b->hp[i] ? f : b->hp[i]);
        }
        incoming += next_attack(b, i);
    }
    double over = incoming - b->hp[HERO] + 2;
    if (over > 0)
        v -= W->danger * over;
    return v;
}

double value_after_turn(const Battle *b) {
    if (b->result != R_NONE)
        return value_of(b);
    Battle c = *b;
    c.tell = NULL;
    int back = __builtin_popcount(b->back);
    b_end_turn(&c);
    return value_of(&c) + BACK_DIE * back;
}

void weights_load(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) {
        fprintf(stderr, "no weights file %s\n", path);
        exit(2);
    }
    char name[64];
    double x;
    while (fscanf(f, "%63s %lf", name, &x) == 2)
        for (int i = 0; i < WEIGHT_COUNT; i++)
            if (!strcmp(name, WEIGHT_NAME[i]))
                *weight_ref(&WEIGHTS, i) = x;
    fclose(f);
}

void weights_print(FILE *f) {
    for (int i = 0; i < WEIGHT_COUNT; i++)
        fprintf(f, "%s %.3f\n", WEIGHT_NAME[i], *weight_ref(&WEIGHTS, i));
}
