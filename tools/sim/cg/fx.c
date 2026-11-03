/* A face's number and what playing it pays and counts: content/effects.tsp (cost, can_play,
   times, number, boosted, prepare, pounce, next_standing); and the charms: content/charms.tsp
   (amount, count, held, hook, dice, round_start, saved, hero_hurt). A row is content/items'
   row: 0-5 her slots, 6 the hairball, 19 the face a hat trick drew. */
#include "sim.h"
#include "tell.h"

int row_id(const Battle *b, int row) {
    if (row < 6)
        return b->k->items[row];
    if (row == HAT_ROW)
        return b->hat_id;
    return HAIRBALL_ID;
}

int row_slot(const Battle *b, int row) {
    return FACES[row_id(b, row)].slot;
}

int ch_amount(const Battle *b, int kind) {
    return b->k->kind_amount[kind];
}

int ch_count(const Battle *b, int kind) {
    return b->k->kind_count[kind];
}

int ch_held(const Battle *b, int kind) {
    return b->k->kind_count[kind] > 0;
}

/* effects.cost: a book's cost, bad milk's more, a cheap trick's less on the first book a
   turn; none for a face paid in hit points */
int fx_cost(const Battle *b, int row) {
    const FaceRow *f = &FACES[row_id(b, row)];
    if (f->tags & TAG_HP)
        return 0;
    int c = f->cost;
    if (f->slot == S_book) {
        c += ch_count(b, K_badmilk);
        if (!b->booked) {
            int less = ch_amount(b, K_cheap);
            c = c > less ? c - less : 0;
        }
    }
    return c;
}

int fx_can_play(const Battle *b, int row) {
    const FaceRow *f = &FACES[row_id(b, row)];
    if ((f->tags & TAG_HP) && b->hp[HERO] <= f->cost)
        return 0;
    if (f->slot == S_junk)
        return 0;
    return !(f->slot == S_book && her(b, ST_mana) < fx_cost(b, row));
}

uint8_t fx_times(int n, int m) {
    int out = 0;
    for (int k = 0; k < m; k++)
        out = sum8(out, n);
    return (uint8_t)out;
}

uint8_t fx_number(const Battle *b, int row) {
    const FaceRow *f = &FACES[row_id(b, row)];
    if (f->slot == S_junk)
        return 0;
    int n = f->amount + fx_times(f->step, b->k->level[f->slot]);
    if (n > 255)
        n = 255;
    if (f->tags & TAG_GROWS)
        n = sum8(n, her(b, ST_habit));
    return (uint8_t)n;
}

/* effects.boosted (use: the boosts are used up) */
static uint8_t boosted(Battle *b, int row, int use) {
    int slot = row_slot(b, row);
    int n = fx_number(b, row);
    b->counts = 1;
    if (slot == S_trick)
        return (uint8_t)n;
    int mult = her(b, ST_mult);
    if (mult > 0) {
        n = fx_times(n, mult);
        b->counts = (uint8_t)mult;
        if (use) {
            set_stk(b, HERO, ST_mult, 0);
            set_stk(b, HERO, ST_gamble, 0);
        }
    }
    if (her(b, ST_plus_left) > 0) {
        n = sum8(n, her(b, ST_plus));
        if (use) {
            set_stk(b, HERO, ST_plus_left, 0);
            set_stk(b, HERO, ST_plus, 0);
        }
    }
    int nip = her(b, ST_nip);
    if (nip > 0) {
        n = sum8(n, 1);
        if (use)
            set_stk(b, HERO, ST_nip, nip - 1);
    }
    if (slot == S_fluff) {
        int kf = her(b, ST_knead_fluff);
        if (kf > 0) {
            n = fx_times(n, kf);
            if (use)
                set_stk(b, HERO, ST_knead_fluff, 0);
        }
        n = sum8(n, ch_amount(b, K_coat));
    }
    if (slot == S_wand) {
        n = sum8(n, sum8(sum8(her(b, ST_knead_wand), her(b, ST_sharp)), ch_amount(b, K_badmilk)));
        if (use)
            set_stk(b, HERO, ST_knead_wand, 0);
        if (her(b, ST_wish) > 0) {
            n = sum8(n, n);
            if (use)
                set_stk(b, HERO, ST_wish, 0);
        }
    }
    int all = her(b, ST_allin);
    if (all > 0)
        n = fx_times(n, all);
    int spook = her(b, ST_spook);
    return (uint8_t)(n > spook ? n - spook : 0);
}

/* effects.prepare: the number after the boosts, the slot's count towards a three, the mana,
   what she played last (again: a copy) */
uint8_t fx_prepare(Battle *b, int row, int target, int again) {
    int slot = row_slot(b, row);
    uint8_t n = boosted(b, row, 1);
    int before = b->combo[slot];
    int after = sum8(before, b->counts);
    b->combo[slot] = (uint8_t)after;
    b->three = before < COMBO_AT && after >= COMBO_AT;
    if (!again) {
        b->last_face = (uint8_t)row;
        b->last_on = (uint8_t)target;
    }
    if (slot == S_book && !again) {
        set_stk(b, HERO, ST_mana, her(b, ST_mana) - fx_cost(b, row));
        b->booked = 1;
    }
    b->wand_on = slot == S_wand;
    return n;
}

/* effects.pounce: every kitten pounces on t */
void fx_pounce(Battle *b, int t) {
    int bite = KITTEN_HIT + ch_amount(b, K_mittens);
    int n = her(b, ST_kittens);
    for (int k = 0; k < n; k++) {
        if (!b->alive[t])
            return;
        hit_plain(b, t, sum8(bite, stk(b, t, ST_brand)));
    }
}

int fx_next_standing(const Battle *b, int t) {
    if (t == NOTHING)
        return NOTHING;
    for (int n = 0; n < 3; n++) {
        t++;
        if (t == ACTORS)
            t = 1;
        if (b->alive[t])
            return t;
    }
    return NOTHING;
}

/* ---- the charms (content/charms.tsp) */

/* charms.hook: the charms she holds for this moment wait to run, v their amount */
void ch_hook(Battle *b, int when) {
    const Setup *k = b->k;
    for (int h = 0; h < k->ncharms; h++) {
        const CharmRow *c = &CHARMS[k->charms[h]];
        if (c->when == when)
            hooks_add(b, FACE_COUNT + k->charms[h], HERO, c->amount * k->charm_n[h]);
    }
}

int ch_dice(const Setup *k) {
    int n = DICE + k->kind_amount[K_toe] + k->kind_count[K_cursedcoin];
    return n > DICE_MOST ? DICE_MOST : n;
}

/* charms.round_start: last turn's shield goes (a fluff three kept it; a fluffy tail keeps
   half); gives the turn's re-rolls */
int ch_round_start(Battle *b) {
    int old = her(b, ST_shield);
    set_stk(b, HERO, ST_shield, 0);
    set_stk(b, HERO, ST_box, 0);
    set_stk(b, HERO, ST_thorns, 0);
    set_stk(b, HERO, ST_mirror, 0);
    set_stk(b, HERO, ST_collar, 0);
    set_stk(b, HERO, ST_wall, 0);
    if (her(b, ST_keep) > 0) {
        set_stk(b, HERO, ST_shield, old);
        set_stk(b, HERO, ST_keep, 0);
    }
    if (ch_held(b, K_tail) && (old >> 1) > her(b, ST_shield))
        set_stk(b, HERO, ST_shield, old >> 1);
    int rolls = her(b, ST_rolls);
    set_stk(b, HERO, ST_rolls, 0);
    return (uint8_t)(REROLLS + ch_amount(b, K_pocket) - ch_amount(b, K_toe) + rolls);
}

/* charms.saved: nine lives, once a run */
int ch_saved(Battle *b) {
    const Setup *k = b->k;
    for (int h = 0; h < k->ncharms; h++) {
        const CharmRow *c = &CHARMS[k->charms[h]];
        if (c->when == W_dies && !(b->spent & (1 << h))) {
            b->spent |= (uint8_t)(1 << h);
            hooks_add(b, FACE_COUNT + k->charms[h], HERO, c->amount);
            return c->amount;
        }
    }
    return 0;
}

void ch_hero_hurt(Battle *b) {
    set_stk(b, HERO, ST_scars, sum8(her(b, ST_scars), 1));
    int kittens = her(b, ST_kittens);
    if (kittens > 0)
        set_stk(b, HERO, ST_kittens, kittens - 1);
    ch_hook(b, W_hurt);
}
