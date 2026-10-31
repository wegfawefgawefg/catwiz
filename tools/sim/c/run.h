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
    uint8_t after;   /* after fight number (1-based), before the next */
} Pick;

typedef struct {
    uint8_t index, won, hp_in, hp_out, turns;
    uint8_t lost, healed, self_hits;
} FightResult;

#define MAX_PICKS 40

typedef struct {
    FightResult fights[FIGHT_COUNT];
    int nfights, won;
    Pick picks[MAX_PICKS];
    int npicks;
    Kit kit;                       /* at the end */
    Kit kit_at[FIGHT_COUNT];       /* walking into each fight */
    uint32_t seen[ITEM_COUNT], played[ITEM_COUNT]; /* faces shown at a turn's end, played */
    char *log;                     /* the readable log, when asked for (malloc'd) */
} RunResult;

/* the reward chooser's knobs (rewards.c) */
typedef struct {
    int rollouts;    /* seeds a rollout */
    int ahead;       /* fights a rollout plays */
    int roll_player; /* the player in rollouts */
} Draft;

void run_one(int player, uint64_t seed, RunResult *out, int want_log);
int play_fight(int player, Mt *prng, const Kit *kit, int hp, int index, Mt *rng,
               struct Tell *tell, Battle *out, RunResult *use);

/* rewards.c */
double kit_worth(const Kit *kit);
int reward_pick(Player *p, Kit *kit, int *hp, int f, int fought, RunResult *out);
int pick_door(Player *p, const Kit *kit, int hp, int f, int other);
const char *pick_words(const Pick *pk, char *buf);
const char *kit_words(const Kit *kit, char *buf);

#endif
