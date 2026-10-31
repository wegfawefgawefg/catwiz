/* The enemies' turn: tools/sim/foes.py (battle/turn.tsp end_turn, enemies_step,
   end_enemies; content/statuses turn_end) and the summons. */
#include "sim.h"
#include "tell.h"

/* n of by's kind's calls into empty spots; they wait for the next round */
void foes_summon(Battle *b, int by, int n) {
    int k = KINDS[b->kind[by]].calls;
    for (int j = 0; j < n; j++) {
        for (int i = 1; i < ACTORS; i++) {
            if (!b->alive[i]) {
                b_set_enemy(b, i, k);
                b->st[i][ST_FRESH] = 1;
                break;
            }
        }
    }
}

/* statuses.turn_end: wet dries, tangles go, fleas bite (the damage given back) */
static int status_end(Battle *b, int who) {
    int32_t *st = b->st[who];
    if (st[ST_WET] > 0)
        st[ST_WET]--;
    st[ST_TANGLE] = 0;
    int turns = st[ST_FLEA_TURNS];
    if (turns == 0)
        return 0;
    int bite = st[ST_POISON];
    st[ST_FLEA_TURNS] = (int32_t)(turns - 1);
    if (turns == 1)
        st[ST_POISON] = 0;
    return bite;
}

static int move_target(Battle *b, int by, int row) {
    const MoveRow *move = &MOVES[row];
    if (move->aim == A_self)
        return by;
    if (b->st[by][ST_LASER] && (move->effect == E_hit || move->effect == E_hit2)) {
        /* its hit goes to a friend; with no friend standing it comes at you */
        b->st[by][ST_LASER] = 0;
        for (int i = 1; i < ACTORS; i++)
            if (i != by && b->alive[i])
                return i;
        return HERO;
    }
    if (move->aim == A_friend) {
        for (int i = 1; i < ACTORS; i++)
            if (i != by && b->alive[i])
                return i;
        return by;
    }
    return HERO;
}

static void land_move(Battle *b, int row, int by, int target) {
    const MoveRow *move = &MOVES[row];
    if (b->tell)
        tell_move(b, by, row, target);
    if (move->aim == A_all && target == HERO && b->st[HERO][ST_BOX] > 0)
        return; /* a cardboard box: hit-alls miss */
    b_apply(b, move->effect, by, target, move->amount);
}

static void next_move(Battle *b, int i) {
    const KindRow *kind = &KINDS[b->kind[i]];
    int made = b->made[i] + 1;
    if (made >= kind->count)
        made = 0;
    b->made[i] = (uint8_t)made;
    b->move[i] = (uint8_t)(kind->first + made);
}

/* the hero's statuses tick, every enemy makes its move, theirs tick; the next round is
   b_start_round's, for the caller (a search may stop here and look) */
void foes_end_turn(Battle *b) {
    int32_t *st = b->st[HERO];
    items_turn_end(b);
    b->in_turn = 0;
    if (b->result != R_NONE)
        return;
    int bite = status_end(b, HERO);
    st[ST_SPOOK] = 0;
    if (bite)
        b_lose(b, HERO, bite);
    if (!b->alive[HERO]) {
        b->result = R_LOST;
        return;
    }
    for (int i = 1; i < ACTORS; i++) {
        if (b->alive[i]) {
            b->st[i][ST_SHIELD] = 0;
            b->st[i][ST_BOX] = 0;
            b->st[i][ST_REFLECT] = 0;
        }
    }
    for (int i = 1; i < ACTORS; i++) {
        if (!b->alive[i])
            continue;
        int32_t *si = b->st[i];
        if (si[ST_FRESH])
            continue;
        const KindRow *kind = &KINDS[b->kind[i]];
        if (kind->stall && si[ST_HURT] >= kind->stall) {
            if (b->tell)
                tell_line(b, "  %s STALLS", kind->name);
            continue;
        }
        int row = b->move[i];
        land_move(b, row, i, move_target(b, i, row));
        b_after_action(b);
        if (b->result != R_NONE)
            return;
    }
    for (int i = 1; i < ACTORS; i++) {
        if (b->alive[i]) {
            bite = status_end(b, i);
            if (bite)
                b_lose(b, i, bite);
        }
        if (b->alive[i]) {
            int32_t *si = b->st[i];
            si[ST_HURT] = 0;
            if (si[ST_FRESH])
                si[ST_FRESH] = 0;
            else
                next_move(b, i);
        }
    }
    if (!b->alive[1] && !b->alive[2] && !b->alive[3])
        b->result = R_WON;
}
