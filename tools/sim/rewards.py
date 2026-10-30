"""The reward after a won fight (battle/reward.tsp) and the proposal's nap and elite doors,
for each policy. The game's offers: one of the fight's two new dice into the bag (not when it
is full: BAG_MOST), one face of a bag die upgraded (faces upgrade), or a die out of the bag
(not the last). The proposal adds: a new die into a full bag takes the place of one you pick.
The dogwitch variant (variants.py) has its own offers: a slot upgraded on every die, the spell
or curse slot swapped, or a charm.

random picks any offer; greedy the one that most raises the bag's worth by a fixed table
of what each face is worth (face_worth); strong tries the best few of those in rollouts of
the next fight (the greedy player, the same dice for every option) and takes the best.

A run's kit is its bag (dice, names: lists changed in place) and its charms (a list).
"""

import random

import policy as po
import variants
from rules import NOTHING, HERO, FAMILIES, family

TYPE_MOST = 3  # PROPOSAL: a face type takes +3 at most

ROLLOUTS = 6
SHORTLIST = 5

CHARM_WORTH = {"pocket": 3.0, "nightlight": 2.5, "fishbone": 3.0, "bell": 1.5, "pillow": 3.5}


def bonus_of(charms):
    return {fam: charms.count("type:" + fam) for fam in FAMILIES.values()}


def face_worth(rules, row, bonus=None):
    """a rough worth of a face, in damage-equivalents, for picking rewards"""
    f = rules.faces[row]
    e = f.effect
    a = f.amount + (bonus.get(family(f), 0) if bonus else 0)
    table = {
        "hit": a, "shield": 0.6 * a, "heal": 0.7 * a, "mana": 1.1 * a, "plus": 1.0 * a,
        "double": 2.5, "nothing": 0.0, "fleas": 2.5 * a / 2, "wet": 1.5, "hiss": 2.0,
        "bath": 1.0, "hairball": 6.0, "zoomies": 5.5, "box": 4.0, "scream": 6.0,
        "mark": 3.0, "laser": 3.0, "knock": 5.5, "catnip": 4.0, "thorns": 4.0,
        "static": 5.0, "ward": 1.5, "cough": 0.0,
    }
    w = table.get(e, 1.0)
    if f.cost:
        w -= 0.9 * f.cost  # its mana came from star faces that did nothing else
        w = max(w, 0.5)
    return w


def die_worth(rules, faces, bonus=None):
    return sum(face_worth(rules, r, bonus) for r in faces) / len(faces)


def kit_worth(rules, dice, charms):
    n = len(dice)
    bonus = bonus_of(charms)
    total = sum(die_worth(rules, d, bonus) for d in dice)
    return total * min(n, rules.hand) / n + sum(CHARM_WORTH.get(c, 0) for c in charms)


def upgrade_options(rules, dice, charms):
    """the upgrades on offer, by the run's rule (rules.upgrade): one face of one die
    (single, the game today), +1 to every face of a type, current and future dice (type, the
    proposal), or every face of a type in the bag one step up its upgrade row (typebag)"""
    out = []
    if rules.upgrade == "single":
        seen = set()
        for d in range(len(dice)):
            for face in range(len(dice[d])):
                row = dice[d][face]
                key = (tuple(dice[d]), row)
                if rules.faces[row].upgrade != NOTHING and key not in seen:
                    seen.add(key)
                    out.append(("up", d, face))
        return out
    present = set()
    for d in dice:
        for r in d:
            if rules.upgrade == "typebag" and rules.faces[r].upgrade == NOTHING:
                continue
            fam = family(rules.faces[r])
            if fam and charms.count("type:" + fam) < TYPE_MOST:
                present.add(fam)
    what = "type" if rules.upgrade == "type" else "typebag"
    return [(what, fam, None) for fam in sorted(present)]


def options(rules, dice, charms, offers, f):
    if "dogwitch" in rules.variant:
        return dogwitch_options(rules, dice, offers, f)
    out = []
    for k, die in enumerate(offers):
        if len(dice) < rules.bag_most:
            out.append(("add", k, None))
        elif rules.swap:
            seen = set()
            for d in range(len(dice)):
                if tuple(dice[d]) not in seen:
                    seen.add(tuple(dice[d]))
                    out.append(("swap", k, d))
    out += upgrade_options(rules, dice, charms)
    if len(dice) > 1:
        seen = set()
        for d in range(len(dice)):
            if tuple(dice[d]) not in seen:
                seen.add(tuple(dice[d]))
                out.append(("remove", d, None))
    return out


def dogwitch_options(rules, dice, offers, f):
    """every slot that upgrades; the offered dice's spells and curses for those slots; two
    charms, by the fight's number"""
    out = [("slot", s, None) for s in range(6) if rules.faces[dice[0][s]].upgrade != NOTHING]
    for die in offers:
        for r in die:
            face = rules.faces[r]
            if face.cost > 0 and r != dice[0][4]:
                out.append(("set", 4, r))
            elif face.effect in ("fleas", "wet", "hiss", "bath") and r != dice[0][5]:
                out.append(("set", 5, r))
    for k in (f, f + 2):
        out.append(("charm", variants.CHARMS[k % len(variants.CHARMS)][0], None))
    return list(dict.fromkeys(out))


def apply(rules, dice, names, charms, offers, opt):
    """a copy of the kit with option opt taken, and what it was in words"""
    what, a, b = opt
    charms = list(charms)
    if what == "type":
        charms.append("type:" + a)
        return [list(d) for d in dice], list(names), charms, "type %s +1" % a.upper()
    if what == "typebag":
        dice = [[rules.faces[r].upgrade if family(rules.faces[r]) == a and
                 rules.faces[r].upgrade != NOTHING else r for r in d] for d in dice]
        return dice, list(names), charms, "every %s face one step up" % a.upper()
    if what in ("slot", "set", "charm"):
        slots = list(dice[0])
        if what == "slot":
            text = "upgrade %s" % rules.faces[slots[a]].name
            slots[a] = rules.faces[slots[a]].upgrade
        elif what == "set":
            text = "slot: " + rules.faces[b].name
            slots[a] = b
        else:
            text = "charm " + a
            charms.append(a)
        return [slots] * len(dice), list(names), charms, text
    dice = [list(d) for d in dice]
    names = list(names)
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
    return dice, names, charms, text


def max_hp(rules, charms):
    return rules.hero_hp + 4 * charms.count("fishbone")


def rollout(rules, dice, hp, charms, fight, seeds):
    """the greedy player's mean result in fight index fight with this kit: hit points left,
    or a big loss"""
    import run  # here, not at the top: run imports this module

    total = 0.0
    for s in seeds:
        pol = po.Greedy(rules, random.Random(s))
        b, _ = run.play_fight(rules, pol, dice, hp, rules.fights[fight].enemies, run.GameRng(s),
                              charms=charms)
        total += b.hp[HERO] if b.result == "won" else -40.0 + 0.5 * (b.hp[HERO] - sum(b.hp[1:]))
    return total / len(seeds)


def take(dice, names, charms, kit):
    dice[:] = kit[0]
    names[:] = kit[1]
    charms[:] = kit[2]
    return kit[3]


def pick(rules, pol, dice, names, charms, hp, f, prng):
    """the reward after fight f - 1, before fight f; changes the kit in place; gives the hit
    points (a fishbone charm heals) and what was taken"""
    offers = rules.fights[f - 1].offers
    opts = options(rules, dice, charms, offers, f)
    if pol.name == "random":
        # the four offers first, as the screen has them, then what that offer asks
        kinds = sorted(set(o[0] for o in opts))
        k = kinds[prng.randrange(len(kinds))]
        sub = [o for o in opts if o[0] == k]
        opt = sub[prng.randrange(len(sub))]
    else:
        def worth(o):
            kit = apply(rules, dice, names, charms, offers, o)
            return -kit_worth(rules, kit[0], kit[2])

        scored = sorted(opts, key=worth)
        opt = scored[0]
        if pol.name == "strong":
            short = scored[:SHORTLIST]
            for o in opts:
                if o[0] in ("add", "swap", "set", "charm", "type") and o not in short:
                    short.append(o)
            seeds = [prng.getrandbits(30) for _ in range(ROLLOUTS)]
            best = None
            for o in short:
                kit = apply(rules, dice, names, charms, offers, o)
                gain = 4 if o[0] == "charm" and o[1] == "fishbone" else 0
                v = rollout(rules, kit[0], hp + gain, kit[2], f, seeds)
                if best is None or v > best:
                    best = v
                    opt = o
    text = take(dice, names, charms, apply(rules, dice, names, charms, offers, opt))
    if opt[0] == "charm" and opt[1] == "fishbone":
        hp += 4
    return hp, text


def nap(rules, pol, dice, names, charms, hp, f, prng):
    """PROPOSAL: after an elite, a nap: NAP_HEAL hit points back, or a face upgraded"""
    if "dogwitch" in rules.variant:
        ups = [o for o in dogwitch_options(rules, dice, [], f) if o[0] == "slot"]
    else:
        ups = upgrade_options(rules, dice, charms)
    heal = min(max_hp(rules, charms), hp + rules.nap_heal)
    if not ups:
        return heal, "nap: heal"

    def worth(o):
        kit = apply(rules, dice, names, charms, [], o)
        return kit_worth(rules, kit[0], kit[2])

    best_up = max(ups, key=worth)
    if pol.name == "random":
        take_heal = prng.random() < 0.5
    elif pol.name == "greedy":
        take_heal = heal - hp >= rules.nap_heal * 0.7
    else:
        seeds = [prng.getrandbits(30) for _ in range(ROLLOUTS)]
        v_heal = rollout(rules, dice, heal, charms, f, seeds)
        kit = apply(rules, dice, names, charms, [], best_up)
        v_up = rollout(rules, kit[0], hp, kit[2], f, seeds)
        take_heal = v_heal >= v_up
    if take_heal:
        return heal, "nap: heal to %d" % heal
    return hp, "nap: " + take(dice, names, charms, apply(rules, dice, names, charms, [], best_up))


def pick_door(rules, pol, dice, hp, charms, f, other, prng):
    """PROPOSAL: fight f or its other door; the player sees both before choosing"""
    if pol.name == "random":
        return f if prng.random() < 0.5 else other
    if pol.name == "greedy":
        def total(i):
            return sum(rules.kinds[k].hp for k in rules.fights[i].enemies)
        return f if total(f) <= total(other) else other
    seeds = [prng.getrandbits(30) for _ in range(ROLLOUTS)]
    a = rollout(rules, dice, hp, charms, f, seeds)
    b = rollout(rules, dice, hp, charms, other, seeds)
    return f if a >= b else other
