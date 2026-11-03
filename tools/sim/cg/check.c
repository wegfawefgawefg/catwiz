/* catwiz-check: one step of the sim from a position read off the real game (validate.py).
   It reads the machine's state as lines "name n n n ..." on stdin (validate.py's FIELDS: her
   kit and charms, the actors, the stacks, the dice, the turn's flags, the engine's lets that
   carry between steps, and lib/random's seed), then the action ("play D T", "flip D",
   "reroll", "end"), does it with the game's own random numbers (the xorshift from the seed),
   and prints the state after in the same lines. */
#include <stdio.h>
#include <stdlib.h>

#include "sim.h"

static Setup K;
static Battle B;

typedef struct {
    const char *name;
    uint8_t *at;
    int n;
} Field;

static uint8_t charm_ids[HELD_CHARMS], charm_counts[HELD_CHARMS], held_n, seed_lo, seed_hi;

static Field fields[] = {
    {"items", K.items, 6},
    {"levels", K.level, 6},
    {"held_n", &held_n, 1},
    {"charm_ids", charm_ids, HELD_CHARMS},
    {"charm_counts", charm_counts, HELD_CHARMS},
    {"kind_amount", K.kind_amount, K_COUNT},
    {"kind_count", K.kind_count, K_COUNT},
    {"mana_most", &K.mana_most, 1},
    {"hp", B.hp, ACTORS},
    {"max_hp", B.maxhp, ACTORS},
    {"alive", B.alive, ACTORS},
    {"kind", B.kind, ACTORS},
    {"move", B.move, ACTORS},
    {"moves_made", B.made, ACTORS},
    {"stacks", B.stacks, STACKS},
    {"dice_n", &B.dice_n, 1},
    {"face_of", B.face_of, 6},
    {"hand", B.hand, 6},
    {"played", B.played, 6},
    {"held", B.held, 6},
    {"clogged", B.clogged, 6},
    {"rerolls", &B.rerolls, 1},
    {"rerolled", &B.rerolled, 1},
    {"combo", B.combo, 6},
    {"last_face", &B.last_face, 1},
    {"last_on", &B.last_on, 1},
    {"last_played", &B.last_played, 1},
    {"wand_on", &B.wand_on, 1},
    {"back_due", &B.back_due, 1},
    {"booked", &B.booked, 1},
    {"lucky", &B.lucky, 1},
    {"nap_die", &B.nap_die, 1},
    {"refreshes", &B.refreshes, 1},
    {"risen", &B.risen, 1},
    {"target", &B.target, 1},
    {"three", &B.three, 1},
    {"counts", &B.counts, 1},
    {"blocked", &B.blocked, 1},
    {"lost", &B.lost, 1},
    {"echo_next", &B.echo_next, 1},
    {"mimicked_v", &B.mim_v, 1},
    {"fight_extra", &B.fight_extra, 1},
    {"kept", &B.kept, 1},
    {"spent", &B.spent, 1},
    {"hat_id", &B.hat_id, 1},
    {"seed_lo", &seed_lo, 1},
    {"seed_hi", &seed_hi, 1},
};
#define NFIELDS (int)(sizeof fields / sizeof *fields)

static void print_state(const char *result) {
    seed_lo = (uint8_t)(B.xs & 255);
    seed_hi = (uint8_t)(B.xs >> 8);
    for (int f = 0; f < NFIELDS; f++) {
        printf("%s", fields[f].name);
        for (int i = 0; i < fields[f].n; i++)
            printf(" %d", fields[f].at[i]);
        printf("\n");
    }
    printf("result %s\n", result);
}

int main(void) {
    char line[4096], action[64] = "";
    int ad = 0, at = 0;
    while (fgets(line, sizeof line, stdin)) {
        char name[64];
        int off;
        if (sscanf(line, "%63s%n", name, &off) != 1)
            continue;
        if (!strcmp(name, "action")) {
            sscanf(line + off, "%63s %d %d", action, &ad, &at);
            continue;
        }
        for (int f = 0; f < NFIELDS; f++) {
            if (strcmp(name, fields[f].name))
                continue;
            char *p = line + off;
            for (int i = 0; i < fields[f].n; i++)
                fields[f].at[i] = (uint8_t)strtol(p, &p, 10);
        }
    }
    K.ncharms = held_n;
    for (int h = 0; h < held_n; h++) {
        K.charms[h] = charm_ids[h];
        K.charm_n[h] = charm_counts[h];
    }
    /* the spent flags: a bit a held charm (validate.py packs state.spent) */
    B.k = &K;
    B.xs = (uint16_t)(seed_lo | seed_hi << 8);
    B.xs_on = 1;
    B.nap_die = B.nap_die;
    B.mim_row = NOTHING;
    B.in_turn = 1;
    if (!strcmp(action, "play"))
        b_play(&B, ad, at);
    else if (!strcmp(action, "flip"))
        b_roll_die(&B, ad, (B.face_of[ad] + 1) % 6);
    else if (!strcmp(action, "reroll"))
        b_reroll(&B);
    else if (!strcmp(action, "end")) {
        b_end_turn(&B);
        if (B.result == R_NONE)
            b_start_round(&B);
    }
    print_state(B.result == R_WON ? "won" : B.result == R_LOST ? "lost" : "none");
    return 0;
}
