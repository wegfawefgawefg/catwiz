/* The steps run: content/play.tsp (run, curse, drain, land_face, turn_end, other_at_random)
   and content/hooks.tsp (the queue of steps waiting, the statuses' hooks). Line for line: a
   row is a step row of gen_content.h (a face's, a charm's or cards.tsp's), two bytes a step. */
#include "sim.h"
#include "tell.h"

#define ALL_K 0
#define OTHERS_K 1
#define REP_K 2

static inline int byte_at(int row, int pc) {
    return STEP_BYTES[ROW_AT[row] + pc];
}

/* ---- content/hooks.tsp */

void hooks_add(Battle *b, int row, int t, int v) {
    if (b->q_count >= 4)
        return;
    b->q_fx[b->q_count] = (uint16_t)row;
    b->q_on[b->q_count] = (uint8_t)t;
    b->q_val[b->q_count] = (uint8_t)v;
    b->q_count++;
}

static int waiting(const Battle *b) {
    return b->q_head < b->q_count;
}

static int take(Battle *b, int *on, int *value) {
    int k = b->q_head;
    b->q_head = (uint8_t)(k + 1);
    if (b->q_head == b->q_count)
        b->q_head = b->q_count = 0;
    *on = b->q_on[k];
    *value = b->q_val[k];
    return b->q_fx[k];
}

void hooks_status(Battle *b, int when, int holder, int t) {
    for (int k = 0; k < HOOK_COUNT; k++) {
        int w = HOOKS[k].when;
        if (w == when || (w == W_wand_hit && b->wand_on && when == W_her_hit)) {
            if (stk(b, holder, HOOKS[k].status) > 0) {
                int v = stk(b, holder, HOOKS[k].value);
                if (v > 0)
                    hooks_add(b, HOOKS[k].row, t, v);
            }
        }
    }
}

/* ---- content/play.tsp */

static int past_close(int row, int pc) {
    while (byte_at(row, pc) != OP_END)
        pc += 2;
    return pc + 2;
}

static int standing_after(const Battle *b, int t, int skip) {
    for (int i = t + 1; i < ACTORS; i++)
        if (b->alive[i] && i != skip)
            return i;
    return NOTHING;
}

int play_other_at_random(Battle *b, int t, int from) {
    int k = 0;
    for (int i = from; i < ACTORS; i++)
        if (i != t && b->alive[i])
            k++;
    if (k == 0)
        return NOTHING;
    int r = (rnd_byte(b) * k) >> 8;
    for (int i = from; i < ACTORS; i++) {
        if (i != t && b->alive[i]) {
            if (r == 0)
                return i;
            r--;
        }
    }
    return NOTHING;
}

static int mimicry(int effect, int all) {
    for (int k = 0; k < MIMICRY_COUNT; k++)
        if (MIMICRY[k].effect == effect && (all || !MIMICRY[k].all))
            return k;
    return NOTHING;
}

/* the steps of a face row (content/items fx) */
static int face_fx(const Battle *b, int row) {
    return row_id(b, row); /* a face's step row is its catalog id */
}

int play_curse(Battle *b, int t, int s, int v) {
    int ward = stk(b, t, ST_ward);
    if (ward > 0) {
        set_stk(b, t, ST_ward, ward - 1);
        ch_hook(b, W_warded);
        return 0;
    }
    int kind = b->kind[t];
    if (s == ST_sleep && kind != NOTHING && kind >= KING && kind <= KING_3)
        return 0;
    if (s == ST_wet && ch_held(b, K_monsoon))
        v = sum8(v, v);
    hit_add(b, t, s, v);
    return 1;
}

void play_run(Battle *b, int start, int t0, int n0) {
    int p = start, pc = 0, t = t0, n = n0, v = n0, base = 0;
    int calls = 0, loops = 0, threes = 0;
    int call_p[CALLS], call_pc[CALLS], call_t[CALLS], call_v[CALLS], call_n[CALLS],
        call_loops[CALLS];
    int loop_pc[LOOPS], loop_kind[LOOPS], loop_left[LOOPS], loop_t[LOOPS];
    int again = 0, again_at = 0, again_on = b->echo_next;
    long steps = 0;
    b->echo_next = 0;
    for (;;) {
        if (++steps > STEP_GUARD) {
            b->peak.runaway = 1;
            tell_line(b, "  runaway: %ld steps", steps);
            b->q_head = b->q_count = 0;
            return;
        }
        int op = byte_at(p, pc);
        int a = byte_at(p, pc + 1);
        pc += 2;
        int go = 1;
        int to = p, to_t = t, to_v = v;
        int s = a & 0x7F;
        int who = a >= OP_ON_T ? t : HERO;
        int old = who < ACTORS ? stk(b, who, s) : 0;
        int now = old, write = 0, cut = 0;
        switch (op) {
        case OP_NUM: v = n; break;
        case OP_LIT: v = a; break;
        case OP_KITS: {
            int per = a == 0 ? n : a;
            for (int k = 0; k < per; k++)
                v = sum8(v, her(b, ST_kittens));
            break;
        }
        case OP_GET: v = old; break;
        case OP_PLUS: v = sum8(v, old); break;
        case OP_HALF: v >>= 1; break;
        case OP_MORE: v = sum8(v, a == 0 ? n : a); break;
        case OP_LEAST: if (v < a) v = a; break;
        case OP_MOST: if (v > a) v = a; break;
        case OP_KEPT: v = b->kept; break;
        case OP_IF: if (old == 0) pc += 2; break;
        case OP_IF_UP: cut = !(t < ACTORS && b->alive[t]); break;
        case OP_FELL:
            cut = a == 0 ? (t < ACTORS && b->alive[t]) : (b->lost == 0);
            break;
        case OP_LOW: cut = b->hp[HERO] >= a; break;
        case OP_COIN:
            if (rnd_byte(b) < 128)
                pc += a << 1;
            break;
        case OP_THREE:
            if (b->three) {
                threes = 1;
                if (ch_held(b, K_echo)) {
                    again = pc;
                    again_at = calls;
                    again_on = 1;
                }
            } else {
                go = 0;
            }
            break;
        case OP_CALM:
            if (b->rerolled) {
                if (a == 0)
                    cut = 1;
                else
                    pc += 2;
            }
            break;
        case OP_ADD: now = sum8(old, v); write = 1; break;
        case OP_SET: now = v; write = 1; break;
        case OP_MAX: now = v; write = v > old; break;
        case OP_TIMES: now = fx_times(old, v); write = 1; break;
        case OP_SUB: now = old > v ? old - v : 0; write = 1; break;
        case OP_MANA: st_gain_mana(b, v); break;
        case OP_SPILL: {
            int m = sum8(her(b, ST_mana), v);
            v = 0;
            if (m > b->k->mana_most) {
                v = m - b->k->mana_most;
                m = b->k->mana_most;
            }
            set_stk(b, HERO, ST_mana, m);
            break;
        }
        case OP_REROLLS: {
            int r = a == 0 ? sum8(b->rerolls, v) : 0;
            if (r > REROLLS_MOST)
                r = REROLLS_MOST;
            b->rerolls = (uint8_t)r;
            break;
        }
        case OP_HEAL: hit_heal(b, HERO, v); break;
        case OP_HIT: hit_strike(b, HERO, t, v, 0); break;
        case OP_PIERCE: hit_strike(b, HERO, t, v, 1); break;
        case OP_PLAIN: hit_plain(b, t, v); break;
        case OP_HURT: if (v > 0) hit_lose(b, t, v); break;
        case OP_CURSE: go = play_curse(b, t, s, v); break;
        case OP_POUNCE: fx_pounce(b, t); break;
        case OP_ALL: {
            int first = standing_after(b, 0, a == OTHERS_K ? t : NOTHING);
            if (first == NOTHING || loops >= LOOPS) {
                pc = past_close(p, pc);
            } else {
                loop_pc[loops] = pc;
                loop_kind[loops] = a;
                loop_t[loops] = t;
                loops++;
                t = first;
            }
            break;
        }
        case OP_REP:
            if (v == 0 || loops >= LOOPS) {
                pc = past_close(p, pc);
            } else {
                loop_pc[loops] = pc;
                loop_kind[loops] = REP_K;
                loop_left[loops] = v;
                loops++;
            }
            break;
        case OP_END: {
            int k = loops - 1;
            if (loop_kind[k] == REP_K) {
                int left = loop_left[k] - 1;
                loop_left[k] = left;
                if (left > 0)
                    pc = loop_pc[k];
                else
                    loops = k;
            } else {
                int after = standing_after(b, t, loop_kind[k] == OTHERS_K ? loop_t[k] : NOTHING);
                if (after == NOTHING) {
                    t = loop_t[k];
                    loops = k;
                } else {
                    t = after;
                    pc = loop_pc[k];
                }
            }
            break;
        }
        case OP_NEXT:
            t = a == 0 ? fx_next_standing(b, t) : play_other_at_random(b, t, 1);
            if (t == NOTHING)
                go = 0;
            break;
        case OP_RETARGET:
            if (!(t < ACTORS && b->alive[t])) {
                t = fx_next_standing(b, t);
                if (t == NOTHING)
                    go = 0;
            }
            break;
        case OP_ME: t = HERO; break;
        case OP_BLOCKED:
            if (v > b->blocked)
                v = b->blocked;
            if (v == 0)
                go = 0;
            break;
        case OP_BACK:
            if (b->back_due)
                go = 0;
            else
                b->back_due = 1;
            break;
        case OP_MIMIC:
            if (a == 0) {
                int row = b->move[t];
                const MoveRow *m = &MOVES[row];
                int k = mimicry(m->effect, m->aim == A_all);
                if (k == NOTHING) {
                    go = 0;
                } else {
                    b->mim_row = MIMICRY[k].row;
                    int mv = m->amount;
                    if (m->effect == E_hit || m->effect == E_hit2)
                        mv = sum8(sum8(mv, stk(b, t, ST_strength)), stk(b, t, ST_cheer));
                    b->mim_v = (uint8_t)mv;
                }
            } else {
                to = b->mim_row;
                to_v = b->mim_v;
            }
            break;
        case OP_COPY:
            if (b->last_face == NOTHING) {
                go = 0;
            } else {
                if (v > 0) {
                    hit_add(b, HERO, ST_plus, v);
                    if (her(b, ST_plus_left) == 0)
                        set_stk(b, HERO, ST_plus_left, 1);
                }
                int on = b->last_on;
                if (!b->alive[on])
                    on = t;
                int row = b->last_face;
                if (b->tell)
                    tell_line(b, "  copycat: %s", FACES[row_id(b, row)].name);
                to = face_fx(b, row);
                to_t = on;
                to_v = fx_prepare(b, row, on, 1);
            }
            break;
        case OP_DO: to = SUBS[a]; break;
        case OP_HAT: {
            int id = (rnd_byte(b) * (FACE_COUNT - 1)) >> 8;
            b->hat_id = (uint8_t)id;
            if (b->tell)
                tell_line(b, "  out of the hat: %s", FACES[id].name);
            to = id;
            if (FACES[id].aim != A_self)
                to_t = b->target;
            to_v = fx_number(b, HAT_ROW);
            if (calls + 1 > b->peak.hat_deep)
                b->peak.hat_deep = (uint8_t)(calls + 1);
            break;
        }
        case OP_STOP:
            go = 0;
            if (again_on && again_at == calls) {
                again_on = 0;
                if (!(t < ACTORS && b->alive[t]))
                    t = fx_next_standing(b, t);
                if (t != NOTHING) {
                    if (b->tell)
                        tell_line(b, "  again!");
                    pc = again;
                    go = 1;
                }
            }
            break;
        case OP_CUE:
        case OP_SAY:
        case OP_HERE:
            break;
        default:
            go = 0;
        }
        if (cut) {
            if (loops > base)
                pc = past_close(p, pc) - 2;
            else
                go = 0;
        }
        if (write)
            set_stk(b, who, s, now);
        if (go) {
            if (to == p && waiting(b) && calls < CALLS) {
                int on, val;
                to = take(b, &on, &val);
                to_t = on;
                to_v = val;
            }
            if (to != p && calls < CALLS) {
                call_p[calls] = p;
                call_pc[calls] = pc;
                call_t[calls] = t;
                call_v[calls] = v;
                call_n[calls] = n;
                call_loops[calls] = loops;
                calls++;
                if (calls > b->calls_deep)
                    b->calls_deep = (uint8_t)calls;
                base = loops;
                p = to;
                pc = 0;
                t = to_t;
                v = to_v;
                n = to_v;
            }
        } else if (calls > 0) {
            calls--;
            p = call_p[calls];
            pc = call_pc[calls];
            t = call_t[calls];
            v = call_v[calls];
            n = call_n[calls];
            loops = call_loops[calls];
            base = calls > 0 ? call_loops[calls - 1] : 0;
        } else {
            b->wand_on = 0;
            if (threes) {
                threes = 0;
                ch_hook(b, W_three);
            }
            if (!waiting(b))
                break;
            int on, val;
            p = take(b, &on, &val);
            pc = 0;
            t = on;
            v = val;
            n = v;
            loops = 0;
            base = 0;
        }
    }
    if (steps > b->peak.max_steps)
        b->peak.max_steps = (uint16_t)(steps < 65535 ? steps : 65535);
}

void play_drain(Battle *b) {
    if (waiting(b))
        play_run(b, RW_NOTHING, HERO, 0);
}

/* play.land_face: a trick's steps with its number; any other face's after the boosts */
void play_land_face(Battle *b, int row, int target) {
    int p = face_fx(b, row);
    int slot = row_slot(b, row);
    if (slot == S_trick) {
        play_run(b, p, target, fx_number(b, row));
        return;
    }
    if (slot == S_book && her(b, ST_echo) > 0) {
        set_stk(b, HERO, ST_echo, 0);
        b->echo_next = 1;
    }
    play_run(b, p, target, fx_prepare(b, row, target, 0));
}

/* play.turn_end: her turn's charms, the boosts go, her statuses' hooks; the kittens pounce */
void play_turn_end(Battle *b) {
    ch_hook(b, W_turn_end);
    play_drain(b);
    set_stk(b, HERO, ST_plus, 0);
    set_stk(b, HERO, ST_plus_left, 0);
    set_stk(b, HERO, ST_mult, 0);
    set_stk(b, HERO, ST_allin, 0);
    set_stk(b, HERO, ST_flip, 0);
    set_stk(b, HERO, ST_echo, 0);
    hooks_status(b, W_turn_end, HERO, HERO);
    play_drain(b);
    if (!b->alive[HERO])
        return;
    int times = her(b, ST_nipped) > 0 ? 2 : 1;
    set_stk(b, HERO, ST_nipped, 0);
    set_stk(b, HERO, ST_nip, 0);
    set_stk(b, HERO, ST_knead_fluff, 0);
    set_stk(b, HERO, ST_knead_wand, 0);
    if (her(b, ST_kittens) == 0)
        return;
    for (int k = 0; k < times; k++) {
        int t = NOTHING;
        for (int i = 1; i < ACTORS; i++)
            if (b->alive[i] && t == NOTHING)
                t = i;
        for (int i = 1; i < ACTORS; i++)
            if (b->alive[i] && stk(b, i, ST_brand) > 0)
                if (t == NOTHING || stk(b, t, ST_brand) == 0)
                    t = i;
        if (t != NOTHING) {
            fx_pounce(b, t);
            play_drain(b);
        }
    }
}
