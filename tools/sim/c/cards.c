/* The chain and combo cards of the proposal (docs/balance.md): their effects, what a play
   sets off after it lands (dice that come back), mimic, and what a fallen enemy leaves
   (flea circus, haunted). tools/sim/cards.py. */
#include "sim.h"
#include "tell.h"

static int32_t sat(int64_t n) {
    return n > 255 ? 255 : (int32_t)n;
}

static int has(const Battle *b, int kind) {
    return b->k->charm_n[kind] > 0;
}

/* she does the picked enemy's shown move herself, times times: its hit on it (a hit-all on
   them all), its shield on her, its call a kitten, its cheer or growing a waiting plus, its
   healing on her, its curse on it, its reflect her thorns */
static void mimic(Battle *b, int t, int times) {
    const MoveRow *m = &MOVES[b->move[t]];
    int e = m->effect, n = m->amount;
    int32_t *sh = b->st[HERO];
    for (int j = 0; j < times; j++) {
        if (!b->alive[1] && !b->alive[2] && !b->alive[3])
            return;
        if (!b->alive[t]) {
            t = b_next_standing(b, t);
            if (t == NOTHING || t == HERO)
                return;
        }
        switch (e) {
        case E_hit:
        case E_hit2:
            if (m->aim == A_all) {
                for (int i = 1; i < ACTORS; i++)
                    if (b->alive[i])
                        b_strike(b, HERO, i, n, 0);
            } else {
                b_strike(b, HERO, t, n, 0);
                if (e == E_hit2 && b->alive[t])
                    b_strike(b, HERO, t, n, 0);
            }
            break;
        case E_shield:
            b_add(b, HERO, ST_SHIELD, n);
            break;
        case E_heal:
        case E_mend:
            b_heal(b, HERO, n);
            break;
        case E_summon: {
            int k = sh[ST_KITTENS] + n;
            sh[ST_KITTENS] = (int32_t)(k < KITTENS_MOST ? k : KITTENS_MOST);
            break;
        }
        case E_cheer:
        case E_grow:
            sh[ST_PLUS] = sat((int64_t)sh[ST_PLUS] + n);
            if (sh[ST_PLUS_LEFT] < 1)
                sh[ST_PLUS_LEFT] = 1;
            break;
        case E_fleas:
        case E_wet:
            b_curse(b, e, t, n);
            break;
        case E_reflect:
            if (sh[ST_THORNS] < n)
                sh[ST_THORNS] = n;
            break;
        }
    }
}

/* an enemy fell (b_lose): a flea circus's fleas jump to the next one, doubled; a haunted
   one hits every other enemy */
void items_fallen(Battle *b, int who, int fleas, int haunt) {
    if (fleas) {
        int j = b_next_standing(b, who);
        if (j != NOTHING && j != HERO) {
            b->st[j][ST_POISON] = sat((int64_t)fleas * 2);
            b->st[j][ST_FLEA_TURNS] = FLEA_TURNS;
            b->st[j][ST_CIRCUS] = 1;
            if (b->tell)
                tell_line(b, "  the fleas jump: %s fleas %d", KINDS[b->kind[j]].name,
                          b->st[j][ST_POISON]);
        }
    }
    if (haunt) {
        uint8_t wand = b->wand_on;
        b->wand_on = 0;
        if (b->tell)
            tell_line(b, "  the haunting: %d to all", haunt);
        for (int i = 1; i < ACTORS; i++)
            if (i != who && b->alive[i])
                b_strike(b, HERO, i, haunt, 0);
        b->wand_on = wand;
    }
}

/* the chain and combo cards' effects (items.c's effect hands them on): 1 if e is one */
int cards_effect(Battle *b, int e, int t, int n) {
    int32_t *sh = b->st[HERO];
    switch (e) {
    case E_swat: {
        int falls = b->falls;
        b_strike(b, HERO, t, n, 0);
        if (b->falls > falls)
            b->swat_back = 1; /* it fell: the die comes back (items_after_play) */
        break;
    }
    case E_habit:
        b_strike(b, HERO, t, n, 0);
        break;
    case E_mimic:
        mimic(b, t, n);
        break;
    case E_mirror:
        b_add(b, HERO, ST_SHIELD, n);
        b_add(b, HERO, ST_MIRROR, n);
        break;
    case E_dryoff:
        for (int i = 1; i < ACTORS; i++) {
            int w = b->st[i][ST_WET];
            if (b->alive[i] && w) {
                b_strike(b, HERO, i, sat((int64_t)n * w), 0);
                if (b->alive[i])
                    b->st[i][ST_WET] = 0;
            }
        }
        break;
    case E_circus: {
        int warded = b->st[t][ST_WARD] > 0;
        b_curse(b, E_fleas, t, n);
        if (!warded)
            b->st[t][ST_CIRCUS] = 1;
        break;
    }
    case E_catfight:
    case E_haunt:
        b_curse(b, e, t, n);
        break;
    case E_cough:
        b_strike(b, HERO, t, sat((int64_t)n * b->hair), 0);
        break;
    case E_paw:
        b_add(b, HERO, ST_SHIELD, n);
        b->rerolls = (int16_t)sat(b->rerolls + 1);
        b->t_gain = (uint8_t)sat(b->t_gain + 1);
        break;
    case E_sunbeam: {
        int m = sh[ST_MANA] + n, over = m > MOST_MANA ? m - MOST_MANA : 0;
        if (over > SUNBEAM_REROLLS)
            over = SUNBEAM_REROLLS;
        sh[ST_MANA] = (int32_t)(m < MOST_MANA ? m : MOST_MANA);
        b->rerolls = (int16_t)sat(b->rerolls + over); /* mana past the most */
        b->t_gain = (uint8_t)sat(b->t_gain + over);
        break;
    }
    default:
        return 0;
    }
    return 1;
}

/* after a die's face landed (and the battle checked who stands): what it set off. Its die
   comes back as it is (finishing swat felled one); or dice come back to be rolled again:
   every die (a wand hit on a red dot; nine lives when every die is used, once a fight) or
   big stretch's few (the used ones first, then dice that cannot be played). A battle with no
   rng (a search's copy) leaves them waiting in b->back. */
void items_after_play(Battle *b, int s) {
    int swat = b->swat_back, dot = b->dot_fired, stretch = b->stretch;
    b->swat_back = b->dot_fired = b->stretch = 0;
    if (b->result != R_NONE)
        return;
    if (swat) {
        b->played[s] = 0;
        b->t_swat = (uint8_t)sat(b->t_swat + 1);
    }
    int all = 0, mask = 0, used = 1, why = 0;
    for (int x = 0; x < b->hand_n; x++) {
        if (b->tray[x] == NOTHING)
            continue;
        all |= 1 << x;
        used &= b->played[x];
    }
    if (dot) {
        mask = all;
        why = 1;
    }
    if (stretch) {
        int k = 0;
        for (int pass = 0; pass < 2; pass++)
            for (int x = 0; x < b->hand_n && k < stretch; x++)
                if ((all >> x & 1) && (pass == 0 ? b->played[x] : !b->played[x] && !b_can_play(b, x))) {
                    mask |= 1 << x;
                    k++;
                }
        if (!why && mask)
            why = 2;
    }
    int32_t *st = b->st[HERO];
    if (!mask && has(b, K_nine) && !st[ST_NINE] && used) {
        st[ST_NINE] = 1;
        mask = all;
        why = 3;
    }
    if (!mask || b->refreshes >= (RULES.refresh_most ? RULES.refresh_most : REFRESH_MOST))
        return;
    b->refreshes++;
    if (why == 1)
        b->t_dot = (uint8_t)sat(b->t_dot + 1);
    else if (why == 2)
        b->t_stretch = (uint8_t)sat(b->t_stretch + 1);
    else
        b->t_nine = (uint8_t)sat(b->t_nine + 1);
    for (int x = 0; x < b->hand_n; x++)
        if (mask >> x & 1)
            b->played[x] = 0;
    b->back = (uint8_t)(b->back | mask);
    if (b->rng)
        items_roll_back(b);
}

/* the dice waiting in b->back are rolled (a hairball on one is coughed up first) */
void items_roll_back(Battle *b) {
    for (int x = 0; b->nclogged && x < b->hand_n; x++) {
        if ((b->back >> x & 1) && b->hand[x] == HAIRBALL) {
            int slot = b->face_of[x];
            if (b->clogged[slot] != NOTHING) {
                b->faces[slot] = b->clogged[slot];
                b->clogged[slot] = NOTHING;
                b->nclogged--;
            }
        }
    }
    for (int x = 0; x < b->hand_n; x++) {
        if (b->back >> x & 1) {
            int f = (int)((mt_bits(b->rng, 8) * 6) >> 8);
            b->face_of[x] = (uint8_t)f;
            b->hand[x] = b->faces[f];
            if (b->hand[x] == HAIRBALL && b->hair < 255)
                b->hair++;
        }
    }
    b->back = 0;
    if (b->tell)
        tell_back(b);
}

