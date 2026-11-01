/* The C balance sim of Catwiz's item-slot model: one battle (battle.c, hit.c, foes.c,
   items.c, cards.c), the players (judge.c, players.c, search.c), the run with its rewards (rewards.c, run.c), the
   report (report.c), the combos study (combos.c) and the readable turn logs (tell.c).
   It ports tools/sim/rules.py, foes.py, items.py, policy.py and rewards.py; each function
   says which Python function it copies. The content is gen_content.h, from the proposal. */
#ifndef SIM_H
#define SIM_H
#include <stdint.h>
#include <string.h>

#include "gen_content.h"
#include "rng.h"

#define NOTHING 255
#define HERO 0
#define ACTORS 4
#define MAX_HAND 7
#define MAX_PLAYS 16 /* plays a turn's plan holds (a finishing swat's die comes back) */
#define TURN_CAP 60 /* a fight this long counts as lost: the player is stuck */
#define COMBO_AT 3
#define PLUS_DICE 1 /* plus one boosts the next die (the owner, 2026-10-31; was 2) */
#define BACK_DIE 3.0 /* a die coming back to be rolled, in a search's copy (judge, value) */

/* statuses an actor has (rules.py STATUSES, the ones the item model uses) */
enum {
    ST_SHIELD, ST_POISON, ST_FLEA_TURNS, ST_WET, ST_CHEER, ST_WARD, ST_BOX, ST_MANA, ST_PLUS,
    ST_SPOOK, ST_REFLECT, ST_LASER, ST_THORNS, ST_HURT, ST_FRESH, ST_STRENGTH, ST_KITTENS,
    ST_NIPPED, ST_TANGLE, ST_BRAND, ST_KNEAD_FLUFF, ST_KNEAD_WAND, ST_NIP, ST_MULT, ST_KEEP,
    ST_WISH, ST_PLUS_LEFT, ST_DOT, ST_NINE,
    ST_CATFIGHT, ST_MIRROR, ST_CIRCUS, ST_HAUNT, ST_GAMBLE, NS
};

enum { R_NONE, R_WON, R_LOST };

/* what a fight is played with, fixed for the fight: levels by item row, charms by kind */
typedef struct {
    uint8_t level_of[ITEM_COUNT];
    uint8_t charm_n[K_COUNT];
    uint8_t items[6];
    int ndice; /* dice in the bag: HAND, or HAND + the sixth toe with the toe fix */
} Setup;

struct Tell;

typedef struct Battle {
    const Setup *k;
    Mt *rng;
    struct Tell *tell; /* a readable log, or NULL (searches' copies have none) */
    uint8_t faces[6];   /* every die's faces now: the slots' items, hairballs over some */
    uint8_t clogged[6]; /* the item a hairball covers on that slot, or NOTHING */
    uint8_t nclogged;
    uint8_t ndice, hand_n;
    uint8_t in_draw[MAX_HAND], held[MAX_HAND];
    uint8_t tray[MAX_HAND], hand[MAX_HAND], face_of[MAX_HAND], played[MAX_HAND];
    int32_t hp[ACTORS], maxhp[ACTORS];
    uint8_t alive[ACTORS], kind[ACTORS], move[ACTORS], made[ACTORS];
    int32_t st[ACTORS][NS];
    int16_t rerolls;
    uint8_t target, last_played, last_face, last_on, rerolled, result;
    uint8_t combo[S_COUNT]; /* faces of each slot played this turn */
    int32_t old_shield;
    int turn, hero_lost, hero_healed, self_hits, lost_this_round;
    /* this hero turn, for the combos study: damage to enemies (the kittens' pounces at its
       end too), the systems it touched (SYS_ bits), the faces played (a bit an item row) */
    int t_dmg;
    uint8_t t_sys, in_turn;
    uint64_t t_played;
    /* the boosts this fight: how many a face row took (a waiting +1 or times) and what they
       added to its number */
    uint16_t boosts[ITEM_COUNT], boost_gain[ITEM_COUNT];
    uint8_t kitten_peak; /* the most kittens she had at once this fight */
    /* the chain cards (items_after_play): the tray spots whose dice come back to be rolled
       (a bit a spot; a search's copy, with no rng, leaves them so), refreshes this turn,
       enemies fallen (finishing swat), what the play being landed set off */
    uint8_t back, refreshes, falls, wand_on, dot_fired, swat_back, stretch;
    /* this turn, for the chains study: dice back by red dot, big stretch, nine lives; swats
       come back; re-rolls got (lucky paw, sunbeam) */
    uint8_t t_dot, t_stretch, t_nine, t_swat, t_gain;
    /* the combo cards: scratching habit's uses this fight, nine lives' hit points to come back
       with (0: spent or not held), the hairballs rolled this turn (cough it up) */
    uint8_t habit, revive, hair;
    uint16_t blunders; /* the skill ladder's random plays this fight (players.c blunder) */
} Battle;

/* the systems a turn can touch: a book paid with mana, kittens, a three-in-a-turn combo, a
   status put on or paying off (marked hits, wet, tangled), a trick's boost used, a charm */
enum { SYS_MANA = 1, SYS_KITTEN = 2, SYS_COMBO = 4, SYS_STATUS = 8, SYS_TRICK = 16,
       SYS_CHARM = 32 };

/* battle.c, hit.c: rules.py, hit.py */
void b_init(Battle *b, const Setup *k, int hero_hp, int maxhp, const uint8_t *enemies, int n,
            Mt *rng);
void b_set_enemy(Battle *b, int i, int k);
void b_start_round(Battle *b);
void b_roll(Battle *b);
int b_can_play(const Battle *b, int s);
int b_playable_count(const Battle *b);
int b_any_unplayed(const Battle *b);
int b_turn_over(const Battle *b);
void b_play(Battle *b, int s, int target); /* target NOTHING: the face's own, or the last */
void b_reroll(Battle *b);
void b_after_action(Battle *b);
void b_apply(Battle *b, int effect, int by, int target, int n);
int b_next_standing(const Battle *b, int t);
void b_curse(Battle *b, int effect, int target, int n);
void b_strike(Battle *b, int by, int target, int amount, int pierce);
void b_strike_plain(Battle *b, int target, int damage);
void b_lose(Battle *b, int who, int n);
void b_heal(Battle *b, int who, int n);
void b_add(Battle *b, int who, int status, int n);
void b_end_turn(Battle *b);

/* foes.c: foes.py */
void foes_end_turn(Battle *b);
void foes_summon(Battle *b, int by, int n);

/* items.c: items.py */
int charm_amount(const Battle *b, int kind);
void items_fight_start(Battle *b);
void items_round_start(Battle *b);
void items_land(Battle *b, int row, int target, int again);
void items_turn_end(Battle *b);
void items_hero_hurt(Battle *b);
void items_ward_blocked(Battle *b);
void items_clog(Battle *b, int slot);
void items_cough(Battle *b);
void items_after_play(Battle *b, int s);
void items_roll_back(Battle *b);
void items_fallen(Battle *b, int who, int fleas, int haunt);

/* cards.c: the chain and combo cards' effects (1 if e is one) */
int cards_effect(Battle *b, int e, int t, int n);

/* the run's kit (rewards.py Kit): an item a slot, a level a slot, the charms in order */
typedef struct {
    uint8_t items[6];
    uint8_t level[6];
    uint8_t charms[8];
    int ncharms;
    uint8_t locked; /* slots whose item no card replaces (a bit a slot: the combos bench) */
    uint8_t kittens; /* kept from the last fight (the litter box charm) */
    uint8_t revived; /* nine lives (die once) spent */
} Kit;

extern const Kit *START_KIT; /* the kit runs start with instead of the starting items */

void kit_start(Kit *kit);
void kit_setup(const Kit *kit, Setup *k);
int kit_has(const Kit *kit, int kind);

/* the rule switches, for comparing (main.c sets them from the command line) */
typedef struct {
    int toe_fix;  /* the sixth toe gives a sixth die (the Python sim's bag kept 5); on */
    int mult_cap; /* a waiting times stacks to this at most (0: 255, the byte; the default) */
    int kitten_rule; /* 0: a kitten runs off each time she loses hit points; 1: when a
                        hit-all lands on her */
    int dot_charges; /* red dot's # is how many times it fires (the default; 0: the turns
                        it lasts, --dot-turns) */
    int refresh_most; /* refreshes a turn at most (0: 255, a byte) */
} Rules;
extern Rules RULES;

#endif
