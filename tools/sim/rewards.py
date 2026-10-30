"""The reward after a won fight (battle/reward.tsp) and the proposal's nap and elite doors,
for each policy. The game's offers: one of the fight's two new dice into the bag (not when it
is full: BAG_MOST), one face of a bag die upgraded (faces upgrade), or a die out of the bag
(not the last). The proposal adds: a new die into a full bag takes the place of one you pick.

random picks any offer; greedy the one that most raises the bag's worth by a fixed table
of what each face is worth (face_worth); strong tries the best few of those in rollouts of
the next fight (the greedy player, the same dice for every option) and takes the best.
"""

import random

import policy as po
from rules import NOTHING, HERO

ROLLOUTS = 6
SHORTLIST = 5


def face_worth(rules, row):
    """a rough worth of a face, in damage-equivalents, for picking rewards"""
    f = rules.faces[row]
    e = f.effect
    a = f.amount
    table = {
        "hit": a, "shield": 0.6 * a, "heal": 0.7 * a, "mana": 1.1 * a, "plus": 1.0 * a,
        "double": 2.5, "nothing": 0.0, "fleas": 2.5 * a / 2, "wet": 1.5, "hiss": 2.0,
        "bath": 1.0, "hairball": 6.0, "zoomies": 5.5, "box": 4.0, "scream": 6.0,
        "mark": 3.0, "laser": 3.0, "knock": 5.5, "catnip": 4.0, "thorns": 4.0,
        "static": 5.0, "ward": 1.5,
    }
    w = table.get(e, 1.0)
    if f.cost:
        w -= 0.9 * f.cost  # its mana came from star faces that did nothing else
        w = max(w, 0.5)
    return w


def die_worth(rules, faces):
    return sum(face_worth(rules, r) for r in faces) / len(faces)


def bag_worth(rules, dice):
    n = len(dice)
    total = sum(die_worth(rules, d) for d in dice)
    return total * min(n, rules.hand) / n


def options(rules, dice, offers):
    out = []
    for k, die in enumerate(offers):
        if len(dice) < rules.bag_most:
            out.append(("add", k, None))
        elif rules.proposal:
            seen = set()
            for d in range(len(dice)):
                if tuple(dice[d]) not in seen:
                    seen.add(tuple(dice[d]))
                    out.append(("swap", k, d))
    seen = set()
    for d in range(len(dice)):
        for f in range(len(dice[d])):
            row = dice[d][f]
            key = (tuple(dice[d]), row)
            if rules.faces[row].upgrade != NOTHING and key not in seen:
                seen.add(key)
                out.append(("up", d, f))
    if len(dice) > 1:
        seen = set()
        for d in range(len(dice)):
            if tuple(dice[d]) not in seen:
                seen.add(tuple(dice[d]))
                out.append(("remove", d, None))
    return out


def apply(rules, dice, names, offers, opt):
    """a copy of the bag and its names with option opt taken, and what it was in words"""
    dice = [list(d) for d in dice]
    names = list(names)
    what, a, b = opt
    if what == "add":
        dice.append(list(offers[a]))
        names.append(rules.die_name(offers[a]))
        text = "new " + names[-1]
    elif what == "swap":
        text = "new %s for %s" % (rules.die_name(offers[a]), names[b])
        dice[b] = list(offers[a])
        names[b] = rules.die_name(offers[a])
    elif what == "up":
        old = rules.faces[dice[a][b]]
        dice[a][b] = old.upgrade
        text = "upgrade %s: %s to %s" % (names[a], old.name, rules.faces[old.upgrade].name)
    else:
        text = "remove " + names[a]
        del dice[a]
        del names[a]
    return dice, names, text


def rollout(rules, dice, hp, fight, seeds):
    """the greedy player's mean result in fight index fight with this bag: hit points left,
    or a big loss"""
    import run  # here, not at the top: run imports this module

    total = 0.0
    for s in seeds:
        pol = po.Greedy(rules, random.Random(s))
        b, _ = run.play_fight(rules, pol, dice, hp, rules.fights[fight].enemies, run.GameRng(s))
        total += b.hp[HERO] if b.result == "won" else -40.0 + 0.5 * (b.hp[HERO] - sum(b.hp[1:]))
    return total / len(seeds)


def pick(rules, pol, dice, names, hp, f, prng):
    """the reward after fight f - 1, before fight f; changes dice and names in place"""
    offers = rules.fights[f - 1].offers
    opts = options(rules, dice, offers)
    if pol.name == "random":
        # the four offers first, as the screen has them, then what that offer asks
        kinds = sorted(set(o[0] for o in opts))
        k = kinds[prng.randrange(len(kinds))]
        sub = [o for o in opts if o[0] == k]
        opt = sub[prng.randrange(len(sub))]
    else:
        scored = sorted(opts, key=lambda o: -bag_worth(rules, apply(rules, dice, names, offers, o)[0]))
        opt = scored[0]
        if pol.name == "strong":
            short = scored[:SHORTLIST]
            for o in opts:
                if o[0] in ("add", "swap") and o not in short:
                    short.append(o)
            seeds = [prng.getrandbits(30) for _ in range(ROLLOUTS)]
            best = None
            for o in short:
                v = rollout(rules, apply(rules, dice, names, offers, o)[0], hp, f, seeds)
                if best is None or v > best:
                    best = v
                    opt = o
    nd, nn, text = apply(rules, dice, names, offers, opt)
    dice[:] = nd
    names[:] = nn
    return text


def nap(rules, pol, dice, names, hp, f, prng):
    """PROPOSAL: after an elite, a nap: NAP_HEAL hit points back, or a face upgraded"""
    ups = [o for o in options(rules, dice, []) if o[0] == "up"]
    heal = min(rules.hero_hp, hp + rules.nap_heal)
    if not ups:
        return heal, "nap: heal"
    best_up = max(ups, key=lambda o: bag_worth(rules, apply(rules, dice, names, [], o)[0]))
    if pol.name == "random":
        take_heal = prng.random() < 0.5
    elif pol.name == "greedy":
        take_heal = heal - hp >= rules.nap_heal * 0.7
    else:
        seeds = [prng.getrandbits(30) for _ in range(ROLLOUTS)]
        v_heal = rollout(rules, dice, heal, f, seeds)
        v_up = rollout(rules, apply(rules, dice, names, [], best_up)[0], hp, f, seeds)
        take_heal = v_heal >= v_up
    if take_heal:
        return heal, "nap: heal to %d" % heal
    nd, nn, text = apply(rules, dice, names, [], best_up)
    dice[:] = nd
    names[:] = nn
    return hp, "nap: " + text


def pick_door(rules, pol, dice, hp, f, other, prng):
    """PROPOSAL: fight f or its other door; the player sees both before choosing"""
    if pol.name == "random":
        return f if prng.random() < 0.5 else other
    if pol.name == "greedy":
        def total(i):
            return sum(rules.kinds[k].hp for k in rules.fights[i].enemies)
        return f if total(f) <= total(other) else other
    seeds = [prng.getrandbits(30) for _ in range(ROLLOUTS)]
    return f if rollout(rules, dice, hp, f, seeds) >= rollout(rules, dice, hp, other, seeds) else other
