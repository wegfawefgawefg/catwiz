/* Hits, hit points and statuses: battle/hit.tsp (strike, plain, lose, die, heal, add_stacks),
   content/statuses.tsp (start, turn_start's part in battle.c, wear, turn_end, skips, dealt,
   taken, gain_mana) and battle/spawn.tsp's enemy. Line for line, in the game's order. */
#include "sim.h"
#include "tell.h"

int rnd_byte(Battle *b) {
    if (b->xs_on) { /* lib/random.tsp: 16-bit xorshift 7, 9, 8 */
        uint16_t x = b->xs;
        x ^= (uint16_t)(x << 7);
        x ^= x >> 9;
        x ^= (uint16_t)(x << 8);
        b->xs = x;
        return x & 0xFF;
    }
    if (b->rng)
        return (int)mt_bits(b->rng, 8);
    uint32_t x = b->srng ? b->srng : 0x9E3779B9u; /* xorshift32 */
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    b->srng = x;
    return (int)(x >> 24);
}

void spawn_enemy(Battle *b, int i, int kind, int fresh) {
    const KindRow *k = &KINDS[kind];
    b->alive[i] = 1;
    b->kind[i] = (uint8_t)kind;
    b->hp[i] = k->hp;
    b->maxhp[i] = k->hp;
    b->move[i] = k->first;
    b->made[i] = 0;
    st_start(b, i, kind);
    if (fresh)
        set_stk(b, i, ST_fresh, 1);
    b->peak.seen_kinds |= 1u << kind;
}

/* statuses.start: no stacks, and the ward its kind has (the hero: NOTHING) */
void st_start(Battle *b, int who, int kind) {
    int n = who == HERO ? ST_COUNT : FOE_COUNT;
    for (int s = 0; s < n; s++)
        set_stk(b, who, s, 0);
    if (kind != NOTHING)
        set_stk(b, who, ST_ward, KINDS[kind].ward);
}

static void wear(Battle *b, int who, int s) {
    int n = stk(b, who, s);
    if (n > 0)
        set_stk(b, who, s, n - 1);
}

/* statuses.turn_end: wet dries, a leech lets go a turn, tangle is the snag, fleas bite */
int st_turn_end(Battle *b, int who) {
    wear(b, who, ST_wet);
    wear(b, who, ST_leech);
    set_stk(b, who, ST_tangle, stk(b, who, ST_snag));
    set_stk(b, who, ST_snag, 0);
    int turns = stk(b, who, ST_flea_turns);
    if (turns == 0)
        return 0;
    int bite = stk(b, who, ST_poison);
    set_stk(b, who, ST_flea_turns, turns - 1);
    if (turns == 1)
        set_stk(b, who, ST_poison, 0);
    return bite;
}

int st_skips(const Battle *b, int who) {
    return (stk(b, who, ST_fresh) | stk(b, who, ST_sleep)) > 0;
}

/* statuses.dealt: cheer and strength add (cheer used when use), tangle takes off, wet halves */
uint8_t st_dealt(Battle *b, int who, int damage, int use) {
    int cheer = stk(b, who, ST_cheer);
    if (use)
        set_stk(b, who, ST_cheer, 0);
    int d = sum8(sum8(damage, cheer), stk(b, who, ST_strength));
    int tangle = stk(b, who, ST_tangle);
    d = d > tangle ? d - tangle : 0;
    if (stk(b, who, ST_wet) > 0)
        d >>= 1;
    return (uint8_t)d;
}

static int st_taken(Battle *b, int who, int damage) {
    int shield = stk(b, who, ST_shield);
    if (shield >= damage) {
        set_stk(b, who, ST_shield, shield - damage);
        return 0;
    }
    set_stk(b, who, ST_shield, 0);
    return damage - shield;
}

void st_gain_mana(Battle *b, int n) {
    if (n == 0)
        return;
    int now = sum8(her(b, ST_mana), n);
    if (now > b->k->mana_most)
        now = b->k->mana_most;
    set_stk(b, HERO, ST_mana, now);
}

void hit_add(Battle *b, int who, int status, int n) {
    set_stk(b, who, status, sum8(stk(b, who, status), n));
}

static void note_hit(Battle *b, int damage) {
    if (damage > b->peak.max_hit)
        b->peak.max_hit = (uint8_t)damage;
    if (damage >= 255 && b->peak.hits255 < 65535)
        b->peak.hits255++;
}

/* hit.strike */
void hit_strike(Battle *b, int by, int target, int amount, int pierce) {
    b->lost = 0;
    if (by == HERO)
        hooks_status(b, W_her_hit, target, target);
    int damage = sum8(st_dealt(b, by, amount, 1), stk(b, target, ST_brand));
    if (target != HERO) {
        if (stk(b, target, ST_wet) > 0)
            damage = sum8(damage, ch_amount(b, K_boots));
        if (by != HERO)
            for (int k = 0; k < ch_count(b, K_trouble); k++)
                damage = sum8(damage, damage);
    }
    if (by == HERO) {
        if (target == HERO)
            b->self_hits++;
        int back = stk(b, target, ST_reflect);
        if (back > damage)
            back = damage;
        if (back > 0) {
            set_stk(b, target, ST_reflect, stk(b, target, ST_reflect) - back);
            damage -= back;
            hit_plain(b, HERO, back);
        }
        if (target != HERO)
            note_hit(b, damage);
    }
    int at_her = target == HERO && by != HERO;
    if (at_her) {
        int shield = her(b, ST_shield);
        b->blocked = (uint8_t)(shield > damage ? damage : shield);
        if (shield >= damage && damage > 0 && ch_held(b, K_porcupine))
            hooks_add(b, RW_QUILLS, by, ch_amount(b, K_porcupine));
    }
    if (b->tell && by == HERO)
        tell_hit(b, target, damage);
    if (pierce)
        hit_lose(b, target, damage);
    else
        hit_plain(b, target, damage);
    if (at_her)
        hooks_status(b, W_hit_her, HERO, by);
}

void hit_plain(Battle *b, int target, int damage) {
    damage = st_taken(b, target, damage);
    if (damage == 0)
        return;
    hit_lose(b, target, damage);
}

static void die(Battle *b, int who) {
    if (who != HERO)
        hooks_status(b, W_falls, who, who);
    for (int d = 0; d < DICE_MOST; d++)
        if (b->held[d] == who)
            b->held[d] = NOTHING;
    if (who != HERO) {
        int next = KINDS[b->kind[who]].then;
        if (b->in_turn && b->full_at_start[who] && b->kind_at_start[who] == b->kind[who] &&
            b->peak.n_one_turn < 8)
            b->peak.one_turn_kind[b->peak.n_one_turn++] = b->kind[who];
        b->full_at_start[who] = 0;
        if (next != NOTHING) {
            spawn_enemy(b, who, next, 1);
            b->risen |= (uint8_t)(1 << who);
            if (b->tell)
                tell_line(b, "  %s gets up", KINDS[next].name);
            return;
        }
    }
    b->alive[who] = 0;
    if (who != HERO) {
        if (b->tell)
            tell_beaten(b, who);
        ch_hook(b, W_kill);
    }
}

/* hit.lose */
void hit_lose(Battle *b, int who, int n) {
    if (!b->alive[who])
        return;
    if (b->risen & (1 << who))
        return;
    int hp = b->hp[who];
    if (n > hp)
        n = hp;
    int left = hp - n;
    b->lost = (uint8_t)n;
    if (left == 0 && n > 0 && who == HERO) {
        left = ch_saved(b);
        if (left > b->maxhp[who])
            left = b->maxhp[who];
        if (left && b->tell)
            tell_line(b, "  Catwiz comes back with %d", left);
    }
    b->hp[who] = (uint8_t)left;
    if (who == HERO) {
        b->hero_lost += n;
        if (n > 0)
            ch_hero_hurt(b);
    } else {
        hit_add(b, who, ST_hurt, n);
        if (b->in_turn)
            b->t_dmg += n;
    }
    if (left == 0)
        die(b, who);
}

void hit_heal(Battle *b, int who, int n) {
    int hp = b->hp[who];
    int room = b->maxhp[who] - hp;
    if (n > room)
        n = room;
    if (n == 0)
        return;
    b->hp[who] = (uint8_t)(hp + n);
    if (who == HERO)
        b->hero_healed += n;
}
