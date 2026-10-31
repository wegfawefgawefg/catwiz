"""Whole runs: the fights in order with the hero's hit points and kit carried over, and the
choices between fights (rewards.py), then the report.

    python3 tools/sim/run.py                       # the game's fights 1-2, every policy
    python3 tools/sim/run.py --content proposal --policy strong --runs 400
    python3 tools/sim/run.py --content proposal --trace --policy greedy --runs 1 --jobs 1
    python3 tools/sim/run.py --content bag --variant upgrade=single     # see variants.py

Content: game (game/content), proposal (the item-slot model, tools/sim/proposal), bag (the
bag model's proposal, tools/sim/proposal_bag). Seeds: run n of --seed s uses
s * 100000 + n, so a run is the same each time.
"""

import argparse
import multiprocessing
import random
import sys
import time

import content
import policy as po
import report
import rewards
from rules import Battle, HERO, NOTHING

TURN_CAP = 60  # a fight this long counts as lost: the policy is stuck


class GameRng:
    """the dice's random bytes for a sim run (the emulator's own xorshift is in validate.py)"""

    def __init__(self, seed):
        self.r = random.Random(seed)

    def byte(self):
        return self.r.getrandbits(8)


def play_fight(rules, pol, kit, hp, index, rng, trace=None):
    fight = rules.fights[index]
    b = Battle(rules, kit.dice, hp, fight.enemies, rng, charms=tuple(kit.charms),
               levels=kit.battle_levels(), zone=fight.zone, lives=kit.lives)
    b.maxhp[HERO] = kit.max_hp()
    b.log = trace
    b.start_round()
    usage = []
    while b.result is None:
        if trace is not None:
            trace.append(describe(b))
        pol.turn(b)
        usage.append([(b.tray[s], b.played[s], b.hand[s]) for s in range(rules.hand)])
        if b.result is not None:
            break
        b.end_turn()
        if b.result is not None or b.turn >= TURN_CAP:
            break
        b.start_round()
    if b.result is None:
        b.result = "lost"
    return b, usage


def describe(b):
    R = b.R
    foes = []
    for i in range(1, 4):
        if b.alive[i]:
            m = R.moves[b.move[i]]
            foes.append("%s %d (%s)" % (R.kinds[b.kind[i]].name, b.hp[i],
                                        m.text.replace("#", str(m.amount))))
    hand = [R.faces[b.hand[s]].name for s in range(R.hand) if b.tray[s] != NOTHING]
    return "turn %d  hp %d mana %d | %s | dice: %s" % (
        b.turn, b.hp[HERO], b.st[HERO][8], "; ".join(foes), ", ".join(hand))


def one_run(args):
    which, variant, pname, seed, trace_on = args
    rules = content.load(which, variant)
    prng = random.Random(seed ^ 0x5EED)
    pol = po.POLICIES[pname](rules, prng)
    rng = GameRng(seed)
    kit = rewards.Kit(rules)
    hp = rules.hero_hp
    out = {"fights": [], "won": False, "picks": [], "use": {}, "faces": {}}
    trace = [] if trace_on else None
    f = 0
    while f < rules.fight_count:
        fight = rules.fights[f]
        index = f
        if fight.other != NOTHING:
            index = rewards.pick_door(rules, pol, kit, hp, f, fight.other, prng)
        if trace is not None:
            trace.append("== fight %d (%s) hp %d kit: %s" % (
                f + 1, ", ".join(rules.kinds[k].name for k in rules.fights[index].enemies), hp,
                kit_words(rules, kit)))
        b, usage = play_fight(rules, pol, kit, hp, index, rng, trace)
        for turn in usage:
            for d, played, row in turn:
                if d == NOTHING:
                    continue
                name = kit.names[d] if d < len(kit.names) else "HAIRBALL"
                u = out["use"].setdefault(name, [0, 0])
                u[0] += 1
                u[1] += 1 if played else 0
                if kit.items is not None:
                    u = out["faces"].setdefault(rules.faces[row].name, [0, 0])
                    u[0] += 1
                    u[1] += 1 if played else 0
        kit.lives = b.lives
        out["fights"].append({"index": index, "won": b.result == "won", "hp_in": hp,
                              "hp_out": b.hp[HERO], "turns": b.turn, "lost": b.hero_lost,
                              "self_hits": b.self_hits, "bag": len(kit.dice),
                              "healed": b.hero_healed})
        if b.result != "won":
            break
        hp = b.hp[HERO]
        f += 1
        if f >= rules.fight_count:
            out["won"] = True
            break
        kit, hp, taken = rewards.pick(rules, pol, kit, hp, f, index, prng, rng)
        out["picks"] += [(f, t) for t in taken]
        if trace is not None:
            trace.append("   took: " + "; ".join(taken))
    out["bag"] = len(kit.dice)
    out["kit"] = kit_words(rules, kit)
    out["trace"] = trace
    return out


def kit_words(rules, kit):
    if kit.items is None:
        return " | ".join(rules.face_names(d) for d in kit.dice)
    words = []
    for s in range(6):
        lv = kit.level(s)
        words.append(rules.faces[kit.items[s]].name + ("+" * lv))
    return ", ".join(words) + ("; charms: " + " ".join(kit.charms) if kit.charms else "")


def run_many(which, variant, pname, runs, seed=1, jobs=8, trace=False):
    args = [(which, variant, pname, seed * 100000 + n, trace) for n in range(runs)]
    if jobs > 1 and runs > 1:
        with multiprocessing.Pool(min(jobs, 8)) as pool:
            return pool.map(one_run, args, chunksize=max(1, runs // 64))
    return [one_run(x) for x in args]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--content", default="game", choices=sorted(content.DIRS))
    ap.add_argument("--policy", default="all")
    ap.add_argument("--runs", type=int, default=300)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--trace", action="store_true")
    ap.add_argument("--variant", default="", help="see variants.py")
    ap.add_argument("--picks", action="store_true", help="what won runs took, fight by fight")
    a = ap.parse_args()
    names = list(po.POLICIES) if a.policy == "all" else a.policy.split(",")
    rules = content.load(a.content, a.variant)
    for p in content.check_engine(rules):
        print("ENGINE CHANGED: " + p)
    for pname in names:
        t0 = time.time()
        results = run_many(a.content, a.variant, pname, a.runs, a.seed, a.jobs, a.trace)
        dt = time.time() - t0
        if a.trace:
            for r in results:
                print("\n".join(r["trace"]))
        report.print_report(rules, pname, results, dt, a.picks)
        sys.stdout.flush()


if __name__ == "__main__":
    main()
