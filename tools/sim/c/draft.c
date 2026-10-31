/* The searching player's picks between fights: each option (a card, a charm, the nap's heal
   or level, a door) is tried in rollouts of the next DRAFT.ahead fights, the same imagined
   dice for every option (seeds from her own random numbers, never the game's). A rollout is
   played by the greedy player (very fast; the strong player in rollouts is many times
   slower), its picks in between by the greedy table. An option's worth:
   the hit points left after the window, a death costing DEATH less what was got through,
   and the kit's worth at the end (rewards.c kit_worth) times DRAFT.kit, for what the window
   does not see. 512 runs a setup (2026-10-31): the strong player's draft (greedy rollouts of
   the next fight, 6 seeds) won 89%, 1 fight ahead 16 seeds 92%, 3 ahead 98%, 11 ahead 98%. */
#include "search.h"

Draft DRAFT = {.rollouts = 24, .ahead = 3, .roll_player = P_GREEDY, .kit = 0.5};

#define DEATH 60.0

static double window(const Kit *kit, int hp, int f, int door, uint32_t seed) {
    Mt rng, prng;
    mt_seed(&rng, seed);
    mt_seed(&prng, seed ^ 0x5EED);
    Kit k = *kit;
    Player greedy = {P_GREEDY, &prng};
    for (int j = 0; j < DRAFT.ahead && f + j < FIGHT_COUNT; j++) {
        int idx = f + j;
        if (j == 0 && door != NOTHING)
            idx = door;
        else if (FIGHTS[idx].other != NOTHING)
            idx = pick_door(&greedy, &k, hp, idx, FIGHTS[idx].other);
        Battle b;
        play_fight(DRAFT.roll_player, &prng, &k, hp, idx, &rng, NULL, &b, NULL);
        if (b.result != R_WON) {
            int left = b.hp[1] + b.hp[2] + b.hp[3], full = 0;
            for (int i = 0; i < FIGHTS[idx].count; i++)
                full += KINDS[FIGHTS[idx].enemies[i]].hp;
            double got = full ? 1.0 - (double)left / full : 0;
            return -DEATH + 10.0 * (j + (got > 0 ? got : 0));
        }
        hp = b.hp[HERO];
        if (f + j + 1 < FIGHT_COUNT && j + 1 < DRAFT.ahead)
            reward_pick(&greedy, &k, &hp, f + j + 1, idx, NULL);
    }
    return hp + DRAFT.kit * kit_worth(&k);
}

static double worth_of(Player *p, const Kit *kit, int hp, int f, int door, const uint32_t *seeds) {
    (void)p;
    double t = 0.0;
    for (int i = 0; i < DRAFT.rollouts; i++)
        t += window(kit, hp, f, door, seeds[i]);
    return t / DRAFT.rollouts;
}

static void make_seeds(Player *p, uint32_t *seeds) {
    for (int i = 0; i < DRAFT.rollouts; i++)
        seeds[i] = mt_bits(p->rng, 30);
}

int search_choose(Player *p, const Kit *kit, int hp, int f, const Pick *opts, int n) {
    uint32_t seeds[64];
    make_seeds(p, seeds);
    int best = 0;
    double bv = 0.0;
    for (int i = 0; i < n; i++) {
        Kit k2 = *kit;
        pick_apply(&k2, &opts[i]);
        double v = worth_of(p, &k2, hp, f, NOTHING, seeds);
        if (i == 0 || v > bv) {
            bv = v;
            best = i;
        }
    }
    return best;
}

int search_nap(Player *p, const Kit *kit, int hp, int heal, const Pick *up, int f) {
    uint32_t seeds[64];
    make_seeds(p, seeds);
    Kit k2 = *kit;
    pick_apply(&k2, up);
    return worth_of(p, kit, heal, f, NOTHING, seeds) >= worth_of(p, &k2, hp, f, NOTHING, seeds);
}

int search_door(Player *p, const Kit *kit, int hp, int f, int other) {
    uint32_t seeds[64];
    make_seeds(p, seeds);
    double a = worth_of(p, kit, hp, f, f, seeds);
    double b = worth_of(p, kit, hp, f, other, seeds);
    return a >= b ? f : other;
}
