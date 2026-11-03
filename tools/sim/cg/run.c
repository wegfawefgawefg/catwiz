/* Whole runs: the fights in order (battle/battle.tsp enter_fight, ending), her hit points, most
   hit points, kept kittens and spent charms carried over, the choices between fights
   (rewards.c). Seeds: the game's random numbers (the dice, the coins, the draws) take
   Mt(seed), the player Mt(seed ^ 0x5EED), so a run is the same for its seed on any threads. */
#include <stdio.h>
#include <stdlib.h>

#include "run.h"
#include "tell.h"

/* one fight: the battle as it ended in *out, the kit's kept kittens and spent charms and her
   hit points after it; faces shown and played into use (or NULL) */
int play_fight(int player, Mt *prng, Kit *kit, int *hp, int index, Mt *rng, Tell *tell,
               Battle *out, RunResult *use) {
    Setup k;
    kit_setup(kit, &k);
    Player pl = {player, prng};
    Battle *b = out;
    b_init(b, &k, *hp, kit->hp_max, index, kit->spent, kit->kept, rng);
    b->tell = tell;
    b_start_round(b);
    while (b->result == R_NONE) {
        if (tell)
            tell_turn(b);
        player_turn(&pl, b);
        if (use) {
            for (int d = 0; d < b->dice_n; d++) {
                if (b->held[d] != NOTHING)
                    continue;
                int id = row_id(b, b->hand[d]);
                use->seen[id]++;
                use->played[id] += b->played[d];
            }
        }
        if (b->result == R_NONE)
            b_end_turn(b);
        if (b->result != R_NONE || b->turn >= TURN_CAP)
            break;
        b_start_round(b);
    }
    if (b->result == R_NONE)
        b->result = R_LOST;
    if (use)
        use->blunders += b->blunders;
    kit->spent = b->spent;
    if (b->result == R_WON) {
        kit->kept = b->kept;
        *hp = b->hp[HERO];
    }
    b->k = NULL; /* k was this function's */
    return b->result == R_WON;
}

void run_one(int player, uint64_t seed, RunResult *out, int want_log) {
    memset(out, 0, sizeof *out);
    memset(out->offer, NOTHING, sizeof out->offer);
    memset(out->charm_offer, NOTHING, sizeof out->charm_offer);
    Mt prng, rng;
    mt_seed(&prng, seed ^ 0x5EED);
    mt_seed(&rng, seed);
    Player pl = {player, &prng};
    Kit kit;
    kit_start(&kit);
    if (START_KIT)
        kit = *START_KIT;
    int hp = kit.hp_max;
    Tell *tell = want_log ? calloc(1, sizeof(Tell)) : NULL;
    char buf[400], words[64];
    for (int f = 0; f < FIGHT_COUNT;) {
        int index = f;
        if (FIGHTS[f].other != NOTHING) {
            index = pick_door(&pl, &kit, hp, f, FIGHTS[f].other);
            const Force *fo = forced_at(FORCE_DOOR, f);
            if (fo)
                index = fo->a;
            if (out->npicks < MAX_PICKS) {
                Pick d = {PK_DOOR, (uint8_t)index, (uint8_t)f, (uint8_t)index};
                out->picks[out->npicks++] = d;
            }
        }
        out->kit_at[f] = kit;
        if (tell) {
            char names[120] = "";
            for (int i = 0; i < FIGHTS[index].count; i++)
                sprintf(names + strlen(names), "%s%s", i ? ", " : "",
                        KINDS[FIGHTS[index].enemies[i]].name);
            tell_printf(tell, "== fight %d (%s) hp %d/%d kit: %s\n", f + 1, names, hp, kit.hp_max,
                        kit_words(&kit, buf));
        }
        Battle b;
        FightResult *fr = &out->fights[out->nfights++];
        fr->hp_in = (uint8_t)hp;
        play_fight(player, &prng, &kit, &hp, index, &rng, tell, &b, out);
        fr->index = (uint8_t)index;
        fr->won = b.result == R_WON;
        fr->hp_out = b.hp[HERO];
        fr->turns = (uint8_t)b.turn;
        fr->lost = (uint8_t)(b.hero_lost < 255 ? b.hero_lost : 255);
        fr->healed = (uint8_t)(b.hero_healed < 255 ? b.hero_healed : 255);
        fr->self_hits = (uint8_t)(b.self_hits < 255 ? b.self_hits : 255);
        fr->peak = b.peak;
        if (b.result != R_WON)
            break;
        f++;
        if (f >= FIGHT_COUNT) {
            out->won = 1;
            break;
        }
        int before = out->npicks;
        reward_pick(&pl, &kit, &hp, f, index, out, &rng);
        if (tell) {
            tell_printf(tell, "   took:");
            for (int i = before; i < out->npicks; i++)
                tell_printf(tell, " %s;", pick_words(&out->picks[i], words));
            tell_printf(tell, "\n");
        }
    }
    out->kit = kit;
    if (tell) {
        out->log = malloc(tell->len + 1);
        memcpy(out->log, tell->text, tell->len);
        out->log[tell->len] = 0;
        free(tell);
    }
}
