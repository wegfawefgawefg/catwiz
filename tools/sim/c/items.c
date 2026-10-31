/* The item-slot model: tools/sim/items.py. A face's number (the item's amount and its slot's
   level), the boosts in their order, its effect, its combo when it is the third of its slot
   this turn; the kittens; the hairball that clogs a slot; the charms.

   Boosts on a played face, in this order: a pending times (a wand, fluff or book only: times
   m, and it counts m towards its slot's three), a pending plus (the next two dice of any
   slot), catnip's +1, knead (the next fluff x2, the next wand +n), bad milk (wands +1), a
   wishing star (the next wand x2), then a spook takes away. */
#include "sim.h"
#include "tell.h"

/* a charm's amount from the charm table, times how many of it the run holds */
int charm_amount(const Battle *b, int kind) {
    for (int c = 0; c < CHARM_COUNT; c++)
        if (CHARMS[c].kind == kind)
            return CHARMS[c].amount * b->k->charm_n[kind];
    return 0;
}

static int has(const Battle *b, int kind) {
    return b->k->charm_n[kind] > 0;
}

void items_fight_start(Battle *b) {
    int32_t *st = b->st[HERO];
    st[ST_KITTENS] = (int32_t)charm_amount(b, K_mother);
    if (has(b, K_badmilk) && BADMILK_FLEAS) {
        st[ST_POISON] = BADMILK_FLEAS; /* the old bad milk: fights start with fleas */
        st[ST_FLEA_TURNS] = FLEA_TURNS;
    }
}

/* the hero's turn begins (after her shield went): a kept shield, the charms, the combo counts
   start again */
void items_round_start(Battle *b) {
    int32_t *st = b->st[HERO];
    memset(b->combo, 0, sizeof b->combo);
    b->rerolled = 0;
    if (st[ST_KEEP]) {
        st[ST_SHIELD] = b->old_shield;
        st[ST_KEEP] = 0;
    }
    if (has(b, K_tail) && st[ST_SHIELD] < b->old_shield / 2)
        st[ST_SHIELD] = (int32_t)(b->old_shield / 2);
    b->rerolls = (int8_t)(b->rerolls + charm_amount(b, K_pocket) - charm_amount(b, K_toe));
}

/* a number past 2^20 (times two stacked for many turns: the Python sim's numbers have no
   end) kept the same mod 256 (a hit's damage is a byte) and above every cap (99) */
static int32_t fold(int64_t n) {
    if (n < (1 << 20))
        return (int32_t)n;
    return (int32_t)((n & 0xFF) + (1 << 20));
}

static void effect(Battle *b, int e, int t, int n);
static void combo(Battle *b, int c, int k, int t, int n);

static void trick(Battle *b, const ItemRow *face, int n) {
    int32_t *st = b->st[HERO];
    switch (face->effect) {
    case E_plus:
        /* +1 is wide: the next two dice get it, each hit and stack of them */
        if (st[ST_PLUS] < n)
            st[ST_PLUS] = (int32_t)n;
        st[ST_PLUS_LEFT] = PLUS_DICE;
        break;
    case E_double: {
        /* x2 is tall: the next wand, fluff or book, counted as two towards a three; played
           after a +1 it doubles that too */
        st[ST_PLUS] = fold((int64_t)st[ST_PLUS] * n);
        int m = st[ST_MULT] > 1 ? st[ST_MULT] : 1;
        st[ST_MULT] = fold((int64_t)m * n);
        if (RULES.mult_cap && st[ST_MULT] > RULES.mult_cap)
            st[ST_MULT] = RULES.mult_cap; /* a waiting times stacks this far at most */
        break;
    }
    case E_copy:
        if (b->last_face != NOTHING) {
            if (n) {
                st[ST_PLUS] = (int32_t)(st[ST_PLUS] + n);
                if (st[ST_PLUS_LEFT] < 1)
                    st[ST_PLUS_LEFT] = 1;
            }
            int on = b->alive[b->last_on] ? b->last_on : b->target;
            if (b->tell)
                tell_copy(b, b->last_face, on);
            items_land(b, b->last_face, on, 1);
        }
        break;
    case E_catnip2:
        b_add(b, HERO, ST_NIP, n);
        st[ST_NIPPED] = 1;
        break;
    case E_knead:
        st[ST_KNEAD_FLUFF] = 1;
        b_add(b, HERO, ST_KNEAD_WAND, n);
        break;
    default:
        tell_fail("trick the sim does not know: %s", EFFECT_NAME[face->effect]);
    }
}

/* a face lands: its number, the boosts, its effect, its combo */
void items_land(Battle *b, int row, int target, int again) {
    const ItemRow *face = &ITEMS[row];
    int32_t *st = b->st[HERO];
    int n = face->amount + b->k->level_of[row] * face->step;
    b->t_played |= 1ull << row;
    if (face->slot == S_trick) {
        trick(b, face, n);
        return;
    }
    int counts = 1;
    int base = n;
    if (st[ST_MULT] && (face->slot == S_wand || face->slot == S_fluff || face->slot == S_book)) {
        n = fold((int64_t)n * st[ST_MULT]);
        counts = st[ST_MULT];
        st[ST_MULT] = 0;
    }
    if (st[ST_PLUS_LEFT]) {
        n += st[ST_PLUS];
        st[ST_PLUS_LEFT]--;
        if (!st[ST_PLUS_LEFT])
            st[ST_PLUS] = 0;
    }
    if (st[ST_NIP]) {
        n += 1;
        st[ST_NIP]--;
    }
    if (face->slot == S_fluff && st[ST_KNEAD_FLUFF]) {
        n *= 2;
        st[ST_KNEAD_FLUFF] = 0;
    }
    if (face->slot == S_wand) {
        n += st[ST_KNEAD_WAND] + charm_amount(b, K_badmilk);
        st[ST_KNEAD_WAND] = 0;
        if (st[ST_WISH]) {
            n *= 2; /* a wishing star: the next wand times 2 */
            st[ST_WISH] = 0;
        }
    }
    if (n > base || again)
        b->t_sys |= SYS_TRICK; /* a boost used, or a copycat's copy */
    if (face->slot == S_wand && charm_amount(b, K_badmilk))
        b->t_sys |= SYS_CHARM;
    if (st[ST_SPOOK]) {
        n -= st[ST_SPOOK];
        if (n < 0)
            n = 0;
    }
    int before = b->combo[face->slot];
    b->combo[face->slot] = (uint8_t)(before + counts);
    int three = before < COMBO_AT && COMBO_AT <= before + counts;
    if (!again) {
        b->last_face = (uint8_t)row;
        b->last_on = (uint8_t)target;
    }
    if (b->tell)
        tell_number(b, n);
    if (face->slot == S_book) {
        /* with too little mana a book gives 1 mana instead (she studies it); a copycat's
           book is paid again; bad milk: books cost 1 more */
        int cost = face->cost + (BADMILK_FLEAS ? 0 : b->k->charm_n[K_badmilk]);
        if (st[ST_MANA] < cost) {
            if (b->tell)
                tell_line(b, "too little mana: she studies it, +1 mana");
            b_apply(b, E_mana, HERO, HERO, 1);
            return;
        }
        st[ST_MANA] = (int32_t)(st[ST_MANA] - cost);
        b->t_sys |= SYS_MANA;
    }
    effect(b, face->effect, target, n);
    if (three && face->combo != C_none) {
        if (b->tell)
            tell_combo(b, face->combo);
        b->t_sys |= SYS_COMBO;
        combo(b, face->combo, face->combo_n, target, n);
        if (has(b, K_trio)) {
            b->t_sys |= SYS_CHARM;
            int a = charm_amount(b, K_trio);
            for (int i = 1; i < ACTORS; i++)
                if (b->alive[i])
                    b_strike_plain(b, i, a);
        }
    }
}

/* every kitten pounces on t, times times: 1 each, more with mittens and marks */
static void pounce(Battle *b, int t, int times) {
    int hit = KITTEN_HIT + charm_amount(b, K_mittens);
    int n = b->st[HERO][ST_KITTENS] * times;
    if (n && b->alive[t])
        b->t_sys |= SYS_KITTEN | (charm_amount(b, K_mittens) ? SYS_CHARM : 0);
    if (b->tell && n && b->alive[t])
        tell_pounce(b, t, n, hit + b->st[t][ST_BRAND]);
    for (int i = 0; i < n; i++) {
        if (!b->alive[t])
            return;
        b_strike_plain(b, t, hit + b->st[t][ST_BRAND]);
    }
}

static void strip(Battle *b, int t) {
    b->st[t][ST_SHIELD] = 0;
    b->st[t][ST_CHEER] = 0;
    b->st[t][ST_STRENGTH] = 0;
    b->st[t][ST_REFLECT] = 0;
}

static void add_mana(Battle *b, int n) {
    b_apply(b, E_mana, HERO, HERO, n);
}

static void effect(Battle *b, int e, int t, int n) {
    int32_t *sh = b->st[HERO];
    if (e == E_kittens || ((e == E_litter || e == E_cannon || e == E_pile) && sh[ST_KITTENS]))
        b->t_sys |= SYS_KITTEN;
    switch (e) {
    case E_yarn:
        b_strike(b, HERO, t, n, 0);
        if (b->alive[t])
            b_curse(b, E_tangled, t, 1);
        break;
    case E_spray:
        b_strike(b, HERO, t, n, 0);
        if (b->alive[t])
            b_curse(b, E_wet, t, 1);
        break;
    case E_feather:
        b_strike(b, HERO, t, n, 0);
        pounce(b, t, 1);
        break;
    case E_pierce:
        b_strike(b, HERO, t, n, 1);
        break;
    case E_string: {
        b_strike(b, HERO, t, n, 0);
        int t2 = b_next_standing(b, t);
        if (t2 != NOTHING && t2 != HERO)
            b_strike(b, HERO, t2, n, 0);
        break;
    }
    case E_shoot:
        add_mana(b, 1);
        b_strike(b, HERO, t, n, 0);
        break;
    case E_moon:
        add_mana(b, 1);
        b_add(b, HERO, ST_SHIELD, n);
        break;
    case E_wish:
        add_mana(b, n);
        sh[ST_WISH] = 1;
        break;
    case E_litter:
        add_mana(b, n + sh[ST_KITTENS]);
        break;
    case E_kittens: {
        int k = sh[ST_KITTENS] + n;
        sh[ST_KITTENS] = (int32_t)(k < KITTENS_MOST ? k : KITTENS_MOST);
        break;
    }
    case E_laserall:
        for (int i = 1; i < ACTORS; i++) {
            if (b->alive[i]) {
                b_strike(b, HERO, i, n, 0);
                if (b->alive[i])
                    b->st[i][ST_LASER] = 1;
            }
        }
        break;
    case E_knock:
        strip(b, t);
        b_strike(b, HERO, t, n, 0);
        break;
    case E_cannon:
        b_strike(b, HERO, t, n * sh[ST_KITTENS], 0);
        break;
    case E_pile:
        b_add(b, HERO, ST_SHIELD, n + 2 * sh[ST_KITTENS]);
        break;
    case E_wet:
    case E_tangled:
    case E_brand:
        b_curse(b, e, t, n);
        break;
    default:
        b_apply(b, e, HERO, t, n);
    }
}

/* what the third fluff (or twig wand) in a turn adds; k: the item's combo_n, n: the face's
   number */
static void combo(Battle *b, int c, int k, int t, int n) {
    int32_t *sh = b->st[HERO];
    uint8_t live[ACTORS];
    int nl = 0;
    for (int i = 1; i < ACTORS; i++)
        if (b->alive[i])
            live[nl++] = (uint8_t)i;
    switch (c) {
    case C_sweep:
        for (int j = 0; j < nl; j++)
            if (live[j] != t)
                b_strike(b, HERO, live[j], n, 0);
        break;
    case C_keep:
        sh[ST_KEEP] = 1;
        break;
    case C_thorns:
        if (sh[ST_THORNS] < k)
            sh[ST_THORNS] = (int32_t)k;
        break;
    case C_box: {
        b->t_sys |= SYS_KITTEN;
        sh[ST_BOX] = 1;
        int kk = sh[ST_KITTENS] + k;
        sh[ST_KITTENS] = (int32_t)(kk < KITTENS_MOST ? kk : KITTENS_MOST);
        break;
    }
    case C_heal:
        b_heal(b, HERO, k);
        break;
    case C_static:
        for (int j = 0; j < nl; j++)
            b_strike(b, HERO, live[j], b->st[live[j]][ST_WET] ? k * 2 : k, 0);
        break;
    case C_ward:
        b_add(b, HERO, ST_WARD, k);
        break;
    default:
        tell_fail("combo the sim does not know: %d", c);
    }
}

/* before the hero's statuses tick: still water's mana, the kittens pounce (on a marked enemy
   first, else the leftmost), twice in a turn with catnip */
void items_turn_end(Battle *b) {
    int32_t *st = b->st[HERO];
    if (has(b, K_still) && !b->rerolled) {
        add_mana(b, charm_amount(b, K_still));
        b->t_sys |= SYS_CHARM;
    }
    int k = st[ST_KITTENS];
    int times = st[ST_NIPPED] ? 2 : 1;
    st[ST_NIPPED] = 0;
    st[ST_NIP] = 0;
    st[ST_KNEAD_FLUFF] = 0;
    st[ST_KNEAD_WAND] = 0;
    if (!k)
        return;
    for (int j = 0; j < times; j++) {
        int first = NOTHING, marked = NOTHING;
        for (int i = 1; i < ACTORS; i++) {
            if (!b->alive[i])
                continue;
            if (first == NOTHING)
                first = i;
            if (marked == NOTHING && b->st[i][ST_BRAND])
                marked = i;
        }
        if (first == NOTHING)
            break;
        pounce(b, marked != NOTHING ? marked : first, 1);
    }
    if (!b->alive[1] && !b->alive[2] && !b->alive[3])
        b->result = R_WON;
}

/* she lost hit points: a kitten runs off; grumpy face gives a mana */
void items_hero_hurt(Battle *b) {
    int32_t *st = b->st[HERO];
    if (st[ST_KITTENS] && RULES.kitten_rule == 0)
        st[ST_KITTENS]--;
    if (has(b, K_grumpy)) {
        int m = st[ST_MANA] + charm_amount(b, K_grumpy);
        st[ST_MANA] = (int32_t)(m < MOST_MANA ? m : MOST_MANA);
    }
}

/* a ward pip took a curse (hers or an enemy's): rubber duck's shield */
void items_ward_blocked(Battle *b) {
    if (has(b, K_duck)) {
        b_add(b, HERO, ST_SHIELD, charm_amount(b, K_duck));
        if (b->in_turn)
            b->t_sys |= SYS_CHARM;
    }
}

/* an enemy's hairball on face slot (0 wand, 1 fluff, ...) of every die, for the fight */
void items_clog(Battle *b, int slot) {
    if (b->clogged[slot] != NOTHING)
        return;
    b->clogged[slot] = b->faces[slot];
    b->nclogged++;
    b->faces[slot] = HAIRBALL;
}

/* a re-roll coughs up the hairballs the re-rolled dice show: their slots come back */
void items_cough(Battle *b) {
    b->rerolled = 1;
    if (!b->nclogged)
        return;
    for (int s = 0; s < b->hand_n; s++) {
        if (!b->played[s] && b->hand[s] == HAIRBALL) {
            int slot = b->face_of[s];
            if (b->clogged[slot] != NOTHING) {
                b->faces[slot] = b->clogged[slot];
                b->clogged[slot] = NOTHING;
                b->nclogged--;
            }
        }
    }
}
