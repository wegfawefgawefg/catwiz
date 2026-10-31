/* The players: random, greedy, strong (players.c, ports of tools/sim/policy.py) and the
   searching player (search.c). Each plays one hero turn; the rewards are rewards.c's. */
#ifndef PLAYERS_H
#define PLAYERS_H
#include "sim.h"

enum { P_RANDOM, P_GREEDY, P_STRONG, P_SEARCH, P_COUNT };
extern const char *const PLAYER_NAME[P_COUNT];

typedef struct {
    int kind;
    Mt *rng; /* the player's own random numbers: random choices, imagined re-rolls */
} Player;

extern double KIND_THREAT[KIND_COUNT];
extern int KIND_CHAIN[KIND_COUNT];
void judge_init(void);
double judge_value(const Battle *b);
double judge_after_turn(const Battle *b);

/* a play: the slot and the target (NOTHING for a face that picks none) */
typedef struct {
    uint8_t s, t;
} Play;
int options(const Battle *b, Play *out);

void player_turn(Player *p, Battle *b);
void search_turn(Player *p, Battle *b); /* search.c */
void search_init(void);

#endif
