/* Whole runs: tools/sim/run.py (play_fight, one_run). The fights in order with the hero's hit
   points and kit carried over, and the choices between fights (rewards.c). Seeds: the dice
   take random.Random(seed), the player random.Random(seed ^ 0x5EED), as the Python sim. */
#include <stdio.h>
#include <stdlib.h>

#include "run.h"
#include "tell.h"

/* one fight: the battle as it ended in *out; faces shown and played into use (or NULL) */
int play_fight(int player, Mt *prng, const Kit *kit, int hp, int index, Mt *rng,
               Tell *tell, Battle *out, RunResult *use) {
    const FightRow *fight = &FIGHTS[index];
    Setup k;
    kit_setup(kit, &k);
    Player pl = {player, prng};
    Battle *b = out;
    b_init(b, &k, hp, HERO_HP, fight->enemies, fight->count, rng);
    b->tell = tell;
    b_start_round(b);
    while (b->result == R_NONE) {
        if (tell)
            tell_turn(b);
        player_turn(&pl, b);
        if (use) {
            for (int s = 0; s < HAND; s++) {
                if (b->tray[s] == NOTHING)
                    continue;
                use->seen[b->hand[s]]++;
                use->played[b->hand[s]] += b->played[s];
            }
        }
        if (b->result == R_NONE)
            b_end_turn(b);
        if (use && use->nturns < MAX_TURNS) {
            TurnRec *t = &use->turns[use->nturns++];
            t->played = b->t_played;
            t->fight = (uint8_t)(use->nfights + 1);
            t->turn = (uint8_t)b->turn;
            t->dmg = (uint8_t)(b->t_dmg < 255 ? b->t_dmg : 255);
            t->sys = b->t_sys;
        }
        if (b->result != R_NONE || b->turn >= TURN_CAP)
            break;
        b_start_round(b);
    }
    if (b->result == R_NONE)
        b->result = R_LOST;
    b->k = NULL; /* k was this function's */
    return b->result == R_WON;
}

void run_one(int player, uint64_t seed, RunResult *out, int want_log) {
    memset(out, 0, sizeof *out);
    Mt prng, rng;
    mt_seed(&prng, seed ^ 0x5EED);
    mt_seed(&rng, seed);
    Player pl = {player, &prng};
    Kit kit;
    kit_start(&kit);
    if (START_KIT)
        kit = *START_KIT;
    int hp = HERO_HP;
    Tell *tell = want_log ? calloc(1, sizeof(Tell)) : NULL;
    if (tell)
        tell->row = -1;
    char buf[400], words[64];
    for (int f = 0; f < FIGHT_COUNT;) {
        const FightRow *fight = &FIGHTS[f];
        int index = f;
        if (fight->other != NOTHING) {
            index = pick_door(&pl, &kit, hp, f, fight->other);
            const Force *fo = forced_at(FORCE_DOOR, f);
            if (fo)
                index = fo->a;
            if (DOOR_FORCE.on && DOOR_FORCE.after == f)
                index = DOOR_FORCE.a;
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
            tell_printf(tell, "== fight %d (%s) hp %d kit: %s\n", f + 1, names, hp,
                        kit_words(&kit, buf));
        }
        Battle b;
        play_fight(player, &prng, &kit, hp, index, &rng, tell, &b, out);
        FightResult *fr = &out->fights[out->nfights++];
        fr->index = (uint8_t)index;
        fr->won = b.result == R_WON;
        fr->hp_in = (uint8_t)hp;
        fr->hp_out = (uint8_t)b.hp[HERO];
        fr->turns = (uint8_t)b.turn;
        fr->lost = (uint8_t)b.hero_lost;
        fr->healed = (uint8_t)b.hero_healed;
        fr->self_hits = (uint8_t)b.self_hits;
        if (b.result != R_WON)
            break;
        hp = b.hp[HERO];
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
