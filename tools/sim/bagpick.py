"""The bag model's rewards (battle/reward.tsp; the bag proposal): one of the fight's two new
dice into the bag (not when it is full: BAG_MOST; the proposal swaps it for a die you pick),
an upgrade (the game: one face of one die; the bag proposal: +1 to a face type), or a die out
of the bag (not the last). Options are tuples; apply gives the kit with one taken."""

from rules import NOTHING
import bagfx


def face_worth(rules, row, bonus=None):
    """a rough worth of a face, in damage-equivalents, for picking rewards"""
    f = rules.faces[row]
    e = f.effect
    a = f.amount + (bonus.get(bagfx.family(f), 0) if bonus else 0)
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


def worth(rules, kit):
    n = len(kit.dice)
    bonus = bagfx.type_bonus(kit.charms)
    total = sum(sum(face_worth(rules, r, bonus) for r in d) / len(d) for d in kit.dice)
    return total * min(n, rules.hand) / n


def upgrade_options(rules, kit, f):
    """one face of one die (single, the game today), +1 to every face of a type, current and
    future dice (type: the bag proposal, the fight's type), or every face of a type in the
    bag one step up its upgrade row (typebag)"""
    dice = kit.dice
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
            fam = bagfx.family(rules.faces[r])
            if fam and fam not in rules.no_type_up and kit.charms.count("type:" + fam) < rules.type_most:
                present.add(fam)
    if f is not None and rules.fights[f - 1].upgrade and "anytype" not in rules.variant:
        present &= {rules.fights[f - 1].upgrade}
    what = "type" if rules.upgrade == "type" else "typebag"
    return [(what, fam, None) for fam in sorted(present)]


def options(rules, kit, offers, f):
    dice = kit.dice
    out = []
    for k in range(len(offers)):
        if len(dice) < rules.bag_most:
            out.append(("add", k, None))
        elif rules.swap:
            seen = set()
            for d in range(len(dice)):
                if tuple(dice[d]) not in seen:
                    seen.add(tuple(dice[d]))
                    out.append(("swap", k, d))
    out += upgrade_options(rules, kit, f)
    if len(dice) > 1:
        seen = set()
        for d in range(len(dice)):
            if tuple(dice[d]) not in seen:
                seen.add(tuple(dice[d]))
                out.append(("remove", d, None))
    return out


def apply(rules, kit, offers, opt):
    """a copy of the kit with option opt taken, and what it was in words"""
    kit = kit.copy()
    what, a, b = opt
    if what == "type":
        kit.charms.append("type:" + a)
        return kit, "type %s +1" % a.upper()
    if what == "typebag":
        kit.dice = [[rules.faces[r].upgrade if bagfx.family(rules.faces[r]) == a and
                     rules.faces[r].upgrade != NOTHING else r for r in d] for d in kit.dice]
        return kit, "every %s face one step up" % a.upper()
    if what == "add":
        kit.dice.append(list(offers[a]))
        kit.names.append(rules.die_name(offers[a]))
        return kit, "new " + kit.names[-1]
    if what == "swap":
        text = "new %s for %s" % (rules.die_name(offers[a]), kit.names[b])
        kit.dice[b] = list(offers[a])
        kit.names[b] = rules.die_name(offers[a])
        return kit, text
    if what == "up":
        old = rules.faces[kit.dice[a][b]]
        kit.dice[a][b] = old.upgrade
        return kit, "upgrade %s: %s to %s" % (kit.names[a], old.name, rules.faces[old.upgrade].name)
    text = "remove " + kit.names[a]
    del kit.dice[a]
    del kit.names[a]
    return kit, text
