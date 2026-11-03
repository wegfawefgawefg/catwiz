/* Readable logs of a battle (tell.c): each turn's position, each die played and what it did,
   the re-rolls, the enemies' moves. A battle with tell set writes into it; copies have none. */
#ifndef TELL_H
#define TELL_H
#include "sim.h"

#define TELL_MAX (1 << 18)

typedef struct Tell {
    char text[TELL_MAX];
    int len;
} Tell;

void tell_line(Battle *b, const char *fmt, ...);
void tell_fail(const char *fmt, ...);
void tell_play(Battle *b, int row, int target);
void tell_play_done(Battle *b);
void tell_hit(Battle *b, int target, int damage);
void tell_beaten(Battle *b, int who);
void tell_move(Battle *b, int by, int row, int target);
void tell_reroll(Battle *b);
void tell_printf(Tell *t, const char *fmt, ...);
void tell_turn(Battle *b);

#endif
