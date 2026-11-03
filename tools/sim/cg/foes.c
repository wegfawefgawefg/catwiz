/* The enemies' moves: content/foes.tsp (stalls, skips, move_target, friend, land_move, apply,
   summon, next_move), line for line. */
#include "sim.h"
#include "tell.h"

static int stalls(const Battle *b, int who) {
    int stall = KINDS[b->kind[who]].stall;
    return stall > 0 && stk(b, who, ST_hurt) >= stall;
}

int foes_skips(const Battle *b, int who) {
    return st_skips(b, who) || stalls(b, who);
}

static int friend_of(const Battle *b, int by, int alone) {
    for (int i = 1; i < ACTORS; i++)
        if (i != by && b->alive[i])
            return i;
    return alone;
}

int foes_move_target(Battle *b, int by, int row, int use) {
    const MoveRow *m = &MOVES[row];
    if (m->aim == A_self)
        return by;
    int attack = m->effect == E_hit || m->effect == E_hit2;
    if (attack && stk(b, by, ST_hypno) > 0) {
        int t = play_other_at_random(b, by, 0);
        if (use)
            set_stk(b, by, ST_hypno, 0);
        return t;
    }
    if (attack && stk(b, by, ST_laser) > 0) {
        if (use)
            set_stk(b, by, ST_laser, 0);
        int f = fx_next_standing(b, by);
        return f == by ? HERO : f;
    }
    if (m->aim == A_friend)
        return friend_of(b, by, by);
    int fight = stk(b, by, ST_catfight);
    if (fight > 0 && attack) {
        int f = friend_of(b, by, NOTHING);
        if (f != NOTHING) {
            if (use) {
                b->fight_extra = (uint8_t)fight;
                set_stk(b, by, ST_catfight, 0);
            }
            return f;
        }
    }
    return HERO;
}

static void summon(Battle *b, int by, int n) {
    int kind = KINDS[b->kind[by]].calls;
    for (int k = 0; k < n; k++) {
        int spot = NOTHING;
        for (int i = 1; i < ACTORS; i++)
            if (spot == NOTHING && !b->alive[i])
                spot = i;
        if (spot != NOTHING)
            spawn_enemy(b, spot, kind, 1);
    }
}

static void apply(Battle *b, int effect, int by, int target, int n) {
    switch (effect) {
    case E_hit:
        hit_strike(b, by, target, n, 0);
        play_drain(b);
        break;
    case E_hit2:
        hit_strike(b, by, target, n, 0);
        play_drain(b);
        if (b->alive[target]) {
            hit_strike(b, by, target, n, 0);
            play_drain(b);
        }
        break;
    case E_shield: hit_add(b, target, ST_shield, n); break;
    case E_heal: hit_heal(b, target, n); break;
    case E_cheer: hit_add(b, target, ST_cheer, n); break;
    case E_mend:
        for (int i = 1; i < ACTORS; i++)
            if (i != by && b->alive[i])
                hit_heal(b, i, n);
        break;
    case E_summon: summon(b, by, n); break;
    case E_steal: {
        int d = b->last_played;
        if (d != NOTHING && b->held[d] == NOTHING) {
            b->held[d] = (uint8_t)by;
            if (b->tell)
                tell_line(b, "  %s grabs a die", KINDS[b->kind[by]].name);
        }
        break;
    }
    case E_grow: hit_add(b, by, ST_strength, n); break;
    case E_reflect: hit_add(b, by, ST_reflect, n); break;
    case E_junk:
        if (!b->clogged[n])
            b->clogged[n] = 1;
        break;
    case E_fleas: play_run(b, RW_FLEAS, target, n); break;
    case E_wet: play_run(b, RW_WET, target, n); break;
    case E_spook: play_run(b, RW_SPOOK, target, n); break;
    default:
        break;
    }
}

void foes_land_move(Battle *b, int row, int by, int target) {
    const MoveRow *m = &MOVES[row];
    if (b->tell)
        tell_move(b, by, row, target);
    if (m->aim == A_all && target == HERO && her(b, ST_box) > 0)
        return;
    int extra = b->fight_extra;
    b->fight_extra = 0;
    int effect = m->effect;
    int n = sum8(m->amount, extra);
    if (effect == E_hit || effect == E_hit2) {
        if (stk(b, by, ST_scared) > 0) {
            set_stk(b, by, ST_scared, 0);
            apply(b, E_shield, by, by, n);
            return;
        }
        if (stk(b, by, ST_berserk) > 0) {
            set_stk(b, by, ST_berserk, 0);
            for (int i = 0; i < ACTORS; i++)
                if (b->alive[i])
                    apply(b, effect, by, i, n);
            return;
        }
    }
    apply(b, effect, by, target, n);
}

void foes_next_move(Battle *b, int i) {
    const KindRow *k = &KINDS[b->kind[i]];
    int made = b->made[i] + 1;
    if (made >= k->count)
        made = 0;
    b->made[i] = (uint8_t)made;
    b->move[i] = (uint8_t)(k->first + made);
}
