/* Whole runs (run.c): the fights in order with the hero's hit points and kit carried over, and
   the choices between fights (rewards.c). What a run gives back for the report. */
#ifndef RUN_H
#define RUN_H
#include "players.h"

/* a choice between fights */
enum { PK_ITEM, PK_LEVEL, PK_CHARM, PK_NAP_HEAL, PK_NAP_LEVEL, PK_DOOR };

typedef struct {
    uint8_t what, a; /* PK_ITEM: item row; PK_LEVEL, PK_NAP_LEVEL: slot; PK_CHARM: charm row;
                        PK_DOOR: the fight row taken */
    uint8_t after;   /* after fight number (1-based), before the next; a door: its index */
    uint8_t card;    /* the card it came from, the charm row, the nap's slot (NOTHING: the
                        heal), the door's fight row */
} Pick;

typedef struct {
    uint8_t index, won, hp_in, hp_out, turns;
    uint8_t lost, healed, self_hits;
} FightResult;

#define MAX_PICKS 40
#define MAX_TURNS 200

/* a hero turn of a run (the combos study): the faces played (a bit an item row), its
   fight (the number, 1-based) and turn, the damage it did, the systems it touched */
typedef struct {
    uint64_t played;
    uint8_t fight, turn, dmg, sys;
} TurnRec;

typedef struct {
    FightResult fights[FIGHT_COUNT];
    int nfights, won;
    Pick picks[MAX_PICKS];
    int npicks;
    Kit kit;                       /* at the end */
    Kit kit_at[FIGHT_COUNT];       /* walking into each fight */
    uint32_t seen[ITEM_COUNT], played[ITEM_COUNT]; /* faces shown at a turn's end, played */
    uint8_t offer[FIGHT_COUNT][3]; /* the cards offered after each fight (NOTHING: none) */
    uint32_t boosts[ITEM_COUNT], boost_gain[ITEM_COUNT]; /* the faces that took +1 or x2 */
    TurnRec turns[MAX_TURNS];
    int nturns;
    char *log;                     /* the readable log, when asked for (malloc'd) */
} RunResult;

/* a pick the player is made to take (study.c): kind FORCE_CARD (a is the card), FORCE_CHARM
   (the charm row), FORCE_NAP (a slot, or NOTHING for the heal), FORCE_DOOR (the fight row);
   after: the fight number just won */
enum { FORCE_CARD, FORCE_CHARM, FORCE_NAP, FORCE_DOOR };
typedef struct {
    int on, kind, after, a;
} Force;
extern Force FORCE, DOOR_FORCE; /* DOOR_FORCE: a door forced as well (the doors' cards) */
/* a line: several picks forced at once (main.c --plan), the rest drafted as usual */
#define PLAN_MOST 16
extern Force PLAN[PLAN_MOST];
extern int NPLAN;
const Force *forced_at(int kind, int after);

/* the reward chooser's knobs (rewards.c) */
typedef struct {
    int rollouts;    /* seeds an option is tried with */
    int ahead;       /* fights a rollout plays */
    int roll_player; /* the player in rollouts */
    double kit;      /* the kit's worth at the window's end counts this much */
    double learn;    /* hit points for 1.0 of learned win rate (draft.c) */
} Draft;
void learned_load(const char *path);
extern Draft DRAFT;

void run_one(int player, uint64_t seed, RunResult *out, int want_log);
int play_fight(int player, Mt *prng, const Kit *kit, int hp, int index, Mt *rng,
               struct Tell *tell, Battle *out, RunResult *use);

/* rewards.c */
double kit_worth(const Kit *kit);
int reward_pick(Player *p, Kit *kit, int *hp, int f, int fought, RunResult *out, Mt *rng);
int pick_door(Player *p, const Kit *kit, int hp, int f, int other);
const char *pick_words(const Pick *pk, char *buf);
const char *kit_words(const Kit *kit, char *buf);

#endif
