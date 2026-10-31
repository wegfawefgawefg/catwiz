/* The kit and the choices between fights: tools/sim/rewards.py (the item model). After a won
   fight, one of its three cards: an item for a slot (the old one goes; holding it already, a
   level on its slot), or an upgrade card (a level on that slot). Levels belong to the slot,
   ITEM_MOST at most. A fight with charms then offers one of three; the elite's nap is 10 hit
   points or a level; fight 10 has two doors.

   random picks any offer; greedy the one that most raises the kit's worth by a fixed table
   (item_worth); strong tries each offer in rollouts of the next fight (the greedy player, the
   same dice for every option); search (search.c) has its own draft. */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "run.h"
#include "search.h"

#define ROLLOUTS 6

void kit_start(Kit *kit) {
    memset(kit, 0, sizeof *kit);
    memcpy(kit->items, STARTING_ITEMS, 6);
}

int kit_has(const Kit *kit, int kind) {
    for (int i = 0; i < kit->ncharms; i++)
        if (CHARMS[kit->charms[i]].kind == kind)
            return 1;
    return 0;
}

void kit_setup(const Kit *kit, Setup *k) {
    memset(k, 0, sizeof *k);
    memcpy(k->items, kit->items, 6);
    for (int s = 0; s < 6; s++)
        k->level_of[kit->items[s]] = kit->level[s];
    for (int i = 0; i < kit->ncharms; i++)
        k->charm_n[CHARMS[kit->charms[i]].kind]++;
    k->ndice = HAND + (RULES.toe_fix ? k->charm_n[K_toe] : 0);
}

/* a rough worth of an item on its face, in damage-equivalents a roll */
static double item_worth(int row, int level) {
    const ItemRow *f = &ITEMS[row];
    int n = f->amount + level * f->step;
    double w;
    switch (f->effect) {
    case E_hit: w = n; break;
    case E_yarn: w = 1.3 * n + 0.3; break;
    case E_feather: w = 1.7 * n; break;
    case E_spray: w = 1.4 * n; break;
    case E_pierce: w = 1.2 * n; break;
    case E_shield: w = 0.7 * n; break;
    case E_mana: w = 1.1 * n; break;
    case E_zoomies: w = 5.0 * n; break;
    case E_kittens: w = 3.0 * n; break;
    case E_laserall: w = 2.0 * n + 2; break;
    case E_knock: w = n + 2; break;
    case E_scream: w = 2.5 * n; break;
    case E_heal: w = 0.7 * n; break;
    case E_fleas: w = 2.0 * n; break;
    case E_wet: w = 1.5 + n; break;
    case E_brand: w = 2.5 * n; break;
    case E_plus: w = 1.2 * n; break;
    case E_double: w = 1.2 * n; break;
    case E_catnip2: w = n; break;
    case E_copy: w = 2.0 + n; break;
    case E_knead: w = 1.5 + n; break;
    case E_string: w = 1.8 * n; break;
    case E_shoot: w = 1.1 + n; break;
    case E_moon: w = 1.1 + 0.7 * n; break;
    case E_wish: w = 1.1 * n + 1.5; break;
    case E_litter: w = 1.1 * n + 1.0; break;
    case E_tangled: w = 1.5 * n; break;
    case E_pile: w = 0.7 * n + 1.0; break;
    case E_cannon: w = 1.5 * n; break;
    default: w = 0.0;
    }
    if (f->combo != C_none)
        w += 0.8;
    if (f->cost) {
        double c = w - 1.0 * f->cost;
        w = c > 0.5 ? c : 0.5;
    }
    return w;
}

static double charm_worth(int kind) {
    switch (kind) {
    case K_pocket: return 3.0;
    case K_toe: return 3.0;
    case K_still: return 2.0;
    case K_trio: return 2.5;
    case K_mittens: return 2.0;
    case K_mother: return 2.5;
    case K_tail: return 2.5;
    case K_grumpy: return 2.0;
    case K_duck: return 1.5;
    case K_badmilk: return 2.5;
    }
    return 0.0;
}

/* a running sum as Python 3.12's sum() of floats does it (Neumaier's compensation), so the
   two sims rank equal-looking kits the same */
typedef struct {
    double s, c;
} Sum;

static void sum_add(Sum *a, double x) {
    double t = a->s + x;
    if (fabs(a->s) >= fabs(x))
        a->c += (a->s - t) + x;
    else
        a->c += (x - t) + a->s;
    a->s = t;
}

static double sum_of(const Sum *a) {
    return a->c != 0.0 ? a->s + a->c : a->s;
}

double kit_worth(const Kit *kit) {
    Sum w = {0, 0}, c = {0, 0};
    for (int s = 0; s < 6; s++)
        sum_add(&w, item_worth(kit->items[s], kit->level[s]));
    for (int i = 0; i < kit->ncharms; i++)
        sum_add(&c, charm_worth(CHARMS[kit->charms[i]].kind));
    return sum_of(&w) + sum_of(&c);
}

static int item_slot(int row) {
    return ITEMS[row].slot == S_food ? 5 : ITEMS[row].slot;
}

Force FORCE = {0, 0, 0, 0}, DOOR_FORCE = {0, 0, 0, 0};
Force PLAN[PLAN_MOST];
int NPLAN = 0;

/* the forced pick of this kind after fight f: the study's, or a line's (NULL for none) */
const Force *forced_at(int kind, int after) {
    if (FORCE.on && FORCE.kind == kind && FORCE.after == after)
        return &FORCE;
    for (int i = 0; i < NPLAN; i++)
        if (PLAN[i].kind == kind && PLAN[i].after == after)
            return &PLAN[i];
    return NULL;
}
const Kit *START_KIT = NULL;

/* the options a fight's cards give this kit; card[i] the card option i came from */
static int card_options(const Kit *kit, const uint8_t *cards, Pick *out, int *card) {
    int n = 0;
    for (int i = 0; i < 3; i++) {
        int c = cards[i];
        if (c == NOTHING)
            continue;
        int slot;
        if (c >= UP_CARD) {
            slot = c - UP_CARD;
        } else {
            slot = item_slot(c);
            if (kit->items[slot] != c) {
                if (kit->locked & (1 << slot))
                    continue;
                out[n].what = PK_ITEM;
                out[n].a = (uint8_t)c;
                out[n].card = (uint8_t)c;
                card[n++] = c;
                continue;
            }
        }
        if (kit->level[slot] < ITEM_MOST) {
            out[n].what = PK_LEVEL;
            out[n].a = (uint8_t)slot;
            out[n].card = (uint8_t)c;
            card[n++] = c;
        }
    }
    return n;
}

/* the forced option of this kind after fight f, if it is on offer (study.c), else -1 */
static int forced(int kind, int f, const int *what, int n) {
    const Force *fo = forced_at(kind, f);
    if (!fo)
        return -1;
    for (int i = 0; i < n; i++)
        if (what[i] == fo->a)
            return i;
    return -1;
}

void pick_apply(Kit *kit, const Pick *o) {
    switch (o->what) {
    case PK_ITEM:
        kit->items[item_slot(o->a)] = o->a;
        break;
    case PK_CHARM:
        kit->charms[kit->ncharms++] = o->a;
        break;
    case PK_LEVEL:
    case PK_NAP_LEVEL:
        kit->level[o->a]++;
        break;
    }
}

/* the greedy player's mean result in fight index f with this kit: hit points left, or a big
   loss (rewards.rollout) */
double rollout(const Kit *kit, int hp, int f, const uint32_t *seeds, int n) {
    double total = 0.0;
    for (int i = 0; i < n; i++) {
        Mt rng;
        mt_seed(&rng, seeds[i]);
        Battle b;
        play_fight(P_GREEDY, NULL, kit, hp, f, &rng, NULL, &b, NULL); /* greedy takes none */
        if (b.result == R_WON) {
            total += b.hp[HERO];
        } else {
            int foes = b.hp[1] + b.hp[2] + b.hp[3];
            total += -40.0 + 0.5 * (b.hp[HERO] - foes);
        }
    }
    return total / n;
}

static int kind_rank(int what) {
    return what == PK_CHARM ? 0 : what == PK_ITEM ? 1 : 2; /* "charm" < "item" < "level" */
}

/* the option a player takes (rewards.choose) */
static int choose(Player *p, const Kit *kit, int hp, int f, const Pick *opts, int n) {
    if (n == 1)
        return 0;
    if (p->kind == P_RANDOM) {
        int kinds[3] = {0, 0, 0}, nk = 0, order[3];
        for (int i = 0; i < n; i++)
            kinds[kind_rank(opts[i].what)] = 1;
        for (int r = 0; r < 3; r++)
            if (kinds[r])
                order[nk++] = r;
        int k = order[mt_below(p->rng, nk)];
        int sub[8], ns = 0;
        for (int i = 0; i < n; i++)
            if (kind_rank(opts[i].what) == k)
                sub[ns++] = i;
        return sub[mt_below(p->rng, ns)];
    }
    /* by worth, the best first (a stable sort, as Python's sorted) */
    int scored[8];
    double w[8];
    for (int i = 0; i < n; i++) {
        Kit k2 = *kit;
        pick_apply(&k2, &opts[i]);
        w[i] = -kit_worth(&k2);
        int j = i;
        while (j > 0 && w[scored[j - 1]] > w[i]) {
            scored[j] = scored[j - 1];
            j--;
        }
        scored[j] = i;
    }
    if (p->kind == P_GREEDY)
        return scored[0];
    if (p->kind == P_SEARCH && DRAFT.ahead > 0)
        return search_choose(p, kit, hp, f, opts, n);
    uint32_t seeds[ROLLOUTS];
    for (int i = 0; i < ROLLOUTS; i++)
        seeds[i] = mt_bits(p->rng, 30);
    int pick = scored[0];
    double best = 0.0;
    for (int j = 0; j < n; j++) {
        Kit k2 = *kit;
        pick_apply(&k2, &opts[scored[j]]);
        double v = rollout(&k2, hp, f, seeds, ROLLOUTS);
        if (j == 0 || v > best) {
            best = v;
            pick = scored[j];
        }
    }
    return pick;
}

static void add_pick(RunResult *out, const Pick *o, int f) {
    if (out && out->npicks < MAX_PICKS) {
        out->picks[out->npicks] = *o;
        out->picks[out->npicks].after = (uint8_t)f;
        out->npicks++;
    }
}

/* after an elite, a rest: REST_HEAL percent of the missing hit points, or dream a level */
static void nap(Player *p, Kit *kit, int *hp, int f, RunResult *out) {
    int heal = *hp + ((HERO_HP - *hp) * REST_HEAL + 99) / 100; /* a share of what she misses */
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
    if (!n) {
        *hp = heal;
        add_pick(out, &heal_pick, f);
        return;
    }
    int best = 0;
    double bw = 0.0;
    for (int i = 0; i < n; i++) {
        Kit k2 = *kit;
        pick_apply(&k2, &ups[i]);
        double w = kit_worth(&k2);
        if (i == 0 || w > bw) {
            bw = w;
            best = i;
        }
    }
    int take_heal;
    const Force *fo = out ? forced_at(FORCE_NAP, f) : NULL;
    if (fo) {
        take_heal = fo->a == NOTHING;
        for (int i = 0; i < n; i++)
            if (ups[i].a == fo->a)
                best = i;
    } else if (p->kind == P_RANDOM) {
        take_heal = mt_random(p->rng) < 0.5;
    } else if (p->kind == P_GREEDY) {
        take_heal = heal - *hp >= 5; /* a rest worth 5 or more */
    } else if (p->kind == P_SEARCH && DRAFT.ahead > 0) {
        take_heal = search_nap(p, kit, *hp, heal, &ups[best], f);
    } else {
        uint32_t seeds[ROLLOUTS];
        for (int i = 0; i < ROLLOUTS; i++)
            seeds[i] = mt_bits(p->rng, 30);
        Kit k2 = *kit;
        pick_apply(&k2, &ups[best]);
        take_heal = rollout(kit, heal, f, seeds, ROLLOUTS) >= rollout(&k2, *hp, f, seeds, ROLLOUTS);
    }
    if (take_heal) {
        *hp = heal;
        add_pick(out, &heal_pick, f);
        return;
    }
    pick_apply(kit, &ups[best]);
    add_pick(out, &ups[best], f);
}

/* the reward after fight row fought, before fight index f (rewards.pick) */
/* up to three different entries of a pool drawn at random by weight (the game's random
   numbers), among those that may come after f fights won and that ok allows
   (rewards.py draw) */
static int draw(Mt *rng, const OfferRow *pool, int count, int f, const uint8_t *ok,
                uint8_t *out) {
    int what[64], wt[64], m = 0, n = 0;
    for (int i = 0; i < count; i++) {
        if (pool[i].from <= f && ok[i]) {
            what[m] = pool[i].what;
            wt[m++] = pool[i].weight;
        }
    }
    for (int k = 0; k < 3; k++) {
        int total = 0;
        for (int j = 0; j < m; j++)
            total += wt[j];
        if (!total)
            break;
        int r = mt_below(rng, total);
        for (int j = 0; j < m; j++) {
            if (r < wt[j]) {
                out[n++] = (uint8_t)what[j];
                for (int q = j; q + 1 < m; q++) {
                    what[q] = what[q + 1];
                    wt[q] = wt[q + 1];
                }
                m--;
                break;
            }
            r -= wt[j];
        }
    }
    return n;
}

/* a forced pick (a study or a line) slipped into the offer when it may come and is not in it */
static int slip_in(int kind, int f, uint8_t *drawn, int n, int may) {
    const Force *fo = forced_at(kind, f);
    if (!fo || !may)
        return n;
    for (int i = 0; i < n; i++)
        if (drawn[i] == fo->a)
            return n;
    if (n < 3)
        drawn[n++] = (uint8_t)fo->a;
    else
        drawn[2] = (uint8_t)fo->a;
    return n;
}

static int card_gives(const Kit *kit, int c) {
    uint8_t one[3] = {(uint8_t)c, NOTHING, NOTHING};
    Pick o[3];
    int card[3];
    return card_options(kit, one, o, card) > 0;
}

/* the reward after fight row fought, before fight index f (f fights won): three cards drawn
   from the pool, then three charms at a charm fight, then the nap (rewards.pick) */
int reward_pick(Player *p, Kit *kit, int *hp, int f, int fought, RunResult *out, Mt *rng) {
    const FightRow *fight = &FIGHTS[fought];
    uint8_t ok[64], cards[3] = {NOTHING, NOTHING, NOTHING}, charms[3];
    for (int i = 0; i < OFFER_COUNT; i++)
        ok[i] = (uint8_t)card_gives(kit, OFFERS[i].what);
    int nc = draw(rng, OFFERS, OFFER_COUNT, f, ok, cards);
    int nh = 0;
    if (fight->charm) {
        for (int i = 0; i < CHARM_OFFER_COUNT; i++) {
            ok[i] = 1;
            for (int j = 0; j < kit->ncharms; j++)
                if (kit->charms[j] == CHARM_OFFERS[i].what)
                    ok[i] = 0;
        }
        nh = draw(rng, CHARM_OFFERS, CHARM_OFFER_COUNT, f, ok, charms);
    }
    if (out) {
        const Force *fo = forced_at(FORCE_CARD, f);
        int may = 0;
        for (int i = 0; fo && i < OFFER_COUNT; i++)
            may |= OFFERS[i].what == fo->a && OFFERS[i].from <= f && card_gives(kit, fo->a);
        nc = slip_in(FORCE_CARD, f, cards, nc, may);
        if (fight->charm) {
            fo = forced_at(FORCE_CHARM, f);
            may = fo != NULL;
            for (int j = 0; fo && j < kit->ncharms; j++)
                may &= kit->charms[j] != fo->a;
            nh = slip_in(FORCE_CHARM, f, charms, nh, may);
        }
    }
    Pick opts[8];
    int card[8];
    int n = card_options(kit, cards, opts, card);
    if (n) {
        int i = out ? forced(FORCE_CARD, f, card, n) : -1;
        if (i >= 0 && NPLAN && opts[i].what == PK_ITEM)
            kit->locked |= (uint8_t)(1 << item_slot(opts[i].a)); /* a line keeps its items */
        if (i < 0)
            i = choose(p, kit, *hp, f, opts, n);
        pick_apply(kit, &opts[i]);
        opts[i].card = (uint8_t)card[i];
        add_pick(out, &opts[i], f);
    }
    if (nh) {
        for (int c = 0; c < nh; c++) {
            opts[c].what = PK_CHARM;
            opts[c].a = charms[c];
            opts[c].card = charms[c];
            card[c] = charms[c];
        }
        int i = out ? forced(FORCE_CHARM, f, card, nh) : -1;
        if (i < 0)
            i = choose(p, kit, *hp, f, opts, nh);
        pick_apply(kit, &opts[i]);
        add_pick(out, &opts[i], f);
    }
    if (fight->nap)
        nap(p, kit, hp, f, out);
    return 0;
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
    if (p->kind == P_SEARCH && DRAFT.ahead > 0)
        return search_door(p, kit, hp, f, other);
    uint32_t seeds[ROLLOUTS];
    for (int i = 0; i < ROLLOUTS; i++)
        seeds[i] = mt_bits(p->rng, 30);
    double a = rollout(kit, hp, f, seeds, ROLLOUTS);
    double b = rollout(kit, hp, other, seeds, ROLLOUTS);
    if (getenv("CATWIZ_DEBUG"))
        fprintf(stderr, "door hp %d seeds %u %u: %.17g %.17g\n", hp, seeds[0], seeds[1], a, b);
    return a >= b ? f : other;
}

static const char *const SLOT_UP[6] = {"WAND", "FLUFF", "STAR", "BOOK", "CURSE", "TRICK"};

/* a pick in words, folded (report.pick_kind): the item, "+1 WAND", "charm NAME", "nap: ..." */
const char *pick_words(const Pick *pk, char *buf) {
    switch (pk->what) {
    case PK_ITEM: sprintf(buf, "%s", ITEMS[pk->a].name); break;
    case PK_LEVEL: sprintf(buf, "+1 %s", SLOT_UP[pk->a]); break;
    case PK_CHARM: sprintf(buf, "charm %s", CHARMS[pk->a].name); break;
    case PK_NAP_HEAL: sprintf(buf, "rest: heal"); break;
    case PK_NAP_LEVEL: sprintf(buf, "rest: +1 %s", SLOT_UP[pk->a]); break;
    default: sprintf(buf, "door %d", pk->a);
    }
    return buf;
}

const char *kit_words(const Kit *kit, char *buf) {
    int len = 0;
    for (int s = 0; s < 6; s++) {
        len += sprintf(buf + len, "%s%s", s ? ", " : "", ITEMS[kit->items[s]].name);
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
