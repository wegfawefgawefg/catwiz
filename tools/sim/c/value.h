/* The searching player's position value (value.c) and its weights. */
#ifndef VALUE_H
#define VALUE_H
#include <stdio.h>

#include "sim.h"

/* every field a double, in WEIGHT_NAME's order (weight_ref walks them) */
typedef struct {
    double hp, danger, mana, plus, mult, wish, ward, kitten, keep, held, clog;
    double foe_hp, foe_shield, foe_ward, brand, wet, fleas, threat, decay;
    double spook, hero_wet, hero_fleas;
} Weights;

#define WEIGHT_COUNT 22
extern Weights WEIGHTS;
extern const char *const WEIGHT_NAME[];
double *weight_ref(Weights *w, int i);

double value_of(const Battle *b);
double value_after_turn(const Battle *b);
void weights_load(const char *path);
void weights_print(FILE *f);

#endif
