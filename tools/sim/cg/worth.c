/* What a kit is worth by a rough fixed rule (the greedy player's picks, and the draft's kit at
   a window's end): a face's number at its level, weighed by its slot and cost, a little more
   for a three or a scaling tag; a charm a flat 2.5. The item sim had a table a card; with 130
   cards the rule is coarse on purpose: the searching player's draft leans on its rollouts and
   its learned values, not on this. */
#include "run.h"

static double face_worth(int id, int level) {
    const FaceRow *f = &FACES[id];
    if (f->slot == S_junk)
        return 0.0;
    double n = f->amount + level * f->step;
    double w;
    switch (f->slot) {
    case S_wand: w = n; break;
    case S_fluff: w = 0.8 * n; break;
    case S_star: w = 1.3 * n + 0.5; break;
    case S_book: w = 2.0 * n - 1.0 * f->cost + 2.0; break;
    case S_curse: w = 1.5 * n + 1.0; break;
    default: w = 1.5 * n + 1.0;
    }
    if (f->tags & TAG_THREE)
        w += 0.8;
    if (f->tags & TAG_NONE)
        w += 3.0; /* a face with no number: what it does is the point */
    return w > 0.5 ? w : 0.5;
}

double kit_worth(const Kit *kit) {
    double w = 0;
    for (int s = 0; s < 6; s++)
        w += face_worth(kit->items[s], kit->level[s]);
    w += 2.5 * kit->ncharms;
    return w;
}
