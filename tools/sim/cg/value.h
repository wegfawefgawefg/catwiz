/* The searching player's position value (value.c) and its weights. */
#ifndef VALUE_H
#define VALUE_H
#include <stdio.h>

#include "sim.h"

/* every field a double, in WEIGHT_NAME's order (weight_ref walks them) */
typedef struct {
    double hp, danger, mana, ward, kitten, keep, held, clog;
    double foe_hp, foe_shield, foe_ward, brand, wet, fleas, threat, decay;
    double spook, hero_wet, hero_fleas, grow, dot, leech;
} Weights;

#define WEIGHT_COUNT 22
extern Weights WEIGHTS;
extern const char *const WEIGHT_NAME[];
double *weight_ref(Weights *w, int i);

double value_of(const Battle *b);
double value_after_turn(const Battle *b);
void weights_load(const char *path);
void weights_print(FILE *f);
/* what enemy i's next move would cost her (0 when it will not come at her) */
double next_attack(const Battle *b, int i);

#endif
