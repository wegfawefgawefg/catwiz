/* The searching player's draft (search.c, draft.c): its picks between fights. */
#ifndef SEARCH_H
#define SEARCH_H
#include "run.h"

int search_choose(Player *p, const Kit *kit, int hp, int f, const Pick *opts, int n);
int search_nap(Player *p, const Kit *kit, int hp, int heal, const Pick *ups, int n, int f);
int search_door(Player *p, const Kit *kit, int hp, int f, int other);
void pick_apply(Kit *kit, const Pick *o);
double rollout(const Kit *kit, int hp, int f, const uint32_t *seeds, int n);

#endif
