"""Whole runs: the fights in order with the hero's hit points and bag carried over, the
reward after each won fight (battle/reward.tsp: one of the two new dice, a face upgraded, or a
die out of the bag), and the report.

    python3 tools/sim/run.py                       # game content, every policy, 300 runs
    python3 tools/sim/run.py --content proposal --policy strong --runs 400 --jobs 8
    python3 tools/sim/run.py --trace --policy greedy --runs 1    # one run, turn by turn

Seeds: run n of --seed s uses s * 100000 + n, so a run is the same each time.
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


def play_fight(rules, pol, dice, hp, kinds, rng, trace=None):
    b = Battle(rules, dice, hp, kinds, rng)
    b.log = trace
    b.start_round()
    usage = []
    while True:
        if trace is not None:
            trace.append(describe(b))
        pol.turn(b)
        usage.append([(b.tray[s], b.played[s]) for s in range(rules.hand)])
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
    which, pname, seed, trace_on = args
    rules = content.load(which)
    prng = random.Random(seed ^ 0x5EED)
    pol = po.POLICIES[pname](rules, prng)
    rng = GameRng(seed)
    dice = [list(d) for d in rules.start_dice]
    names = [rules.die_name(d) for d in dice]
    hp = rules.hero_hp
    out = {"fights": [], "won": False, "picks": [], "use": {}, "names": None}
    trace = [] if trace_on else None
    f = 0
    while f < rules.fight_count:
        fight = rules.fights[f]
        index = f
        if fight.other != NOTHING:
            index = rewards.pick_door(rules, pol, dice, hp, f, fight.other, prng)
        kinds = rules.fights[index].enemies
        if trace is not None:
            trace.append("== fight %d (%s) hp %d bag: %s" % (
                f + 1, ", ".join(rules.kinds[k].name for k in kinds), hp,
                " | ".join(rules.face_names(d) for d in dice)))
        b, usage = play_fight(rules, pol, dice, hp, kinds, rng, trace)
        for turn in usage:
            for d, played in turn:
                if d == NOTHING:
                    continue
                u = out["use"].setdefault(names[d], [0, 0])
                u[0] += 1
                u[1] += 1 if played else 0
        out["fights"].append({"index": index, "won": b.result == "won", "hp_in": hp,
                              "hp_out": b.hp[HERO], "turns": b.turn, "lost": b.hero_lost})
        if b.result != "won":
            break
        hp = b.hp[HERO]
        f += 1
        if f >= rules.fight_count:
            out["won"] = True
            break
        pick = rewards.pick(rules, pol, dice, names, hp, f, prng)
        out["picks"].append(pick)
        if fight.nap:
            hp, nap = rewards.nap(rules, pol, dice, names, hp, f, prng)
            out["picks"].append(nap)
        if trace is not None:
            trace.append("   reward: " + pick)
    out["names"] = names
    out["trace"] = trace
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--content", default="game", choices=["game", "proposal"])
    ap.add_argument("--policy", default="all")
    ap.add_argument("--runs", type=int, default=300)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument("--trace", action="store_true")
    a = ap.parse_args()
    names = list(po.POLICIES) if a.policy == "all" else a.policy.split(",")
    rules = content.load(a.content)
    problems = content.check_engine(rules)
    for p in problems:
        print("ENGINE CHANGED: " + p)
    for pname in names:
        jobs = [(a.content, pname, a.seed * 100000 + n, a.trace) for n in range(a.runs)]
        t0 = time.time()
        if a.jobs > 1 and a.runs > 1:
            with multiprocessing.Pool(min(a.jobs, 8)) as pool:
                results = pool.map(one_run, jobs, chunksize=max(1, a.runs // 64))
        else:
            results = [one_run(j) for j in jobs]
        dt = time.time() - t0
        if a.trace:
            for r in results:
                print("\n".join(r["trace"]))
        report.print_report(rules, pname, results, dt)
        sys.stdout.flush()


if __name__ == "__main__":
    main()
