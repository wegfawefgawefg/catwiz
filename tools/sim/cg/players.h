/* The players: random, greedy, strong (players.c) and the searching player (search.c). Each
   plays one hero turn; the picks between fights are rewards.c's and draft.c's. */
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

/* a play: the die and the target (NOTHING for a face that picks none; FLIP | f: turn the die
   to face f, after a paw flip) */
typedef struct {
    uint8_t s, t;
} Play;
#define MAX_OPTIONS 64
int options(const Battle *b, Play *out);

/* the skill ladder: the searching player's chance at each play of a random legal play, and
   at each pick between fights of a random option */
extern double BLUNDER_PLAY, BLUNDER_PICK;
int blunder(Player *p, Battle *b);

void player_turn(Player *p, Battle *b);
void search_turn(Player *p, Battle *b); /* search.c */

/* a position's hash (from POS_BEGIN to POS_END) */
void pos_hash(const Battle *b, uint64_t *h1, uint64_t *h2);

#endif
