/* Hits, hit points and statuses: tools/sim/hit.py (the game's battle/hit.tsp, statuses.tsp
   taken and lose). */
#include "sim.h"
#include "tell.h"

static int dealt(Battle *b, int who, int damage) {
    int32_t *st = b->st[who];
    int cheer = st[ST_CHEER];
    st[ST_CHEER] = 0;
    int d = damage + cheer + st[ST_STRENGTH];
    if (d > 255)
        d = 255; /* a hit is a byte: it saturates (the owner, 2026-11-01; it wrapped) */
    if (st[ST_TANGLE]) {
        d -= st[ST_TANGLE];
        if (d < 0)
            d = 0;
    }
    if (st[ST_WET] > 0)
        d >>= 1;
    return d;
}

void b_strike(Battle *b, int by, int target, int amount, int pierce) {
    if (by == HERO && target == HERO)
        b->self_hits++;
    int32_t *st = b->st[target];
    if (by == HERO && b->wand_on && st[ST_DOT] && !b->dot_fired) {
        b->dot_fired = 1; /* a wand hit on a red dot: all dice back (items_after_play) */
        if (RULES.dot_charges)
            st[ST_DOT]--;
    }
    int damage = dealt(b, by, amount);
    damage += st[ST_BRAND];
    if (damage > 255)
        damage = 255;
    if (st[ST_BRAND] && by == HERO)
        b->t_sys |= SYS_STATUS; /* a marked hit */
    if (st[ST_REFLECT] && by == HERO) {
        int back = st[ST_REFLECT] < damage ? st[ST_REFLECT] : damage;
        st[ST_REFLECT] = (int32_t)(st[ST_REFLECT] - back);
        damage -= back;
        b_strike_plain(b, HERO, back);
    }
    if (b->tell && by == HERO)
        tell_hit(b, target, damage);
    int back = 0;
    if (target == HERO && by != HERO && st[ST_MIRROR]) { /* mirror fur */
        back = st[ST_SHIELD] < damage ? st[ST_SHIELD] : damage;
        if (back > st[ST_MIRROR])
            back = st[ST_MIRROR];
        st[ST_MIRROR] -= back;
    }
    if (pierce)
        b_lose(b, target, damage);
    else
        b_strike_plain(b, target, damage);
    if (back)
        b_lose(b, by, back);
    if (target == HERO && by != HERO && b->st[HERO][ST_THORNS])
        b_lose(b, by, b->st[HERO][ST_THORNS]);
}

/* statuses.taken, then hit.lose */
void b_strike_plain(Battle *b, int target, int damage) {
    int32_t *st = b->st[target];
    int shield = st[ST_SHIELD];
    if (shield >= damage) {
        st[ST_SHIELD] = (int32_t)(shield - damage);
        return;
    }
    st[ST_SHIELD] = 0;
    b_lose(b, target, damage - shield);
}

static void release(Battle *b, int who) {
    for (int d = 0; d < b->ndice; d++) {
        if (b->held[d] == who) {
            b->held[d] = NOTHING;
            b->in_draw[d] = 1;
        }
    }
}

static void die(Battle *b, int who) {
    if (who == HERO) {
        b->alive[HERO] = 0;
        return;
    }
    int then = KINDS[b->kind[who]].then;
    b->falls++; /* finishing swat */
    int fleas = b->st[who][ST_CIRCUS] ? b->st[who][ST_POISON] : 0, haunt = b->st[who][ST_HAUNT];
    release(b, who);
    if (then != NOTHING) {
        /* the possum gets up, the elites' second forms, the boss's next phase: a round to
           get up, it skips one move */
        b_set_enemy(b, who, then);
        b->st[who][ST_FRESH] = 1;
        if (b->tell)
            tell_line(b, "  %s GETS UP", KINDS[then].name);
    } else {
        b->alive[who] = 0;
        if (b->tell)
            tell_beaten(b, who);
    }
    if (fleas || haunt)
        items_fallen(b, who, fleas, haunt);
}

void b_lose(Battle *b, int who, int n) {
    if (!b->alive[who])
        return;
    int hp = b->hp[who];
    if (n > hp)
        n = hp;
    if (who == HERO && n == hp && n > 0 && b->revive) { /* nine lives: once a run */
        b->hp[HERO] = b->revive < b->maxhp[HERO] ? b->revive : b->maxhp[HERO];
        b->revive = 0;
        b->hero_lost += n;
        b->lost_this_round += n;
        items_hero_hurt(b);
        if (b->tell)
            tell_line(b, "  CATWIZ COMES BACK");
        return;
    }
    b->hp[who] = (int32_t)(hp - n);
    if (who == HERO) {
        b->hero_lost += n;
        b->lost_this_round += n;
        if (n > 0)
            items_hero_hurt(b);
    } else {
        b->st[who][ST_HURT] = (int32_t)(b->st[who][ST_HURT] + n);
        if (b->in_turn)
            b->t_dmg += n;
    }
    if (hp - n == 0)
        die(b, who);
}

void b_heal(Battle *b, int who, int n) {
    int hp = b->hp[who] + n;
    if (hp > b->maxhp[who])
        hp = b->maxhp[who];
    if (who == HERO)
        b->hero_healed += hp - b->hp[who];
    b->hp[who] = (int32_t)hp;
}

void b_add(Battle *b, int who, int status, int n) {
    int v = b->st[who][status] + n;
    b->st[who][status] = (int32_t)(v < 255 ? v : 255); /* bytes, saturating (99 before) */
}

