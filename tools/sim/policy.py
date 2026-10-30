"""The sim's players. Each plays one hero turn (turn()) and picks rewards (in run.py, which
calls reward_pick()).

random  plays a random playable die on a random enemy until none is left; re-rolls or ends
        at random when stuck. A player mashing keys.
greedy  each step plays the one die and target that leaves the best position after the
        enemies' shown moves (the enemies are deterministic: their moves show); ends when no
        die helps. Re-rolls only dice it would not play.
strong  searches the whole turn: every order of dice and targets (merged where they lead to
        the same position), the enemies' moves, then the position; and whether to play some
        dice and re-roll the rest, by sampling the re-roll. Rewards by rollouts of the next
        fight.
"""

import rules as ru
from rules import HERO, ACTORS, NOTHING

# what a position is worth: the hero's hit point is worth W_HP of an enemy's, and an enemy
# standing costs its threat (damage a turn) THREAT_TURNS times more
W_HP = 2.0
THREAT_TURNS = 2.5


def kind_threat(rules):
    out = []
    for k in rules.kinds:
        total = 0.0
        for r in range(k.first, k.first + k.count):
            m = rules.moves[r]
            if m.effect == "hit":
                total += m.amount
            elif m.effect in ("fleas",):
                total += m.amount * 2.5
            elif m.effect in ("wet", "spook", "steal"):
                total += 2.0
            elif m.effect in ("summon",):
                total += 3.0 * m.amount
            elif m.effect in ("cheer", "mend", "shield", "reflect"):
                total += 1.0
        out.append(total / k.count)
    return out


def chain_hp(rules, k):
    """hit points still to come after this kind is beaten (a possum, the boss's phases)"""
    total = 0
    k = rules.kinds[k].then
    while k != NOTHING:
        total += rules.kinds[k].hp
        k = rules.kinds[k].then
    return total


class Judge:
    def __init__(self, rules):
        self.R = rules
        self.threat = kind_threat(rules)
        self.chain = [chain_hp(rules, k) for k in range(len(rules.kinds))]

    def value(self, b):
        """a position at the start of the hero's turn (or the fight's end)"""
        if b.result == "lost":
            return -100000.0
        st0 = b.st[HERO]
        v = W_HP * b.hp[HERO]
        if b.result == "won":
            return v + 1000.0
        v += 1.2 * min(st0[ru.MANA], 5) + 0.8 * st0[ru.PLUS] + 2.0 * st0[ru.DOUBLE]
        v += 0.6 * st0[ru.WARD]
        v -= W_HP * st0[ru.POISON] * st0[ru.FLEA_TURNS]
        for d in range(len(b.held)):
            if b.held[d] != NOTHING:
                v -= 3.0
        for i in range(1, ACTORS):
            if not b.alive[i]:
                continue
            s = b.st[i]
            k = b.kind[i]
            hp = b.hp[i] + self.chain[k]
            v -= hp + 0.8 * s[ru.SHIELD] + 0.5 * s[ru.WARD]
            v -= self.threat[k] * THREAT_TURNS
            if s[ru.FLEA_TURNS]:
                v += 0.9 * min(s[ru.POISON] * s[ru.FLEA_TURNS], b.hp[i])
        return v

    def after_turn(self, b):
        """b as the turn would end now: the enemies move, then the position"""
        if b.result is not None:
            return self.value(b)
        c = b.clone()
        c.end_turn()
        return self.value(c)


def options(b):
    """the distinct plays now: (slot, target), one slot for each face shown"""
    out = []
    seen = set()
    R = b.R
    for s in range(R.hand):
        if not b.can_play(s):
            continue
        row = b.hand[s]
        if row in seen:
            continue
        seen.add(row)
        if R.faces[row].aim == "foe":
            for t in range(1, ACTORS):
                if b.alive[t]:
                    out.append((s, t))
        else:
            out.append((s, None))
    return out


class Random:
    name = "random"

    def __init__(self, rules, rng):
        self.rng = rng

    def turn(self, b):
        while not b.turn_over():
            slots = b.playable()
            if slots:
                s = slots[self.rng.randrange(len(slots))]
                live = [t for t in range(1, ACTORS) if b.alive[t]]
                b.play(s, live[self.rng.randrange(len(live))])
                continue
            if b.rerolls > 0 and self.rng.random() < 0.5:
                b.reroll()
                continue
            break


class Greedy:
    name = "greedy"

    def __init__(self, rules, rng):
        self.judge = Judge(rules)
        self.rng = rng

    def turn(self, b):
        J = self.judge
        while not b.turn_over():
            best = J.after_turn(b)
            pick = None
            for s, t in options(b):
                c = b.clone()
                c.play(s, t)
                v = J.after_turn(c)
                if v > best + 1e-9:
                    best = v
                    pick = (s, t)
            if pick is not None:
                b.play(*pick)
                continue
            if b.rerolls > 0 and b.any_unplayed():
                b.reroll()
                continue
            break


class Strong:
    name = "strong"
    SAMPLES = 6  # re-roll samples
    NODE_CAP = 1500

    def __init__(self, rules, rng):
        self.judge = Judge(rules)
        self.rng = rng

    def key(self, b):
        return (tuple(b.played), tuple(b.hp), tuple(b.alive), tuple(b.kind),
                tuple(tuple(s) for s in b.st), tuple(b.held))

    def search(self, b, memo):
        """the best value of the turn from b with no more re-rolls, and its plays"""
        k = self.key(b)
        if k in memo:
            return memo[k]
        best = self.judge.after_turn(b)
        plan = []
        if b.result is None and len(memo) < self.NODE_CAP:
            for s, t in options(b):
                c = b.clone()
                c.play(s, t)
                v, p = self.search(c, memo)
                if v > best + 1e-9:
                    best = v
                    plan = [(s, t)] + p
        memo[k] = (best, plan)
        return best, plan

    def reroll_value(self, b):
        """b re-rolled: the mean best value of the turn over sampled rolls (the sim's own
        random numbers: the dice the hero will really get are not known)"""
        total = 0.0
        for _ in range(self.SAMPLES):
            c = b.clone()
            c.rng = SampleRng(self.rng)
            c.reroll()
            v, _ = self.search(c, {})
            total += v
        return total / self.SAMPLES

    def turn(self, b):
        while not b.turn_over():
            v0, plan = self.search(b, {})
            if b.rerolls > 0:
                # play the plan's first j dice, then re-roll the rest: the best j
                best_j = None
                best_v = v0
                c = b.clone()
                for j in range(len(plan) + 1):
                    if j > 0:
                        c.play(*plan[j - 1])
                        if c.result is not None:
                            break
                    if not c.any_unplayed():
                        break
                    v = self.reroll_value(c)
                    if v > best_v + 0.5:
                        best_v = v
                        best_j = j
                if best_j is not None:
                    for j in range(best_j):
                        b.play(*plan[j])
                    if b.result is None:
                        b.reroll()
                    continue
            if not plan:
                break
            for s, t in plan:
                b.play(s, t)
                if b.result is not None:
                    break
            break


class SampleRng:
    """random bytes for a search's imagined rolls, from the policy's own generator"""

    def __init__(self, rng):
        self.rng = rng

    def byte(self):
        return self.rng.getrandbits(8)


POLICIES = {"random": Random, "greedy": Greedy, "strong": Strong}
