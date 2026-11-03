/* The kit and the choices between fights, as battle/reward.tsp and battle/offer.tsp have them:
   after a won fight five cards drawn from the faces' pool (each face by its weight, the six
   upgrades by theirs; five different; a level, a held face or an upgrade, only on a slot below
   ITEM_MOST); after an elite three charms she does not hold, drawn the same way (ninth life's
   hit points first), then the nap (every hit point back) or a level on a slot of her choice;
   the doors before a fight that has another. A card or a charm may be skipped.

   random picks any option; greedy the one that most raises the kit's worth by a rough table
   (kit_worth); strong tries each option in rollouts of the next fight; search (draft.c). */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "run.h"

#define ROLLOUTS 6

const Kit *START_KIT = NULL;
int BLANK_SLOT = NOTHING;
uint64_t OFFER_SALT = 0;

void kit_start(Kit *kit) {
    memset(kit, 0, sizeof *kit);
    memcpy(kit->items, STARTING_ITEMS, 6);
    kit->hp_max = HERO_HP;
}

int kit_has(const Kit *kit, int kind) {
    for (int i = 0; i < kit->ncharms; i++)
        if (CHARMS[kit->charms[i]].kind == kind)
            return 1;
    return 0;
}

int kit_holds(const Kit *kit, int charm) {
    for (int i = 0; i < kit->ncharms; i++)
        if (kit->charms[i] == charm)
            return 1;
    return 0;
}

/* charms.refresh: the kinds' totals, a mana battery's mana */
void kit_setup(const Kit *kit, Setup *k) {
    memset(k, 0, sizeof *k);
    memcpy(k->items, kit->items, 6);
    memcpy(k->level, kit->level, 6);
    k->ncharms = kit->ncharms;
    for (int h = 0; h < kit->ncharms; h++) {
        const CharmRow *c = &CHARMS[kit->charms[h]];
        k->charms[h] = kit->charms[h];
        k->charm_n[h] = 1;
        k->kind_amount[c->kind] = (uint8_t)(k->kind_amount[c->kind] + c->amount);
        k->kind_count[c->kind]++;
    }
    k->mana_most = (uint8_t)(MOST_MANA + k->kind_amount[K_battery]);
}

Force FORCE = {0, 0, 0, 0};
Force PLAN[PLAN_MOST];
int NPLAN = 0;

const Force *forced_at(int kind, int after) {
    if (FORCE.on && FORCE.kind == kind && FORCE.after == after)
        return &FORCE;
    for (int i = 0; i < NPLAN; i++)
        if (PLAN[i].kind == kind && PLAN[i].after == after)
            return &PLAN[i];
    return NULL;
}

/* ---- the draw (battle/offer.tsp) */

static int card_slot(int c) {
    return c >= UP_CARD ? c - UP_CARD : FACES[c].slot;
}

static int levels(const Kit *kit, int c) {
    return c >= UP_CARD || kit->items[card_slot(c)] == c;
}

static int card_ok(const Kit *kit, int c) {
    if (!levels(kit, c))
        return !(kit->locked >> card_slot(c) & 1);
    return kit->level[card_slot(c)] < ITEM_MOST;
}

static int card_what(const Kit *kit, int c) {
    return levels(kit, c) ? UP_CARD + card_slot(c) : c;
}

static int pool_of(int charms, uint8_t *what, uint8_t *weight) {
    int n = 0;
    if (charms) {
        for (int c = 0; c < CHARM_COUNT; c++)
            if (CHARMS[c].weight) {
                what[n] = (uint8_t)c;
                weight[n++] = CHARMS[c].weight;
            }
        return n;
    }
    for (int f = 0; f < FACE_COUNT; f++)
        if (FACES[f].weight) {
            what[n] = (uint8_t)f;
            weight[n++] = FACES[f].weight;
        }
    for (int s = 0; s < 6; s++) {
        what[n] = (uint8_t)(UP_CARD + s);
        weight[n++] = UPGRADE_WEIGHT[s];
    }
    return n;
}

/* offer.below: a random number below n, from two random bytes cut to the bits n needs */
static int below(Mt *rng, int n) {
    int bits = 1;
    while (bits < n)
        bits = bits << 1 | 1;
    for (;;) {
        int r = (int)(mt_bits(rng, 8) | mt_bits(rng, 8) << 8) & bits;
        if (r < n)
            return r;
    }
}

static int draw(Mt *rng, const Kit *kit, int charms, uint8_t *out) {
    uint8_t what[FACE_COUNT + 8], weight[FACE_COUNT + 8];
    int rows = pool_of(charms, what, weight), count = 0;
    int most = charms ? CHARMS_DRAWN : FACES_DRAWN;
    for (int n = 0; n < most; n++) {
        int w[FACE_COUNT + 8], total = 0;
        for (int k = 0; k < rows; k++) {
            int c = what[k], ok = 1;
            for (int i = 0; i < count && ok; i++)
                ok = charms ? out[i] != c : card_what(kit, out[i]) != card_what(kit, c);
            if (ok)
                ok = charms ? !kit_holds(kit, c) : card_ok(kit, c);
            w[k] = ok ? weight[k] : 0;
            total += w[k];
        }
        if (!total)
            break;
        int r = below(rng, total), k = 0;
        while (r >= w[k]) {
            r -= w[k];
            k++;
        }
        out[count++] = what[k];
    }
    return count;
}

/* a forced pick slipped into the offer when it can come and is not in it */
static int slip_in(const Kit *kit, int kind, int f, uint8_t *drawn, int n, int most) {
    const Force *fo = forced_at(kind, f);
    if (!fo || fo->a >= BLANK_CARD)
        return n; /* a skip or a blank is not a card */
    if (kind == FORCE_CARD && !card_ok(kit, fo->a))
        return n;
    if (kind == FORCE_CHARM && kit_holds(kit, fo->a))
        return n;
    for (int i = 0; i < n; i++)
        if (drawn[i] == fo->a)
            return n;
    if (n < most)
        drawn[n++] = (uint8_t)fo->a;
    else
        drawn[most - 1] = (uint8_t)fo->a;
    return n;
}

/* ---- the picks */

static void grow_hp(Kit *kit, int *hp, int n) {
    kit->hp_max = sum8(kit->hp_max, n);
    *hp = sum8(*hp, n);
}

void pick_apply(Kit *kit, int *hp, const Pick *o) {
    switch (o->what) {
    case PK_ITEM:
        if (o->a != BLANK_ID)
            kit->items[FACES[o->a].slot] = o->a;
        break;
    case PK_CHARM:
        if (kit->ncharms < HELD_CHARMS) {
            kit->charms[kit->ncharms++] = o->a;
            if (CHARMS[o->a].kind == K_collar && hp)
                grow_hp(kit, hp, CHARMS[o->a].amount);
        }
        break;
    case PK_LEVEL:
    case PK_NAP_LEVEL:
        kit->level[o->a]++;
        break;
    }
}

/* the greedy player's mean result in fight row f with this kit (rewards.rollout) */
static double rollout(const Kit *kit, int hp, int f, const uint32_t *seeds, int n) {
    double total = 0.0;
    for (int i = 0; i < n; i++) {
        Mt rng;
        mt_seed(&rng, seeds[i]);
        Battle b;
        Kit k = *kit;
        int h = hp;
        play_fight(P_GREEDY, &rng, &k, &h, f, &rng, NULL, &b, NULL);
        if (b.result == R_WON)
            total += b.hp[HERO];
        else
            total += -40.0 + 0.5 * (b.hp[HERO] - b.hp[1] - b.hp[2] - b.hp[3]);
    }
    return total / n;
}

static int choose(Player *p, const Kit *kit, int hp, int f, const Pick *opts, int n) {
    if (n == 1)
        return 0;
    if (p->kind == P_SEARCH && BLUNDER_PICK > 0.0 && mt_random(p->rng) < BLUNDER_PICK)
        return mt_below(p->rng, n);
    if (p->kind == P_RANDOM)
        return mt_below(p->rng, n);
    if (p->kind == P_SEARCH && DRAFT.ahead > 0)
        return search_choose(p, kit, hp, f, opts, n);
    int best = 0;
    double bw = -1e18;
    for (int i = 0; i < n; i++) {
        Kit k2 = *kit;
        int h = hp;
        pick_apply(&k2, &h, &opts[i]);
        double w = kit_worth(&k2);
        if (w > bw + 1e-9) {
            bw = w;
            best = i;
        }
    }
    if (p->kind == P_GREEDY)
        return best;
    uint32_t seeds[ROLLOUTS];
    for (int i = 0; i < ROLLOUTS; i++)
        seeds[i] = mt_bits(p->rng, 30);
    double top = -1e18;
    for (int i = 0; i < n; i++) {
        Kit k2 = *kit;
        int h = hp;
        pick_apply(&k2, &h, &opts[i]);
        double v = rollout(&k2, h, f, seeds, ROLLOUTS) + 0.5 * kit_worth(&k2);
        if (v > top) {
            top = v;
            best = i;
        }
    }
    return best;
}

static void add_pick(RunResult *out, const Pick *o, int f) {
    if (out && out->npicks < MAX_PICKS) {
        out->picks[out->npicks] = *o;
        out->picks[out->npicks].after = (uint8_t)f;
        out->npicks++;
    }
}

static int forced_index(int kind, int f, const Pick *opts, int n) {
    const Force *fo = forced_at(kind, f);
    if (!fo)
        return -1;
    for (int i = 0; i < n; i++)
        if (opts[i].card == fo->a)
            return i;
    return -1;
}

/* the nap: every hit point she is missing back (NAP_HEAL_SHIFT), or a level on a slot */
static void nap(Player *p, Kit *kit, int *hp, int f, RunResult *out) {
    int miss = kit->hp_max - *hp;
    int heal = *hp + ((miss + (1 << NAP_HEAL_SHIFT) - 1) >> NAP_HEAL_SHIFT);
    Pick ups[6];
    int n = 0;
    for (int s = 0; s < 6; s++) {
        if (kit->level[s] < ITEM_MOST) {
            ups[n].what = PK_NAP_LEVEL;
            ups[n].a = (uint8_t)s;
            ups[n].card = (uint8_t)s;
            n++;
        }
    }
    Pick heal_pick = {PK_NAP_HEAL, 0, 0, NOTHING};
    int best = -1;
    const Force *fo = out ? forced_at(FORCE_NAP, f) : NULL;
    if (!n) {
        best = -1;
    } else if (fo) {
        for (int i = 0; i < n; i++)
            if (ups[i].a == fo->a)
                best = i;
    } else if (p->kind == P_RANDOM) {
        best = (int)mt_below(p->rng, n + 1) - 1;
    } else if (p->kind == P_GREEDY) {
        best = heal - *hp >= 4 ? -1 : 0;
    } else if (p->kind == P_SEARCH && BLUNDER_PICK > 0.0 && mt_random(p->rng) < BLUNDER_PICK) {
        best = (int)mt_below(p->rng, n + 1) - 1;
    } else if (p->kind == P_SEARCH && DRAFT.ahead > 0) {
        best = search_nap(p, kit, *hp, heal, ups, n, f);
    } else {
        uint32_t seeds[ROLLOUTS];
        for (int i = 0; i < ROLLOUTS; i++)
            seeds[i] = mt_bits(p->rng, 30);
        double hv = rollout(kit, heal, f, seeds, ROLLOUTS);
        for (int i = 0; i < n; i++) {
            Kit k2 = *kit;
            pick_apply(&k2, NULL, &ups[i]);
            double v = rollout(&k2, *hp, f, seeds, ROLLOUTS);
            if (v > hv) {
                hv = v;
                best = i;
            }
        }
    }
    if (best < 0) {
        *hp = heal;
        add_pick(out, &heal_pick, f);
        return;
    }
    pick_apply(kit, hp, &ups[best]);
    add_pick(out, &ups[best], f);
}

/* the reward after fight row fought, before the next (f fights won) */
void reward_pick(Player *p, Kit *kit, int *hp, int f, int fought, RunResult *out, Mt *rng) {
    const FightRow *fight = &FIGHTS[fought];
    uint8_t cards[FACES_DRAWN], charms[CHARMS_DRAWN];
    Mt own;
    if (OFFER_SALT && out) { /* the luck study: the draws apart from the dice */
        uint64_t s = OFFER_SALT * 1000003u + (uint64_t)f * 7919u;
        for (int i = 0; i < out->npicks; i++)
            s = s * 31u + out->picks[i].card;
        mt_seed(&own, s ^ out->seed_of_run);
        rng = &own;
    }
    int nc = draw(rng, kit, 0, cards), nh = 0;
    if (fight->elite) {
        for (int h = 0; h < kit->ncharms; h++)
            if (CHARMS[kit->charms[h]].kind == K_ninth)
                grow_hp(kit, hp, CHARMS[kit->charms[h]].amount);
        nh = draw(rng, kit, 1, charms);
    }
    if (out) {
        nc = slip_in(kit, FORCE_CARD, f, cards, nc, FACES_DRAWN);
        if (fight->elite)
            nh = slip_in(kit, FORCE_CHARM, f, charms, nh, CHARMS_DRAWN);
        if (f >= 1 && f <= FIGHT_COUNT) {
            memset(out->offer[f - 1], NOTHING, FACES_DRAWN);
            memcpy(out->offer[f - 1], cards, nc);
            memset(out->charm_offer[f - 1], NOTHING, CHARMS_DRAWN);
            memcpy(out->charm_offer[f - 1], charms, nh);
        }
    }
    Pick opts[FACES_DRAWN + 1];
    int n = 0;
    for (int i = 0; i < nc; i++) {
        int c = cards[i];
        if (BLANK_SLOT != NOTHING && c < UP_CARD && FACES[c].slot == BLANK_SLOT &&
            kit->items[BLANK_SLOT] == BLANK_ID)
            continue; /* the blank's slot stays blank (the studies' baseline) */
        int lv = levels(kit, c);
        opts[n].what = lv ? PK_LEVEL : PK_ITEM;
        opts[n].a = (uint8_t)(lv ? card_slot(c) : c);
        opts[n].card = (uint8_t)c;
        n++;
    }
    const Force *fb = out ? forced_at(FORCE_CARD, f) : NULL;
    if (fb && fb->a >= BLANK_CARD && fb->a < BLANK_CARD + 6) {
        /* the studies' baseline: the slot's face made a blank, as if the card did nothing */
        kit->items[fb->a - BLANK_CARD] = BLANK_ID;
        Pick bl = {PK_ITEM, BLANK_ID, 0, (uint8_t)fb->a};
        add_pick(out, &bl, f);
        n = 0;
    }
    if (n) {
        opts[n].what = PK_SKIP;
        opts[n].a = 0;
        opts[n].card = SKIP_CARD;
        n++;
        int i = out ? forced_index(FORCE_CARD, f, opts, n) : -1;
        if (i >= 0 && NPLAN && opts[i].what == PK_ITEM)
            kit->locked |= (uint8_t)(1 << FACES[opts[i].a].slot);
        if (i < 0)
            i = choose(p, kit, *hp, f, opts, n);
        pick_apply(kit, hp, &opts[i]);
        add_pick(out, &opts[i], f);
    }
    if (nh) {
        for (int c = 0; c < nh; c++) {
            opts[c].what = PK_CHARM;
            opts[c].a = charms[c];
            opts[c].card = charms[c];
        }
        opts[nh].what = PK_SKIP;
        opts[nh].a = 1;
        opts[nh].card = SKIP_CARD;
        int i = out ? forced_index(FORCE_CHARM, f, opts, nh + 1) : -1;
        if (i < 0)
            i = choose(p, kit, *hp, f, opts, nh + 1);
        pick_apply(kit, hp, &opts[i]);
        add_pick(out, &opts[i], f);
    }
    if (fight->elite)
        nap(p, kit, hp, f, out);
}

/* fight f or its other door; the player sees both before choosing */
int pick_door(Player *p, const Kit *kit, int hp, int f, int other) {
    if (p->kind == P_RANDOM)
        return mt_random(p->rng) < 0.5 ? f : other;
    if (p->kind == P_GREEDY) {
        int a = 0, b = 0;
        for (int i = 0; i < FIGHTS[f].count; i++)
            a += KINDS[FIGHTS[f].enemies[i]].hp;
        for (int i = 0; i < FIGHTS[other].count; i++)
            b += KINDS[FIGHTS[other].enemies[i]].hp;
        return a <= b ? f : other;
    }
    if (p->kind == P_SEARCH && BLUNDER_PICK > 0.0 && mt_random(p->rng) < BLUNDER_PICK)
        return mt_random(p->rng) < 0.5 ? f : other;
    if (p->kind == P_SEARCH && DRAFT.ahead > 0)
        return search_door(p, kit, hp, f, other);
    uint32_t seeds[ROLLOUTS];
    for (int i = 0; i < ROLLOUTS; i++)
        seeds[i] = mt_bits(p->rng, 30);
    return rollout(kit, hp, f, seeds, ROLLOUTS) >= rollout(kit, hp, other, seeds, ROLLOUTS)
               ? f
               : other;
}

static const char *const SLOT_UP[6] = {"WAND", "FLUFF", "STAR", "BOOK", "CURSE", "TRICK"};

const char *card_name(int c, char *buf) {
    if (c == SKIP_CARD)
        sprintf(buf, "skip");
    else if (c >= BLANK_CARD && c < BLANK_CARD + 6)
        sprintf(buf, "blank %s", SLOT_UP[c - BLANK_CARD]);
    else if (c >= UP_CARD)
        sprintf(buf, "+1 %s", SLOT_UP[c - UP_CARD]);
    else
        sprintf(buf, "%s", FACES[c].name);
    return buf;
}

const char *pick_words(const Pick *pk, char *buf) {
    switch (pk->what) {
    case PK_ITEM: sprintf(buf, "%s", pk->a == BLANK_ID ? "(a blank face)" : FACES[pk->a].name); break;
    case PK_LEVEL: sprintf(buf, "+1 %s", SLOT_UP[pk->a]); break;
    case PK_CHARM: sprintf(buf, "charm %s", CHARMS[pk->a].name); break;
    case PK_NAP_HEAL: sprintf(buf, "rest: heal"); break;
    case PK_NAP_LEVEL: sprintf(buf, "rest: +1 %s", SLOT_UP[pk->a]); break;
    case PK_SKIP: sprintf(buf, pk->a ? "skip the charm" : "skip the card"); break;
    default: sprintf(buf, "door %d", pk->a);
    }
    return buf;
}

const char *kit_words(const Kit *kit, char *buf) {
    int len = 0;
    for (int s = 0; s < 6; s++) {
        len += sprintf(buf + len, "%s%s", s ? ", " : "",
                       kit->items[s] == BLANK_ID ? "(blank)" : FACES[kit->items[s]].name);
        for (int l = 0; l < kit->level[s]; l++)
            buf[len++] = '+';
        buf[len] = 0;
    }
    if (kit->ncharms) {
        len += sprintf(buf + len, "; charms:");
        for (int i = 0; i < kit->ncharms; i++)
            len += sprintf(buf + len, " %s", CHARMS[kit->charms[i]].name);
    }
    return buf;
}
