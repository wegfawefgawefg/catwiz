/* The catalog sim: Catwiz's battle as the game plays it, every face and charm a row of steps
   from the game's own files (gen.py writes gen_content.h from game/content). Each file says
   which game file it mirrors:

     play.c    content/play.tsp (the step interpreter, curses, drain, a face landing, her
               turn's end) and content/hooks.tsp (the queue)
     fx.c      content/effects.tsp (a face's number, the boosts, paying, the pounce) and
               content/charms.tsp (the charms' amounts, their moments, the turn's start)
     hit.c     battle/hit.tsp (strike, plain, lose, die, heal) and content/statuses.tsp
     foes.c    content/foes.tsp (who a move goes to, what it does, summons)
     battle.c  battle/turn.tsp and battle/dice.tsp (the turn, the dice, the enemies' turn) and
               battle/battle.tsp's fight start

   The players (players.c, judge.c, search.c, value.c), the run and its picks (run.c,
   rewards.c, draft.c) and the studies are the item sim's (tools/sim/c), changed for this
   engine. A battle is a plain struct: a search copies it with =. */
#ifndef SIM_H
#define SIM_H
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#include "gen_content.h"
#include "rng.h"

#define NOTHING 255
#define HERO 0
#define ACTORS 4
#define STACKS 120 /* state.STACKS: hers, then three enemies' FOE_COUNT each */
#define MAX_HAND DICE_MOST
#define MAX_PLAYS 24
#define TURN_CAP 60 /* a fight this long counts as lost: the player is stuck */
#define BACK_DIE 3.0
#define HAT_ROW 19 /* content/items: the row a hat trick's face is read into */
#define JUNK_ROW 6 /* content/items: the hairball's row */
#define CALLS 3
#define LOOPS 3
#define STEP_GUARD 200000 /* steps in one play past which the sim calls it a runaway */
#define FLIP 0x40 /* a play's target with this bit: a paw flip turns die s to face t & 7 */

enum { R_NONE, R_WON, R_LOST };

/* what a fight is played with, fixed for the fight (content/charms' kinds' totals) */
typedef struct {
    uint8_t items[6]; /* catalog ids, a slot each */
    uint8_t level[6];
    uint8_t charms[HELD_CHARMS], charm_n[HELD_CHARMS];
    int ncharms;
    uint8_t kind_amount[K_COUNT], kind_count[K_COUNT];
    uint8_t mana_most;
} Setup;

struct Tell;

/* the most a fight showed (the broken study): the biggest hit, turns that hit the cap, the
   biggest turn, one-turn kills of the kinds at full hit points, chains, runaways */
typedef struct {
    uint8_t max_hit;
    uint16_t hits255, turn_dmg_max, max_steps;
    uint16_t turn_hit_max; /* the most her hits added up to in one turn, before hit points */
    uint8_t back_cap_turns, hat_deep, runaway;
    uint8_t one_turn_kind[8]; /* kinds killed from full in one of her turns */
    uint8_t n_one_turn;
    uint32_t seen_kinds; /* a bit a kind that stood in the fight */
} Peak;

typedef struct Battle {
    const Setup *k;
    Mt *rng;            /* the game's random numbers; NULL in a search's copy */
    struct Tell *tell;  /* a readable log, or NULL */
    /* ---- the position (hashed by the searches, from hp to the end of srng) */
    uint8_t hp[ACTORS], maxhp[ACTORS], alive[ACTORS], kind[ACTORS], move[ACTORS], made[ACTORS];
    uint8_t stacks[STACKS];
    uint8_t dice_n, face_of[MAX_HAND], hand[MAX_HAND], played[MAX_HAND], held[MAX_HAND];
    uint8_t clogged[6];
    uint8_t back; /* dice coming back to be rolled, waiting (a search's copy has no rng) */
    uint8_t rerolls, rerolled, combo[6];
    uint8_t last_face, last_on, last_played, wand_on, back_due, booked, lucky, nap_die;
    uint8_t refreshes, risen, target, three, counts, blocked, lost, echo_next;
    uint8_t mim_v, fight_extra, hat_id, spent, kept, result, flip_next, flips_used;
    uint16_t mim_row;
    uint16_t q_fx[4];
    uint8_t q_on[4], q_val[4], q_head, q_count;
    uint32_t srng; /* a search's copy's own random numbers (coins, picks, hats) */
    uint16_t xs;   /* the game's own random numbers (lib/random's xorshift), for check.c */
    uint8_t xs_on;
    /* ---- not the position */
    int turn, hero_lost, hero_healed, self_hits;
    int t_dmg;          /* damage to enemies this hero turn */
    int t_hit;          /* her hits on enemies this turn, as dealt (before their hit points) */
    uint8_t in_turn;    /* her turn is on (not the enemies') */
    uint8_t full_at_start[ACTORS]; /* at full hit points as her turn started (one-turn kills) */
    uint8_t kind_at_start[ACTORS];
    uint8_t calls_deep;
    uint64_t t_played;  /* faces played this turn, a bit an id (low 64 ids) */
    uint16_t blunders;
    Peak peak;
} Battle;

#define POS_BEGIN offsetof(Battle, hp)
#define POS_END offsetof(Battle, turn)

/* the stacks: state.stack, set_stack (who's first stack, then the status: an enemy's high
   statuses would run into the next enemy's, as in the game) */
static inline uint8_t stk(const Battle *b, int who, int s) {
    static const uint8_t FIRST[ACTORS] = {0, ST_COUNT, ST_COUNT + FOE_COUNT,
                                          ST_COUNT + 2 * FOE_COUNT};
    int i = FIRST[who] + s;
    return i < STACKS ? b->stacks[i] : 0;
}
static inline void set_stk(Battle *b, int who, int s, int n) {
    static const uint8_t FIRST[ACTORS] = {0, ST_COUNT, ST_COUNT + FOE_COUNT,
                                          ST_COUNT + 2 * FOE_COUNT};
    int i = FIRST[who] + s;
    if (i < STACKS)
        b->stacks[i] = (uint8_t)n;
}
static inline uint8_t her(const Battle *b, int s) {
    return b->stacks[s];
}
static inline uint8_t sum8(int a, int b) { /* st.sum: 255 at most */
    int s = a + b;
    return (uint8_t)(s > 255 ? 255 : s);
}

/* a random byte: the game's (b->rng) or a copy's own */
int rnd_byte(Battle *b);

/* hit.c */
void hit_strike(Battle *b, int by, int target, int amount, int pierce);
void hit_plain(Battle *b, int target, int damage);
void hit_lose(Battle *b, int who, int n);
void hit_heal(Battle *b, int who, int n);
void hit_add(Battle *b, int who, int status, int n);
void st_start(Battle *b, int who, int kind);
uint8_t st_dealt(Battle *b, int who, int damage, int use);
int st_turn_end(Battle *b, int who);
int st_skips(const Battle *b, int who);
void st_gain_mana(Battle *b, int n);
void spawn_enemy(Battle *b, int i, int kind, int fresh);

/* fx.c */
int row_id(const Battle *b, int row);
int row_slot(const Battle *b, int row);
int fx_cost(const Battle *b, int row);
int fx_can_play(const Battle *b, int row);
uint8_t fx_times(int n, int m);
uint8_t fx_number(const Battle *b, int row);
uint8_t fx_prepare(Battle *b, int row, int target, int again);
void fx_pounce(Battle *b, int t);
int fx_next_standing(const Battle *b, int t);
int ch_amount(const Battle *b, int kind);
int ch_count(const Battle *b, int kind);
int ch_held(const Battle *b, int kind);
void ch_hook(Battle *b, int when);
int ch_dice(const Setup *k);
int ch_round_start(Battle *b);
int ch_saved(Battle *b);
void ch_hero_hurt(Battle *b);

/* play.c */
void hooks_add(Battle *b, int row, int t, int v);
void hooks_status(Battle *b, int when, int holder, int t);
void play_run(Battle *b, int row, int t0, int n0);
void play_drain(Battle *b);
int play_curse(Battle *b, int t, int s, int v);
void play_land_face(Battle *b, int row, int target);
void play_turn_end(Battle *b);
int play_other_at_random(Battle *b, int t, int from);

/* foes.c */
int foes_skips(const Battle *b, int who);
int foes_move_target(Battle *b, int by, int row, int use);
void foes_land_move(Battle *b, int row, int by, int target);
void foes_next_move(Battle *b, int i);

/* battle.c */
void b_init(Battle *b, const Setup *k, int hp, int maxhp, int fight, uint8_t spent, int kept,
            Mt *rng);
void b_start_round(Battle *b);
int b_can_play(const Battle *b, int d);
int b_playable_count(const Battle *b);
int b_any_unplayed(const Battle *b);
int b_turn_over(const Battle *b);
void b_play(Battle *b, int d, int target);
int b_can_reroll(const Battle *b);
void b_reroll(Battle *b);
void b_reroll_to(Battle *b, const uint8_t *faces); /* a search's imagined re-roll */
void b_back_to(Battle *b, const uint8_t *faces);   /* a search's imagined dice coming back */
void b_end_turn(Battle *b);
void b_end_battle(Battle *b, int won);
void b_roll_die(Battle *b, int d, int f);
int b_any_enemy(const Battle *b);
int b_face_aim(const Battle *b, int d); /* the aim of the face die d shows */

/* the run's kit (rewards.c): an item a slot, a level a slot, the charms in order */
typedef struct {
    uint8_t items[6];
    uint8_t level[6];
    uint8_t charms[HELD_CHARMS];
    int ncharms;
    uint8_t locked; /* slots whose item no card replaces (a bit a slot: the benches) */
    uint8_t kept;   /* state.kept: the kittens kept from the last fight (half, rounded up) */
    uint8_t spent;  /* a bit a held charm: spent this run (nine lives) */
    uint8_t hp_max;
} Kit;

extern const Kit *START_KIT;

void kit_start(Kit *kit);
void kit_setup(const Kit *kit, Setup *k);
int kit_has(const Kit *kit, int kind);
int kit_holds(const Kit *kit, int charm);

#endif
