/* One battle, step by step: tools/sim/rules.py (Battle), which copies the game's battle/
   files and content/effects.tsp, statuses.tsp. Actor 0 is the hero, 1-3 the enemies. A battle is a
   plain struct: a search copies it with =. */
#include "sim.h"
#include "tell.h"

Rules RULES = {1, 4, 0}; /* the sixth toe's die, a waiting times x4 at most (main.c) */

void b_set_enemy(Battle *b, int i, int k) {
    const KindRow *kind = &KINDS[k];
    b->kind[i] = (uint8_t)k;
    b->hp[i] = kind->hp;
    b->maxhp[i] = kind->hp;
    b->alive[i] = 1;
    b->move[i] = kind->first;
    b->made[i] = 0;
    memset(b->st[i], 0, sizeof b->st[i]);
    b->st[i][ST_WARD] = kind->ward;
}

/* Battle.__init__ and play_fight's max hit points */
void b_init(Battle *b, const Setup *k, int hero_hp, int maxhp, const uint8_t *enemies, int n,
            Mt *rng) {
    memset(b, 0, sizeof *b);
    b->k = k;
    b->rng = rng;
    memcpy(b->faces, k->items, 6);
    memset(b->clogged, NOTHING, 6);
    for (int i = 0; i < ACTORS; i++)
        b->kind[i] = NOTHING;
    b->hp[HERO] = (int32_t)hero_hp;
    b->maxhp[HERO] = (int32_t)maxhp;
    b->alive[HERO] = 1;
    for (int i = 0; i < n; i++)
        b_set_enemy(b, i + 1, enemies[i]);
    b->ndice = (uint8_t)k->ndice;
    for (int d = 0; d < b->ndice; d++) {
        b->in_draw[d] = 1;
        b->held[d] = NOTHING;
    }
    b->hand_n = (uint8_t)(HAND + k->charm_n[K_toe]);
    for (int s = 0; s < b->hand_n; s++) {
        b->tray[s] = NOTHING;
        b->played[s] = 1;
    }
    b->target = 1;
    b->last_played = NOTHING;
    b->last_face = NOTHING;
    b->last_on = 1;
    b->result = R_NONE;
    items_fight_start(b);
}

/* ---- the bag: battle/bag.tsp (every die is the same in the item model, but the draw takes
   the game's random bytes, so the dice match the Python sim's) */

static int draw_count(const Battle *b) {
    int n = 0;
    for (int d = 0; d < b->ndice; d++)
        n += b->in_draw[d];
    return n;
}

static int in_tray(const Battle *b, int d) {
    for (int s = 0; s < b->hand_n; s++)
        if (b->tray[s] == d)
            return 1;
    return 0;
}

static int draw_one(Battle *b) {
    if (draw_count(b) == 0) {
        for (int d = 0; d < b->ndice; d++)
            if (!in_tray(b, d) && b->held[d] == NOTHING)
                b->in_draw[d] = 1;
    }
    int n = draw_count(b);
    if (n == 0)
        return NOTHING;
    int k = (int)(mt_bits(b->rng, 8) & 7);
    while (k >= n)
        k = (int)(mt_bits(b->rng, 8) & 7);
    for (int d = 0; d < b->ndice; d++) {
        if (b->in_draw[d]) {
            if (k == 0) {
                b->in_draw[d] = 0;
                return d;
            }
            k--;
        }
    }
    return NOTHING;
}

static void deal(Battle *b) {
    for (int s = 0; s < b->hand_n; s++)
        b->tray[s] = NOTHING;
    for (int s = 0; s < b->hand_n; s++) {
        int d = draw_one(b);
        b->tray[s] = (uint8_t)d;
        b->played[s] = d == NOTHING;
    }
}

/* turn.roll_step: the unplayed dice get a random face each (a byte times 6 over 256) */
void b_roll(Battle *b) {
    for (int s = 0; s < b->hand_n; s++) {
        if (!b->played[s]) {
            int f = (int)((mt_bits(b->rng, 8) * 6) >> 8);
            b->face_of[s] = (uint8_t)f;
            b->hand[s] = b->faces[f];
        }
    }
}

/* ---- the hero's turn: battle/turn.tsp */

static void fix_target(Battle *b) {
    if (b->alive[b->target])
        return;
    int t = b->target;
    for (int i = 0; i < 3; i++) {
        t++;
        if (t == ACTORS)
            t = 1;
        if (b->alive[t]) {
            b->target = (uint8_t)t;
            return;
        }
    }
}

void b_start_round(Battle *b) {
    int32_t *st = b->st[HERO];
    b->turn++;
    b->old_shield = st[ST_SHIELD];
    st[ST_SHIELD] = 0;
    st[ST_BOX] = 0;
    st[ST_THORNS] = 0;
    b->rerolls = REROLLS;
    b->last_played = NOTHING;
    b->lost_this_round = 0;
    b->t_dmg = 0;
    b->t_sys = 0;
    b->t_played = 0;
    b->in_turn = 1;
    items_round_start(b);
    if (b->result != R_NONE)
        return;
    deal(b);
    b_roll(b);
    fix_target(b);
}

int b_can_play(const Battle *b, int s) {
    if (b->played[s])
        return 0;
    const ItemRow *face = &ITEMS[b->hand[s]];
    if (face->slot == S_junk)
        return 0; /* a hairball: only a re-roll coughs it up */
    if (face->slot == S_book)
        return 1; /* a book with too little mana gives 1 mana */
    return face->cost <= b->st[HERO][ST_MANA];
}

int b_playable_count(const Battle *b) {
    int n = 0;
    for (int s = 0; s < b->hand_n; s++)
        n += b_can_play(b, s);
    return n;
}

int b_any_unplayed(const Battle *b) {
    for (int s = 0; s < b->hand_n; s++)
        if (!b->played[s])
            return 1;
    return 0;
}

/* the turn ends by itself: every die played, or none playable and no re-roll left */
int b_turn_over(const Battle *b) {
    if (b->result != R_NONE)
        return 1;
    if (b_playable_count(b) == 0)
        return !b_any_unplayed(b) || b->rerolls == 0;
    return 0;
}

/* turn.play_selected */
void b_play(Battle *b, int s, int target) {
    int row = b->hand[s];
    const ItemRow *face = &ITEMS[row];
    int t;
    b->played[s] = 1;
    b->last_played = b->tray[s];
    if (face->aim == A_self) {
        t = HERO;
    } else {
        if (target != NOTHING && face->aim == A_foe)
            b->target = (uint8_t)target;
        t = b->target;
    }
    if (b->tell)
        tell_play(b, row, t);
    items_land(b, row, t, 0);
    b_after_action(b);
    if (b->tell)
        tell_play_done(b);
}

void b_reroll(Battle *b) {
    uint8_t before[MAX_HAND];
    memcpy(before, b->hand, sizeof before);
    b->rerolls--;
    items_cough(b);
    b_roll(b);
    if (b->tell)
        tell_reroll(b, before);
}

void b_after_action(Battle *b) {
    int any = b->alive[1] || b->alive[2] || b->alive[3];
    if (!b->alive[HERO])
        b->result = R_LOST;
    else if (!any)
        b->result = R_WON;
    else
        fix_target(b);
}

/* ---- effects.apply: the one match on the effect kind (the moves', and the items' plain
   ones; items.c has the items' own) */

void b_apply(Battle *b, int effect, int by, int target, int n) {
    switch (effect) {
    case E_hit:
        b_strike(b, by, target, n, 0);
        break;
    case E_shield:
        b_add(b, target, ST_SHIELD, n);
        break;
    case E_heal:
        b_heal(b, target, n);
        break;
    case E_mana: {
        int m = b->st[HERO][ST_MANA] + n;
        b->st[HERO][ST_MANA] = (int32_t)(m < MOST_MANA ? m : MOST_MANA);
        break;
    }
    case E_zoomies: {
        int t = 0;
        for (int i = 0; i < ZOOMIES_HITS; i++) {
            t = b_next_standing(b, t);
            if (t != NOTHING)
                b_strike(b, by, t, n, 0);
        }
        break;
    }
    case E_scream:
        for (int i = 1; i < ACTORS; i++)
            if (b->alive[i])
                b_strike(b, by, i, n, 0);
        b_lose(b, HERO, SCREAM_SELF);
        break;
    case E_cheer:
        b_add(b, target, ST_CHEER, n);
        break;
    case E_nothing:
    case E_plus:
    case E_double:
    case E_wait:
        break;
    case E_fleas:
    case E_wet:
    case E_spook:
        b_curse(b, effect, target, n);
        break;
    case E_hit2:
        b_strike(b, by, target, n, 0);
        if (b->alive[target])
            b_strike(b, by, target, n, 0);
        break;
    case E_mend:
        for (int i = 1; i < ACTORS; i++)
            if (i != by && b->alive[i])
                b_heal(b, i, n);
        break;
    case E_summon:
        foes_summon(b, by, n);
        break;
    case E_steal: {
        int d = b->last_played;
        if (d != NOTHING && b->held[d] == NOTHING) {
            b->held[d] = (uint8_t)by;
            b->in_draw[d] = 0;
            if (b->tell)
                tell_line(b, "  %s TAKES A DIE", KINDS[b->kind[by]].name);
        }
        break;
    }
    case E_grow:
        b_add(b, by, ST_STRENGTH, n);
        break;
    case E_reflect:
        b_add(b, by, ST_REFLECT, n);
        break;
    case E_junk:
        items_clog(b, n);
        break;
    default:
        tell_fail("effect the sim does not know: %s", EFFECT_NAME[effect]);
    }
}

/* effects.next_standing, with the proposals' fix: no zoomies at the cat */
int b_next_standing(const Battle *b, int t) {
    for (int i = 0; i < 3; i++) {
        t = (t + 1) & 0xFF;
        if (t == ACTORS)
            t = 1;
        if (t < ACTORS && b->alive[t]) {
            if (t == HERO)
                return NOTHING;
            return t;
        }
    }
    return NOTHING;
}

/* effects.curse: always lands; a ward pip breaks instead */
void b_curse(Battle *b, int effect, int target, int n) {
    int32_t *st = b->st[target];
    if (st[ST_WARD] > 0) {
        st[ST_WARD]--;
        items_ward_blocked(b);
        if (b->tell)
            tell_status(b, target, -1, 0);
        return;
    }
    switch (effect) {
    case E_fleas:
        b_add(b, target, ST_POISON, n);
        st[ST_FLEA_TURNS] = FLEA_TURNS;
        break;
    case E_wet: {
        int w = st[ST_WET];
        if (n > w)
            w = n;
        if (w < 1)
            w = 1;
        st[ST_WET] = (int32_t)w;
        break;
    }
    case E_spook:
        b_add(b, target, ST_SPOOK, n);
        break;
    case E_brand:
        b_add(b, target, ST_BRAND, n);
        break;
    case E_tangled:
        b_add(b, target, ST_TANGLE, n);
        break;
    default:
        st[ST_SHIELD] = 0;
    }
    if (b->in_turn && target != HERO)
        b->t_sys |= SYS_STATUS;
    if (b->tell)
        tell_status(b, target, effect, n);
}

/* ---- battle/hit.tsp */

static int dealt(Battle *b, int who, int damage) {
    int32_t *st = b->st[who];
    int cheer = st[ST_CHEER];
    st[ST_CHEER] = 0;
    int d = (damage + cheer + st[ST_STRENGTH]) & 0xFF;
    if (st[ST_TANGLE]) {
        d -= st[ST_TANGLE];
        if (d < 0)
            d = 0;
    }
    if (st[ST_WET] > 0)
        d >>= 1;
    return d;
}

void b_strike(Battle *b, int by, int target, int amount, int pierce) {
    if (by == HERO && target == HERO)
        b->self_hits++;
    int damage = dealt(b, by, amount);
    int32_t *st = b->st[target];
    damage += st[ST_BRAND];
    if (st[ST_BRAND] && by == HERO)
        b->t_sys |= SYS_STATUS; /* a marked hit */
    if (st[ST_REFLECT] && by == HERO) {
        int back = st[ST_REFLECT] < damage ? st[ST_REFLECT] : damage;
        st[ST_REFLECT] = (int32_t)(st[ST_REFLECT] - back);
        damage -= back;
        b_strike_plain(b, HERO, back);
    }
    if (b->tell && by == HERO)
        tell_hit(b, target, damage);
    if (pierce)
        b_lose(b, target, damage);
    else
        b_strike_plain(b, target, damage);
    if (target == HERO && by != HERO && b->st[HERO][ST_THORNS])
        b_lose(b, by, b->st[HERO][ST_THORNS]);
}

/* statuses.taken, then hit.lose */
void b_strike_plain(Battle *b, int target, int damage) {
    int32_t *st = b->st[target];
    int shield = st[ST_SHIELD];
    if (shield >= damage) {
        st[ST_SHIELD] = (int32_t)(shield - damage);
        return;
    }
    st[ST_SHIELD] = 0;
    b_lose(b, target, damage - shield);
}

static void release(Battle *b, int who) {
    for (int d = 0; d < b->ndice; d++) {
        if (b->held[d] == who) {
            b->held[d] = NOTHING;
            b->in_draw[d] = 1;
        }
    }
}

static void die(Battle *b, int who) {
    if (who == HERO) {
        b->alive[HERO] = 0;
        return;
    }
    int then = KINDS[b->kind[who]].then;
    release(b, who);
    if (then != NOTHING) {
        /* the possum gets up, the elites' second forms, the boss's next phase: a round to
           get up, it skips one move */
        b_set_enemy(b, who, then);
        b->st[who][ST_FRESH] = 1;
        if (b->tell)
            tell_line(b, "  %s GETS UP", KINDS[then].name);
        return;
    }
    b->alive[who] = 0;
    if (b->tell)
        tell_beaten(b, who);
}

void b_lose(Battle *b, int who, int n) {
    if (!b->alive[who])
        return;
    int hp = b->hp[who];
    if (n > hp)
        n = hp;
    b->hp[who] = (int32_t)(hp - n);
    if (who == HERO) {
        b->hero_lost += n;
        b->lost_this_round += n;
        if (n > 0)
            items_hero_hurt(b);
    } else {
        b->st[who][ST_HURT] = (int32_t)(b->st[who][ST_HURT] + n);
        if (b->in_turn)
            b->t_dmg += n;
    }
    if (hp - n == 0)
        die(b, who);
}

void b_heal(Battle *b, int who, int n) {
    int hp = b->hp[who] + n;
    if (hp > b->maxhp[who])
        hp = b->maxhp[who];
    if (who == HERO)
        b->hero_healed += hp - b->hp[who];
    b->hp[who] = (int32_t)hp;
}

void b_add(Battle *b, int who, int status, int n) {
    int v = b->st[who][status] + n;
    b->st[who][status] = (int32_t)(v < 99 ? v : 99);
}

void b_end_turn(Battle *b) {
    foes_end_turn(b);
}
