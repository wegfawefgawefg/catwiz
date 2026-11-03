/* Whole runs (run.c): the fights in order with her hit points, most hit points and kit
   carried over, and the choices between fights (rewards.c, draft.c). */
#ifndef RUN_H
#define RUN_H
#include "players.h"

/* a choice between fights */
enum { PK_ITEM, PK_LEVEL, PK_CHARM, PK_NAP_HEAL, PK_NAP_LEVEL, PK_DOOR, PK_SKIP };

typedef struct {
    uint8_t what, a; /* PK_ITEM: face id; PK_LEVEL, PK_NAP_LEVEL: slot; PK_CHARM: charm id;
                        PK_DOOR: the fight row taken; PK_SKIP: 0 cards, 1 charms */
    uint8_t after;   /* after fight number (1-based), before the next */
    uint8_t card;    /* the card it came from (a face id or UP_CARD + slot), the charm id, the
                        nap's slot (NOTHING: the heal), the door's row; SKIP_CARD to skip */
} Pick;

#define SKIP_CARD 254

typedef struct {
    uint8_t index, won, hp_in, hp_out, turns, lost, healed, self_hits;
    Peak peak;
} FightResult;

#define MAX_PICKS 40

typedef struct {
    FightResult fights[FIGHT_COUNT];
    int nfights, won;
    Pick picks[MAX_PICKS];
    int npicks;
    Kit kit;                       /* at the end */
    Kit kit_at[FIGHT_COUNT];       /* walking into each fight */
    uint8_t offer[FIGHT_COUNT][FACES_DRAWN];  /* the cards offered after each fight */
    uint8_t charm_offer[FIGHT_COUNT][CHARMS_DRAWN];
    uint32_t seen[FACE_COUNT], played[FACE_COUNT]; /* faces shown at a turn's end, played */
    int blunders;
    uint64_t seed_of_run;
    char *log;
} RunResult;

/* a pick the player is made to take (the studies): FORCE_CARD (a: the card), FORCE_CHARM (the
   charm id), FORCE_NAP (a slot, or NOTHING for the heal), FORCE_DOOR (the fight row); after:
   the fight number just won */
enum { FORCE_CARD, FORCE_CHARM, FORCE_NAP, FORCE_DOOR };
typedef struct {
    int on, kind, after, a;
} Force;
extern Force FORCE;
#define PLAN_MOST 16
extern Force PLAN[PLAN_MOST];
extern int NPLAN;
const Force *forced_at(int kind, int after);

/* the draft's knobs (draft.c) */
typedef struct {
    int rollouts, ahead, roll_player;
    double kit, learn;
} Draft;
void learned_load(const char *path);
extern Draft DRAFT;

/* a blank face (the studies' baseline): a slot's face that does nothing, or NOTHING */
extern int BLANK_SLOT;
#define BLANK_ID HAIRBALL_ID

void run_one(int player, uint64_t seed, RunResult *out, int want_log);
int play_fight(int player, Mt *prng, Kit *kit, int *hp, int index, Mt *rng, struct Tell *tell,
               Battle *out, RunResult *use);

/* rewards.c */
double kit_worth(const Kit *kit);
void reward_pick(Player *p, Kit *kit, int *hp, int f, int fought, RunResult *out, Mt *rng);
int pick_door(Player *p, const Kit *kit, int hp, int f, int other);
void pick_apply(Kit *kit, int *hp, const Pick *o);
const char *pick_words(const Pick *pk, char *buf);
const char *kit_words(const Kit *kit, char *buf);
const char *card_name(int c, char *buf);

/* draft.c */
double learned_value(int kind, int after, int what);
extern uint64_t OFFER_SALT; /* not 0: the draws take their own random numbers (luck study) */
#define BLANK_CARD 200 /* a forced card BLANK_CARD + slot: that slot's face made a blank */
int search_choose(Player *p, const Kit *kit, int hp, int f, const Pick *opts, int n);
int search_nap(Player *p, const Kit *kit, int hp, int heal, const Pick *ups, int n, int f);
int search_door(Player *p, const Kit *kit, int hp, int f, int other);

#endif
