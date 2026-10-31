/* Readable logs of a battle (tell.c): what each die did, the enemies' moves, the re-rolls.
   A battle with tell set writes into it; searches' copies have none. */
#ifndef TELL_H
#define TELL_H
#include "sim.h"

#define TELL_MAX (1 << 18)

typedef struct Tell {
    char text[TELL_MAX];
    int len;
    /* the play being told */
    int row, target, n, nhits, hit_target[16], hit_damage[16], copied;
    char boosts[64], after[160];
} Tell;

void tell_line(Battle *b, const char *fmt, ...);
void tell_fail(const char *fmt, ...);
void tell_play(Battle *b, int row, int target);
void tell_play_done(Battle *b);
void tell_number(Battle *b, int n);
void tell_copy(Battle *b, int row, int on);
void tell_hit(Battle *b, int target, int damage);
void tell_status(Battle *b, int target, int effect, int n);
void tell_combo(Battle *b, int combo);
void tell_pounce(Battle *b, int target, int n, int each);
void tell_beaten(Battle *b, int who);
void tell_move(Battle *b, int by, int row, int target);
void tell_reroll(Battle *b, const uint8_t *before);
void tell_printf(Tell *t, const char *fmt, ...);
void tell_turn(Battle *b);
const char *short_name(int kind);

#endif
