/* Readable battle logs: a line a turn with her and the enemies, a line a die played (its
   number, what it hit), the hooks' and charms' notes, the re-rolls, the enemies' moves. Only a
   battle with b->tell set writes; the search's copies have none. */
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "tell.h"

void tell_printf(Tell *t, const char *fmt, ...) {
    if (!t)
        return;
    int room = TELL_MAX - t->len;
    if (room <= 1)
        return;
    va_list ap;
    va_start(ap, fmt);
    int w = vsnprintf(t->text + t->len, room, fmt, ap);
    va_end(ap);
    t->len += w < room ? w : room - 1;
}

void tell_line(Battle *b, const char *fmt, ...) {
    Tell *t = b->tell;
    if (!t)
        return;
    int room = TELL_MAX - t->len;
    if (room <= 2)
        return;
    va_list ap;
    va_start(ap, fmt);
    int w = vsnprintf(t->text + t->len, room - 1, fmt, ap);
    va_end(ap);
    t->len += w < room - 1 ? w : room - 2;
    t->text[t->len++] = '\n';
    t->text[t->len] = 0;
}

void tell_fail(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "catwiz sim: ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
    exit(1);
}

static const char *who(const Battle *b, int i) {
    return i == HERO ? "Catwiz" : KINDS[b->kind[i]].name;
}

static const char *const SHORT[] = {
    "sh", "flea", "fturn", "wet", "cheer", "ward", "refl", "laser", "str", "tang", "mark",
    "hurt", "fresh", "dot", "catf", "circ", "scared", "hypno", "bers", "leech", "mleech",
    "snag", "sleep", "box", "mana", "plus", "plusl", "mult", "spook", "thorn", "kit", "nip",
    "nipd", "kfl", "kwa", "keep", "wish", "mirr", "gamb", "habit", "sharp", "snow", "scars",
    "collar", "wall", "echo", "allin", "flip", "mom", "rolls", "tmp"};

_Static_assert(sizeof SHORT / sizeof *SHORT == ST_COUNT, "a short name a status");

static void stacks(Battle *b, int i, char *buf) {
    int n = i == HERO ? ST_COUNT : FOE_COUNT, len = 0;
    buf[0] = 0;
    for (int s = 0; s < n; s++) {
        int v = stk(b, i, s);
        if (v && s != ST_hurt && s != ST_scars && len < 200)
            len += sprintf(buf + len, " %s%d", SHORT[s], v);
    }
}

void tell_turn(Battle *b) {
    if (!b->tell)
        return;
    char buf[256];
    stacks(b, HERO, buf);
    tell_line(b, "-- turn %d: Catwiz %d/%d%s, re-rolls %d", b->turn, b->hp[HERO], b->maxhp[HERO],
              buf, b->rerolls);
    for (int i = 1; i < ACTORS; i++) {
        if (!b->alive[i])
            continue;
        stacks(b, i, buf);
        tell_line(b, "   %d %s %d/%d%s, next: %s %d", i, KINDS[b->kind[i]].name, b->hp[i],
                  b->maxhp[i], buf, MOVES[b->move[i]].text, MOVES[b->move[i]].amount);
    }
    int len = 0;
    char dice[200];
    dice[0] = 0;
    for (int d = 0; d < b->dice_n; d++)
        len += sprintf(dice + len, "%s%s", d ? ", " : "",
                       b->held[d] != NOTHING ? "(held)" : FACES[row_id(b, b->hand[d])].name);
    tell_line(b, "   dice: %s", dice);
}

void tell_play(Battle *b, int row, int target) {
    tell_line(b, "  plays %s on %s", FACES[row_id(b, row)].name, who(b, target));
}

void tell_play_done(Battle *b) {
    (void)b;
}

void tell_hit(Battle *b, int target, int damage) {
    tell_line(b, "    hits %s for %d", who(b, target), damage);
}

void tell_beaten(Battle *b, int i) {
    tell_line(b, "    %s is beaten", KINDS[b->kind[i]].name);
}

void tell_move(Battle *b, int by, int row, int target) {
    tell_line(b, "  %s: %s %d on %s", who(b, by), MOVES[row].text, MOVES[row].amount,
              target == NOTHING ? "-" : who(b, target));
}

void tell_reroll(Battle *b) {
    int len = 0;
    char dice[200];
    dice[0] = 0;
    for (int d = 0; d < b->dice_n; d++)
        if (!b->played[d])
            len += sprintf(dice + len, "%s%s", len ? ", " : "", FACES[row_id(b, b->hand[d])].name);
    tell_line(b, "  re-rolls: %s", dice);
}
