/* One battle: battle/battle.tsp's fight start (enter_fight), battle/turn.tsp (start_round,
   showing, play_selected, select's paw flip, reroll, after_action, end_battle, turn_end,
   end_turn, enemies_step, end_enemies) and battle/dice.tsp (deal, roll, turn, back, cough).
   The players call b_play, b_reroll and b_end_turn; the run calls b_start_round. */
#include "sim.h"
#include "tell.h"

int b_any_enemy(const Battle *b) {
    return b->alive[1] || b->alive[2] || b->alive[3];
}

static int item_on(const Battle *b, int f) {
    return b->clogged[f] ? JUNK_ROW : f;
}

void b_roll_die(Battle *b, int d, int f) {
    b->face_of[d] = (uint8_t)f;
    b->hand[d] = (uint8_t)item_on(b, f);
}

static void roll(Battle *b, int d) {
    b_roll_die(b, d, (rnd_byte(b) * 6) >> 8);
}

/* dice.cough: the hairballs the unplayed dice show are coughed up */
static void cough(Battle *b) {
    for (int d = 0; d < DICE_MOST; d++)
        if (!b->played[d] && b->hand[d] == JUNK_ROW)
            b->clogged[b->face_of[d]] = 0;
}

void b_end_battle(Battle *b, int won) {
    if (won) {
        int k = her(b, ST_kittens);
        b->kept = (uint8_t)(k - (k >> 1));
    }
    b->result = won ? R_WON : R_LOST;
}

/* turn.showing: a jackpot (five alike win the fight), a lucky seven (five different) */
static int showing(Battle *b) {
    if (!(ch_held(b, K_jackpot) || ch_held(b, K_lucky7)))
        return 0;
    int seen = 0, most = 0;
    for (int f = 0; f < 6; f++) {
        int k = 0;
        for (int d = 0; d < b->dice_n; d++)
            if (b->held[d] == NOTHING && b->face_of[d] == f)
                k++;
        if (k > 0)
            seen++;
        if (k > most)
            most = k;
    }
    if (most >= 5 && ch_held(b, K_jackpot)) {
        for (int i = 1; i < ACTORS; i++)
            b->alive[i] = 0;
        if (b->tell)
            tell_line(b, "  JACKPOT: five alike win the fight");
        b_end_battle(b, 1);
        return 1;
    }
    if (seen >= 5 && ch_held(b, K_lucky7) && !b->lucky) {
        b->lucky = 1;
        b->rerolls = (uint8_t)(b->rerolls + LUCKY_REROLLS);
        if (b->rerolls > REROLLS_MOST)
            b->rerolls = REROLLS_MOST;
    }
    return 0;
}

static void fix_target(Battle *b) {
    if (b->alive[b->target])
        return;
    int t = b->target;
    for (int n = 0; n < 3; n++) {
        t++;
        if (t == ACTORS)
            t = 1;
        if (b->alive[t]) {
            b->target = (uint8_t)t;
            return;
        }
    }
}

/* battle.enter_fight */
void b_init(Battle *b, const Setup *k, int hp, int maxhp, int fight, uint8_t spent, int kept,
            Mt *rng) {
    memset(b, 0, sizeof *b);
    b->k = k;
    b->rng = rng;
    b->spent = spent;
    b->kept = (uint8_t)kept;
    b->target = 1;
    b->last_face = NOTHING;
    b->last_on = HERO;
    b->last_played = NOTHING;
    b->dice_n = (uint8_t)ch_dice(k);
    for (int d = 0; d < DICE_MOST; d++) {
        b->held[d] = NOTHING;
        b->played[d] = 1;
    }
    b->nap_die = NOTHING;
    b->alive[HERO] = 1;
    b->kind[HERO] = NOTHING;
    b->hp[HERO] = (uint8_t)hp;
    b->maxhp[HERO] = (uint8_t)maxhp;
    st_start(b, HERO, NOTHING);
    const FightRow *f = &FIGHTS[fight];
    for (int i = 1; i < ACTORS; i++) {
        b->kind[i] = NOTHING;
        if (i <= f->count)
            spawn_enemy(b, i, f->enemies[i - 1], 0);
    }
    ch_hook(b, W_fight_start);
    play_drain(b);
}

/* turn.start_round, with dice.deal and the roll (a nap spot's die keeps its face) */
void b_start_round(Battle *b) {
    b->turn++;
    b->rerolls = (uint8_t)ch_round_start(b);
    b->in_turn = 1;
    ch_hook(b, W_turn_start);
    play_drain(b);
    b->rerolled = 0;
    b->refreshes = 0;
    b->risen = 0;
    b->back_due = 0;
    b->booked = 0;
    b->lucky = 0;
    b->back = 0;
    b->last_played = NOTHING;
    memset(b->combo, 0, sizeof b->combo);
    b->t_dmg = 0;
    b->t_played = 0;
    for (int i = 0; i < ACTORS; i++) {
        b->full_at_start[i] = i > 0 && b->alive[i] && b->hp[i] == b->maxhp[i];
        b->kind_at_start[i] = b->kind[i];
    }
    for (int d = 0; d < DICE_MOST; d++)
        b->played[d] = d >= b->dice_n || b->held[d] != NOTHING;
    for (int d = 0; d < DICE_MOST; d++) {
        if (b->played[d])
            continue;
        if (d == b->nap_die)
            b->nap_die = NOTHING;
        else
            roll(b, d);
    }
    if (showing(b))
        return;
    fix_target(b);
}

int b_can_play(const Battle *b, int d) {
    if (d >= DICE_MOST || b->played[d] || (b->back >> d & 1))
        return 0;
    return fx_can_play(b, b->hand[d]);
}

int b_playable_count(const Battle *b) {
    int n = 0;
    for (int d = 0; d < DICE_MOST; d++)
        n += b_can_play(b, d);
    return n;
}

int b_any_unplayed(const Battle *b) {
    for (int d = 0; d < DICE_MOST; d++)
        if (!b->played[d] && !(b->back >> d & 1))
            return 1;
    return 0;
}

int b_can_reroll(const Battle *b) {
    return b->result == R_NONE && b->rerolls > 0 && her(b, ST_allin) == 0 && !b->back &&
           b_any_unplayed(b);
}

/* the turn ends by itself: every die played, or none playable and no re-roll left */
int b_turn_over(const Battle *b) {
    if (b->result != R_NONE)
        return 1;
    if (b->back)
        return 0;
    if (b_playable_count(b) == 0)
        return !b_any_unplayed(b) || !b_can_reroll(b);
    return 0;
}

int b_face_aim(const Battle *b, int d) {
    return FACES[row_id(b, b->hand[d])].aim;
}

/* dice.back: every die she rolls comes back (one an enemy holds stays out), then they roll;
   a search's copy (no rng) leaves them waiting in b->back */
static void dice_back(Battle *b) {
    uint8_t mask = 0;
    for (int d = 0; d < b->dice_n; d++) {
        if (b->held[d] == NOTHING) {
            b->played[d] = 0;
            mask |= (uint8_t)(1 << d);
        }
    }
    cough(b);
    if (!b->rng && !b->xs_on) {
        b->back = mask;
        return;
    }
    for (int d = 0; d < DICE_MOST; d++)
        if (mask >> d & 1)
            roll(b, d);
    showing(b);
}

/* turn.after_action for her face: the fight may be over; else her dice come back when the
   face set that off, BACK_MOST times a turn at most */
static void after_face(Battle *b) {
    if (!b->alive[HERO]) {
        b_end_battle(b, 0);
        return;
    }
    if (!b_any_enemy(b)) {
        b_end_battle(b, 1);
        return;
    }
    if (b->back_due) {
        b->back_due = 0;
        if (b->refreshes < BACK_MOST) {
            b->refreshes++;
            if (b->refreshes == BACK_MOST)
                b->peak.back_cap_turns++;
            if (b->tell)
                tell_line(b, "  all the dice come back");
            dice_back(b);
        }
    }
    fix_target(b);
}

/* turn.play_selected (and select's paw flip: a target with FLIP turns die d to that face) */
void b_play(Battle *b, int d, int target) {
    if (target != NOTHING && (target & FLIP)) {
        b_roll_die(b, d, target & 7);
        b->flip_next = (uint8_t)(d + 1); /* the search turns each die once, left to right */
        return;
    }
    int row = b->hand[d];
    set_stk(b, HERO, ST_flip, 0);
    b->flip_next = 0;
    b->played[d] = 1;
    b->last_played = (uint8_t)d;
    int id = row_id(b, row);
    if (id < 64)
        b->t_played |= 1ull << id;
    /* a die for an enemy goes to the one picked (a hat trick's target is picked before it) */
    if ((FACES[id].aim == A_foe || id == ID_HAT_TRICK) && target != NOTHING && target < ACTORS &&
        target > 0 && b->alive[target])
        b->target = (uint8_t)target;
    int t = FACES[id].aim == A_self ? HERO : b->target;
    if (b->tell)
        tell_play(b, row, t);
    play_land_face(b, row, t);
    after_face(b);
    if (b->tell)
        tell_play_done(b);
}

void b_reroll(Battle *b) {
    uint8_t faces[MAX_HAND];
    for (int d = 0; d < DICE_MOST; d++)
        faces[d] = b->played[d] ? b->face_of[d] : (uint8_t)((rnd_byte(b) * 6) >> 8);
    b_reroll_to(b, faces);
}

void b_reroll_to(Battle *b, const uint8_t *faces) {
    b->rerolls--;
    b->rerolled = 1;
    cough(b);
    for (int d = 0; d < DICE_MOST; d++)
        if (!b->played[d])
            b_roll_die(b, d, faces[d]);
    if (b->tell)
        tell_reroll(b);
    showing(b);
}

void b_back_to(Battle *b, const uint8_t *faces) {
    for (int d = 0; d < DICE_MOST; d++)
        if (b->back >> d & 1)
            b_roll_die(b, d, faces[d]);
    b->back = 0;
    showing(b);
}

/* turn.turn_end: fleas bite who (an enemy's twice with itchy) */
static void turn_end_of(Battle *b, int who) {
    int hurt = st_turn_end(b, who);
    int bites = who != HERO && ch_held(b, K_itchy) ? 2 : 1;
    for (int k = 0; k < bites; k++) {
        if (hurt > 0) {
            hit_lose(b, who, hurt);
            play_drain(b);
        }
    }
}

static void end_enemies(Battle *b) {
    for (int i = 1; i < ACTORS; i++) {
        if (b->alive[i])
            turn_end_of(b, i);
        if (b->alive[i]) {
            set_stk(b, i, ST_hurt, 0);
            if (st_skips(b, i)) {
                set_stk(b, i, ST_fresh, 0);
                set_stk(b, i, ST_sleep, 0);
            } else {
                foes_next_move(b, i);
            }
        }
    }
    if (!b_any_enemy(b))
        b_end_battle(b, 1);
}

/* turn.end_turn, the enemies' moves (enemies_step) and end_enemies; the next round is
   b_start_round's, for the caller (a search stops here and looks) */
void b_end_turn(Battle *b) {
    if (b->result != R_NONE)
        return;
    b->back = 0;
    b->nap_die = NOTHING;
    if (ch_held(b, K_nap))
        for (int d = 0; d < b->dice_n; d++)
            if (b->nap_die == NOTHING && !b->played[d] && b->hand[d] != JUNK_ROW)
                b->nap_die = (uint8_t)d;
    play_turn_end(b);
    if (b->t_dmg > b->peak.turn_dmg_max)
        b->peak.turn_dmg_max = (uint16_t)(b->t_dmg < 65535 ? b->t_dmg : 65535);
    b->in_turn = 0;
    if (!b_any_enemy(b)) {
        b_end_battle(b, 1);
        return;
    }
    turn_end_of(b, HERO);
    b->risen = 0;
    set_stk(b, HERO, ST_spook, 0);
    if (!b->alive[HERO]) {
        b_end_battle(b, 0);
        return;
    }
    for (int i = 1; i < ACTORS; i++) {
        if (b->alive[i]) {
            set_stk(b, i, ST_shield, 0);
            set_stk(b, i, ST_reflect, 0);
            set_stk(b, i, ST_mleech, 0);
        }
    }
    for (int i = 1; i < ACTORS; i++) {
        if (!b->alive[i])
            continue;
        if (foes_skips(b, i))
            continue;
        int row = b->move[i];
        foes_land_move(b, row, i, foes_move_target(b, i, row, 1));
        if (!b->alive[HERO]) {
            b_end_battle(b, 0);
            return;
        }
        if (!b_any_enemy(b)) {
            b_end_battle(b, 1);
            return;
        }
    }
    end_enemies(b);
}
