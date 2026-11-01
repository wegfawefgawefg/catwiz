/* What a kit is worth by a fixed table: tools/sim/rewards.py item_worth, CHARM_WORTH and worth
   (the greedy player's picks, the draft's kit at a window's end). */
#include <math.h>

#include "run.h"

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
    case E_dot: w = 2.0 * n + 1.0; break;
    case E_swat: w = 1.4 * n; break;
    case E_paw: w = 0.7 * n + 1.5; break;
    case E_sunbeam: w = 1.1 * n + 0.5; break;
    case E_stretch: w = 1.5 * n; break;
    case E_mimic: w = 4.0 * n; break;
    case E_catfight: w = 1.5 + 0.8 * n; break;
    case E_mirror: w = 1.1 * n; break;
    case E_dryoff: w = 2.0 * n; break;
    case E_circus: w = 2.5 * n; break;
    case E_haunt: w = 1.0 * n; break;
    case E_habit: w = 1.3 * n + 1.0; break;
    case E_gamble: w = 1.0 * n; break;
    case E_cough: w = 0.5 * n; break;
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
    case K_nine: return 3.0;
    case K_litterbox: return 1.5;
    case K_lives9: return 3.0;
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
