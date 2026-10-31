/* What a position is worth: tools/sim/policy.py Judge, for the greedy and strong players
   (the searching player has its own, search.c). The hero's hit point is worth W_HP of an
   enemy's, and an enemy standing costs its threat (damage a turn) THREAT_TURNS times more.
   The sums keep the Python's order so the two sims pick the same plays. */
#include "players.h"

#define W_HP 2.0
#define THREAT_TURNS 2.5

double KIND_THREAT[KIND_COUNT];
int KIND_CHAIN[KIND_COUNT]; /* hit points still to come after it is beaten (then kinds) */

void judge_init(void) {
    for (int k = 0; k < KIND_COUNT; k++) {
        double total = 0.0;
        for (int r = KINDS[k].first; r < KINDS[k].first + KINDS[k].count; r++) {
            const MoveRow *m = &MOVES[r];
            switch (m->effect) {
            case E_hit:
                total += m->amount;
                break;
            case E_fleas:
                total += m->amount * 2.5;
                break;
            case E_wet:
            case E_spook:
            case E_steal:
                total += 2.0;
                break;
            case E_summon:
                total += 3.0 * m->amount;
                break;
            case E_cheer:
            case E_mend:
            case E_shield:
            case E_reflect:
            case E_grow:
            case E_junk:
                total += 1.0;
                break;
            }
        }
        KIND_THREAT[k] = total / KINDS[k].count;
        int chain = 0;
        for (int t = KINDS[k].then; t != NOTHING; t = KINDS[t].then)
            chain += KINDS[t].hp;
        KIND_CHAIN[k] = chain;
    }
}

/* a position at the start of the hero's turn (or the fight's end) */
double judge_value(const Battle *b) {
    if (b->result == R_LOST)
        return -100000.0;
    const int32_t *st0 = b->st[HERO];
    double v = W_HP * b->hp[HERO];
    if (b->result == R_WON)
        return v + 1000.0;
    int mana = st0[ST_MANA] < 5 ? st0[ST_MANA] : 5;
    v += 1.2 * mana + 0.8 * st0[ST_PLUS] + 2.0 * 0;
    v += 0.6 * st0[ST_WARD];
    v -= W_HP * st0[ST_POISON] * st0[ST_FLEA_TURNS];
    for (int d = 0; d < b->ndice; d++)
        if (b->held[d] != NOTHING)
            v -= 3.0; /* a die a squirrel holds */
    v -= 2.0 * b->nclogged; /* a slot under a hairball */
    int sh = st0[ST_SHIELD] < 6 ? st0[ST_SHIELD] : 6;
    v += 2.5 * st0[ST_KITTENS] + 2.0 * st0[ST_KEEP] * sh / 3;
    v += 1.5 * st0[ST_MULT];
    for (int i = 1; i < ACTORS; i++) {
        if (!b->alive[i])
            continue;
        const int32_t *s = b->st[i];
        int k = b->kind[i];
        int hp = b->hp[i] + KIND_CHAIN[k];
        v -= hp + 0.8 * s[ST_SHIELD] + 0.5 * s[ST_WARD];
        v += 1.5 * s[ST_BRAND] + 0.5 * s[ST_WET];
        v -= (KIND_THREAT[k] + s[ST_STRENGTH]) * THREAT_TURNS;
        if (s[ST_FLEA_TURNS]) {
            int f = s[ST_POISON] * s[ST_FLEA_TURNS];
            v += 0.9 * (f < b->hp[i] ? f : b->hp[i]);
        }
    }
    return v;
}

/* b as the turn would end now: the enemies move, then the position */
double judge_after_turn(const Battle *b) {
    if (b->result != R_NONE)
        return judge_value(b);
    Battle c = *b;
    c.tell = NULL;
    b_end_turn(&c);
    return judge_value(&c);
}
