/* Readable battle logs: each turn's position, each die played with its boosts and what it
   did ("ZOOMIES x2 +1 = 3: 5 hits of 4 (GARDEN GNOME 3, SPORELET 2)"), the re-rolls, the
   enemies' moves. Only a battle with b->tell set calls these. */
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

static void vline(Tell *t, const char *fmt, va_list ap) {
    int room = TELL_MAX - t->len;
    if (room <= 2)
        return;
    int w = vsnprintf(t->text + t->len, room - 1, fmt, ap);
    t->len += w < room - 1 ? w : room - 2;
    t->text[t->len++] = '\n';
    t->text[t->len] = 0;
}

void tell_line(Battle *b, const char *fmt, ...) {
    if (!b->tell)
        return;
    va_list ap;
    va_start(ap, fmt);
    vline(b->tell, fmt, ap);
    va_end(ap);
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

const char *short_name(int kind) {
    return KINDS[kind].name;
}

static const char *who(const Battle *b, int i) {
    return i == HERO ? "CATWIZ" : KINDS[b->kind[i]].name;
}

static void after(Tell *t, const char *fmt, ...) {
    int len = (int)strlen(t->after);
    if (len >= (int)sizeof t->after - 2)
        return;
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(t->after + len, sizeof t->after - len, fmt, ap);
    va_end(ap);
}

void tell_turn(Battle *b) {
    Tell *t = b->tell;
    const int32_t *h = b->st[HERO];
    tell_printf(t, "turn %d  hp %d mana %d", b->turn, b->hp[HERO], h[ST_MANA]);
    if (h[ST_SHIELD])
        tell_printf(t, " shield %d", h[ST_SHIELD]);
    if (h[ST_KITTENS])
        tell_printf(t, " kittens %d", h[ST_KITTENS]);
    if (h[ST_PLUS_LEFT])
        tell_printf(t, " (+%d waits)", h[ST_PLUS]);
    if (h[ST_MULT])
        tell_printf(t, " (x%d waits)", h[ST_MULT]);
    if (h[ST_WISH])
        tell_printf(t, " (wish waits)");
    tell_printf(t, " |");
    for (int i = 1; i < ACTORS; i++) {
        if (!b->alive[i])
            continue;
        const MoveRow *m = &MOVES[b->move[i]];
        tell_printf(t, " %s %d", who(b, i), b->hp[i]);
        if (b->st[i][ST_SHIELD])
            tell_printf(t, " sh%d", b->st[i][ST_SHIELD]);
        if (b->st[i][ST_BRAND])
            tell_printf(t, " marked%d", b->st[i][ST_BRAND]);
        if (b->st[i][ST_WET])
            tell_printf(t, " wet%d", b->st[i][ST_WET]);
        if (b->st[i][ST_FLEA_TURNS])
            tell_printf(t, " fleas%dx%d", b->st[i][ST_POISON], b->st[i][ST_FLEA_TURNS]);
        tell_printf(t, " (");
        for (const char *c = m->text; *c; c++) {
            if (*c == '#')
                tell_printf(t, "%d", m->amount);
            else
                tell_printf(t, "%c", *c);
        }
        tell_printf(t, ");");
    }
    tell_printf(t, " | dice:");
    for (int s = 0; s < b->hand_n; s++)
        if (b->tray[s] != NOTHING)
            tell_printf(t, " %s%s", ITEMS[b->hand[s]].name, s + 1 < b->hand_n ? "," : "");
    tell_printf(t, "\n");
}

/* CATWIZ_PYLOG=1: the Python sim's log lines too (check.py compares them) */
static int pylog(void) {
    static int on = -1;
    if (on < 0)
        on = getenv("CATWIZ_PYLOG") != NULL;
    return on;
}

void tell_play(Battle *b, int row, int target) {
    Tell *t = b->tell;
    if (pylog()) {
        int aim = ITEMS[row].aim;
        if (target == HERO || aim == A_all)
            tell_line(b, "  CATWIZ USES %s", ITEMS[row].name);
        else
            tell_line(b, "  CATWIZ USES %s on %s", ITEMS[row].name, who(b, target));
    }
    const int32_t *h = b->st[HERO];
    int slot = ITEMS[row].slot;
    t->row = row;
    t->target = target;
    t->n = -1;
    t->nhits = 0;
    t->copied = -1;
    t->boosts[0] = 0;
    t->after[0] = 0;
    char *p = t->boosts;
    if (h[ST_MULT] && (slot == S_wand || slot == S_fluff || slot == S_book))
        p += sprintf(p, " x%d", h[ST_MULT]);
    if (h[ST_PLUS_LEFT] && slot != S_trick)
        p += sprintf(p, " +%d", h[ST_PLUS]);
    if (h[ST_NIP] && slot != S_trick)
        p += sprintf(p, " +1nip");
    if (slot == S_wand && h[ST_WISH])
        p += sprintf(p, " wish x2");
    if (slot == S_wand && h[ST_KNEAD_WAND])
        p += sprintf(p, " knead +%d", h[ST_KNEAD_WAND]);
    if (slot == S_fluff && h[ST_KNEAD_FLUFF])
        p += sprintf(p, " knead x2");
    if (h[ST_SPOOK] && slot != S_trick)
        p += sprintf(p, " spooked -%d", h[ST_SPOOK]);
}

void tell_number(Battle *b, int n) {
    if (b->tell->n < 0)
        b->tell->n = n;
}

void tell_copy(Battle *b, int row, int on) {
    (void)on;
    b->tell->copied = row;
}

void tell_hit(Battle *b, int target, int damage) {
    Tell *t = b->tell;
    if (t->nhits < 16) {
        t->hit_target[t->nhits] = b->kind[target];
        t->hit_damage[t->nhits] = damage;
        t->nhits++;
    }
}

void tell_status(Battle *b, int target, int effect, int n) {
    Tell *t = b->tell;
    if (effect < 0) {
        after(t, "; %s's ward blocks it", who(b, target));
        return;
    }
    const char *what = effect == E_fleas ? "fleas" : effect == E_wet ? "wet"
                     : effect == E_spook ? "spooked" : effect == E_brand ? "marked"
                     : effect == E_tangled ? "tangled" : "shield gone";
    after(t, "; %s %s %d", who(b, target), what, n);
}

void tell_combo(Battle *b, int combo) {
    static const char *const words[] = {"", "3rd: hits all", "3rd: shield stays",
                                        "3rd: spikes", "3rd: box, +kitten", "3rd: heal",
                                        "3rd: static", "3rd: ward pip"};
    after(b->tell, "; %s", combo < 8 ? words[combo] : "3rd: ?");
}

void tell_pounce(Battle *b, int target, int n, int each) {
    Tell *t = b->tell;
    if (t->row >= 0)
        after(t, "; %d kitten pounces on %s for %d", n, who(b, target), each);
    else
        tell_line(b, "  %d kitten pounces on %s for %d", n, who(b, target), each);
}

void tell_beaten(Battle *b, int who_) {
    Tell *t = b->tell;
    if (t->row >= 0)
        after(t, "; %s beaten", who(b, who_));
    else
        tell_line(b, "  %s beaten", who(b, who_));
}

/* the hits of a play, folded: "5 hits of 4 (GNOME 3, SPORELET 2)" or "4 on GNOME, 2 on .." */
static void hits_words(Tell *t, char *out) {
    out[0] = 0;
    if (!t->nhits)
        return;
    int same = 1;
    for (int i = 1; i < t->nhits; i++)
        same &= t->hit_damage[i] == t->hit_damage[0];
    char *p = out;
    if (same && t->nhits > 1) {
        p += sprintf(p, ": %d hits of %d (", t->nhits, t->hit_damage[0]);
        int done[16] = {0};
        for (int i = 0; i < t->nhits; i++) {
            if (done[i])
                continue;
            int c = 0;
            for (int j = i; j < t->nhits; j++)
                if (t->hit_target[j] == t->hit_target[i]) {
                    c++;
                    done[j] = 1;
                }
            p += sprintf(p, "%s%s %d", i ? ", " : "", KINDS[t->hit_target[i]].name, c);
        }
        sprintf(p, ")");
        return;
    }
    for (int i = 0; i < t->nhits; i++)
        p += sprintf(p, "%s %d on %s", i ? "," : ":", t->hit_damage[i],
                     KINDS[t->hit_target[i]].name);
}

void tell_play_done(Battle *b) {
    Tell *t = b->tell;
    const ItemRow *it = &ITEMS[t->row];
    char hits[400];
    hits_words(t, hits);
    char on[64] = "";
    if (it->aim == A_foe && t->target != HERO)
        sprintf(on, " on %s", who(b, t->target));
    char num[24] = "";
    if (t->n >= 0 && it->slot != S_trick)
        sprintf(num, " = %d", t->n);
    char cp[48] = "";
    if (t->copied >= 0)
        sprintf(cp, " (copies %s)", ITEMS[t->copied].name);
    tell_line(b, "  %s%s%s%s%s%s%s", it->name, cp, t->boosts, num, on, hits, t->after);
    t->row = -1;
}

void tell_move(Battle *b, int by, int row, int target) {
    const MoveRow *m = &MOVES[row];
    char text[64], *p = text;
    for (const char *c = m->text; *c; c++) {
        if (*c == '#')
            p += sprintf(p, "%d", m->amount);
        else
            *p++ = *c;
    }
    *p = 0;
    char extra[64] = "";
    if (target != HERO && target != by)
        sprintf(extra, " (at %s)", who(b, target));
    if (b->st[by][ST_STRENGTH] && (m->effect == E_hit || m->effect == E_hit2))
        sprintf(extra + strlen(extra), " +%d strength", b->st[by][ST_STRENGTH]);
    tell_line(b, "  %s: %s%s", who(b, by), text, extra);
}

void tell_reroll(Battle *b, const uint8_t *before) {
    char was[200] = "", now[200] = "";
    for (int s = 0; s < b->hand_n; s++) {
        if (b->played[s])
            continue;
        sprintf(was + strlen(was), "%s%s", was[0] ? ", " : "", ITEMS[before[s]].name);
        sprintf(now + strlen(now), "%s%s", now[0] ? ", " : "", ITEMS[b->hand[s]].name);
    }
    tell_line(b, "  re-roll %s -> %s", was, now);
    if (pylog())
        tell_line(b, "  RE-ROLL: %s", now);
}
