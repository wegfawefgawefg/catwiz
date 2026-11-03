/* What a position is worth to the greedy and strong players (tools/sim/c/judge.c for this
   engine): her hit point is worth W_HP of an enemy's, and an enemy standing costs its average
   move (KIND_THREAT) THREAT_TURNS times more. The searching player has its own (value.c). */
#include "players.h"

#define W_HP 2.0
#define THREAT_TURNS 2.5

double KIND_THREAT[KIND_COUNT];
int KIND_CHAIN[KIND_COUNT]; /* hit points still to come after it is beaten (its next forms) */

void judge_init(void) {
    for (int k = 0; k < KIND_COUNT; k++) {
        double total = 0.0;
        for (int r = KINDS[k].first; r < KINDS[k].first + KINDS[k].count; r++) {
            const MoveRow *m = &MOVES[r];
            switch (m->effect) {
            case E_hit: total += m->amount; break;
            case E_hit2: total += 2.0 * m->amount; break;
            case E_fleas: total += m->amount * 2.5; break;
            case E_wet:
            case E_spook:
            case E_steal: total += 2.0; break;
            case E_summon: total += 3.0 * m->amount; break;
            case E_wait: break;
            default: total += 1.0;
            }
        }
        KIND_THREAT[k] = total / KINDS[k].count;
        int chain = 0;
        for (int t = KINDS[k].then; t != NOTHING; t = KINDS[t].then)
            chain += KINDS[t].hp;
        KIND_CHAIN[k] = chain;
    }
}

double judge_value(const Battle *b) {
    if (b->result == R_LOST)
        return -100000.0;
    double v = W_HP * b->hp[HERO];
    if (b->result == R_WON)
        return v + 1000.0;
    int mana = her(b, ST_mana) < 5 ? her(b, ST_mana) : 5;
    v += 1.2 * mana + 0.6 * her(b, ST_ward);
    v -= W_HP * her(b, ST_poison) * her(b, ST_flea_turns);
    for (int d = 0; d < b->dice_n; d++)
        if (b->held[d] != NOTHING)
            v -= 3.0;
    for (int f = 0; f < 6; f++)
        v -= 2.0 * b->clogged[f];
    int sh = her(b, ST_shield) < 6 ? her(b, ST_shield) : 6;
    v += 2.5 * her(b, ST_kittens) + 2.0 * (her(b, ST_keep) > 0) * sh / 3;
    v += her(b, ST_sharp) + her(b, ST_habit);
    for (int i = 1; i < ACTORS; i++) {
        if (!b->alive[i])
            continue;
        int k = b->kind[i];
        v -= b->hp[i] + KIND_CHAIN[k] + 0.8 * stk(b, i, ST_shield) + 0.5 * stk(b, i, ST_ward);
        v += 1.5 * stk(b, i, ST_brand) + 0.5 * stk(b, i, ST_wet);
        v -= (KIND_THREAT[k] + stk(b, i, ST_strength)) * THREAT_TURNS;
        if (stk(b, i, ST_flea_turns)) {
            int f = stk(b, i, ST_poison) * stk(b, i, ST_flea_turns);
            v += 0.9 * (f < b->hp[i] ? f : b->hp[i]);
        }
    }
    return v;
}

double judge_after_turn(const Battle *b) {
    if (b->result != R_NONE)
        return judge_value(b);
    Battle c = *b;
    c.tell = NULL;
    int back = __builtin_popcount(b->back);
    b_end_turn(&c);
    return judge_value(&c) + BACK_DIE * back;
}
