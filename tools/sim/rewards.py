"""What a run carries between fights (Kit) and the choices between fights: the reward after a
won fight, the charm after the elites and the day's end, the nap, the elite doors.

The item model (the proposal): after a fight, pick one of its three cards. An item card for
a slot puts that item in (the old one goes), or, when you hold it, is a level on its slot; an
upgrade card (UP_WAND...) is a level on that slot. Levels belong to the slot (the item there
gets its step more a level, whichever item it is), ITEM_MOST at most; the "itembound" variant
keeps them with the item instead, and "twodoor" offers new item (one of the item cards) or a
level on any slot. A fight with charms then offers one of three. The nap: heal or a level.
The bag model's rewards are bagpick.py's.

random picks any offer; greedy the one that most raises the kit's worth by a fixed table
(item_worth, bagpick.face_worth); strong tries each offer (the bag model: the best few) in
rollouts of the next fight (the greedy player, the same dice for every option).
"""

import random

import bagpick
import content
import policy as po
from rules import HERO

ROLLOUTS = 6
SHORTLIST = 5

CHARM_WORTH = {"pocket": 3.0, "nightlight": 2.5, "fishbone": 3.0, "bell": 1.5, "pillow": 3.5,
               "toe": 3.0, "still": 2.0, "trio": 2.5, "mittens": 2.0, "mother": 2.5,
               "tail": 2.5, "grumpy": 2.0, "duck": 1.5, "badmilk": 2.5}


class Kit:
    """the run's dice (the bag model) or items (the item model: a row a slot), the slots' or
    items' levels, charms (kinds by name; the bag proposal's type upgrades as "type:..."),
    the names of the bag's dice, and nine lives left"""

    def __init__(self, rules):
        self.rules = rules
        self.items = list(rules.start_items) if rules.model == "items" else None
        self.bag = [list(d) for d in rules.start_dice] if self.items is None else None
        self.names = [rules.die_name(d) for d in rules.start_dice]
        self.levels = {}
        self.charms = []
        self.lives = 0

    @property
    def dice(self):
        if self.items is not None:
            # toefix: the sixth toe's sixth die (without it the bag has five dice and the
            # sixth tray spot stays empty: the toe was only a re-roll less)
            extra = self.charms.count("toe") if "toefix" in self.rules.variant else 0
            return [self.items] * (self.rules.hand + extra)
        return self.bag

    @dice.setter
    def dice(self, value):
        self.bag = value

    def copy(self):
        k = Kit.__new__(Kit)
        k.rules = self.rules
        k.items = list(self.items) if self.items is not None else None
        k.bag = [list(d) for d in self.bag] if self.bag is not None else None
        k.names = list(self.names)
        k.levels = dict(self.levels)
        k.charms = list(self.charms)
        k.lives = self.lives
        return k

    def level(self, slot):
        if self.rules.levels == "item":
            return self.levels.get(self.items[slot], 0)
        return self.levels.get(slot, 0)

    def battle_levels(self):
        """face row to level, for the battle"""
        if self.items is None:
            return {}
        return {self.items[s]: self.level(s) for s in range(6)}

    def max_hp(self):
        return self.rules.hero_hp + 5 * self.charms.count("fishbone")


def item_worth(rules, row, level):
    """a rough worth of an item on its face, in damage-equivalents a roll"""
    f = rules.faces[row]
    n = f.amount + level * f.step
    e = f.effect
    table = {
        "hit": n, "yarn": 1.3 * n + 0.3, "feather": 1.7 * n, "spray": 1.4 * n,
        "pierce": 1.2 * n, "hit_all": 2.0 * n, "shield": 0.7 * n, "spiky": 0.8 * n + 0.6,
        "fort": 0.7 * n + 2.5, "blanket": 0.7 * n + 0.8, "mana": 1.1 * n,
        "shootstar": 1.1 * n + 1.0, "sundrop": 1.1 * n + 0.4, "moonbowl": 1.5 * n,
        "luckystar": 1.1 + n, "zoomies": 5.0 * n, "kittens": 3.0 * n, "laserall": 2.0 * n + 2,
        "knock": n + 2, "scream": 2.5 * n, "sits": 3.0 * n, "purr": 2.0 * n, "heal": 0.7 * n,
        "goldfish": 2.0 * n, "fleas": 2.0 * n, "wet": 1.5 + n, "hiss": 2.0 + n, "bath": 1.0 + n,
        "brand": 2.5 * n, "blink": 2.0, "plus": 1.2 * n, "double": 1.2 * n, "catnip2": n,
        "copy": 2.0 + n, "knead": 1.5 + n, "reroll": 1.2 * n, "sardine": 1.0 + n,
        "string": 1.8 * n, "shoot": 1.1 + n, "moon": 1.1 + 0.7 * n, "wish": 1.1 * n + 1.5,
        "litter": 1.1 * n + 1.0, "tangled": 1.5 * n, "pile": 0.7 * n + 1.0, "kittens": 3.0 * n, "cannon": 1.5 * n,
    }
    w = table.get(e, 0.0)
    if f.combo and f.combo != "none":
        w += 0.8
    if f.cost:
        w = max(0.5, w - 1.0 * f.cost)
    return w


def worth(rules, kit):
    if kit.items is None:
        return bagpick.worth(rules, kit) + sum(CHARM_WORTH.get(c, 0) for c in kit.charms)
    w = sum(item_worth(rules, kit.items[s], kit.level(s)) for s in range(6))
    return w + sum(CHARM_WORTH.get(c, 0) for c in kit.charms)


# ---- the item model's offers

def item_options(rules, kit, cards):
    out = []
    if "twodoor" in rules.variant:
        out = [("item", c) for c in cards if c < 128 and c not in kit.items]
        return out + [("level", s) for s in range(6) if kit.level(s) < rules.item_most]
    for c in cards:
        if c >= 128:
            slot = c - 128
        else:
            slot = content.slot_index(rules.faces[c].slot)
            if kit.items[slot] != c:
                out.append(("item", c))
                continue
        if kit.level(slot) < rules.item_most:
            out.append(("level", slot))
    return out


def item_apply(rules, kit, opt):
    kit = kit.copy()
    what, a = opt[0], opt[1]
    if what == "item":
        slot = content.slot_index(rules.faces[a].slot)
        old = rules.faces[kit.items[slot]].name
        kit.items[slot] = a
        return kit, "%s (for %s)" % (rules.faces[a].name, old)
    if what == "charm":
        kind = rules.charm_table[a]["kind"]
        kit.charms.append(kind)
        if kind == "lives":
            kit.lives += 1
        return kit, "charm " + rules.charm_table[a]["name"]
    key = kit.items[a] if rules.levels == "item" else a
    kit.levels[key] = kit.levels.get(key, 0) + 1
    return kit, "+1 %s (%s)" % (content.SLOTS[a].upper(), rules.faces[kit.items[a]].name)


# ---- choosing

def rollout(rules, kit, hp, fight, seeds):
    """the greedy player's mean result in fight index fight with this kit: hit points left,
    or a big loss"""
    import run  # here, not at the top: run imports this module

    total = 0.0
    for s in seeds:
        pol = po.Greedy(rules, random.Random(s))
        b, _ = run.play_fight(rules, pol, kit, hp, fight, run.GameRng(s))
        total += b.hp[HERO] if b.result == "won" else -40.0 + 0.5 * (b.hp[HERO] - sum(b.hp[1:]))
    return total / len(seeds)


def choose(rules, pol, kit, hp, f, opts, applied, prng):
    """the option a policy takes; applied(o) gives (kit, words)"""
    if len(opts) == 1:
        return opts[0]
    if pol.name == "random":
        kinds = sorted(set(o[0] for o in opts))
        k = kinds[prng.randrange(len(kinds))]
        sub = [o for o in opts if o[0] == k]
        return sub[prng.randrange(len(sub))]
    scored = sorted(opts, key=lambda o: -worth(rules, applied(o)[0]))
    if pol.name != "strong" or f >= rules.fight_count:
        return scored[0]
    short = scored if kit.items is not None else scored[:SHORTLIST]
    if kit.items is None:
        short += [o for o in opts if o[0] in ("add", "swap", "type") and o not in short]
    seeds = [prng.getrandbits(30) for _ in range(ROLLOUTS)]
    best, pick = None, scored[0]
    for o in short:
        k = applied(o)[0]
        gain = 5 if o[0] == "charm" and rules.charm_table[o[1]]["kind"] == "fishbone" else 0
        v = rollout(rules, k, hp + gain, f, seeds)
        if best is None or v > best:
            best, pick = v, o
    return pick


def draw(rng, pool, ok, n=3):
    """n different entries of a pool of (what, weight, from) drawn at random by weight among
    those ok says may come; rng is the game's (GameRng): the C sim draws the same"""
    left = [(w, wt) for w, wt, _ in pool if ok(w)]
    out = []
    for _ in range(n):
        total = sum(wt for _, wt in left)
        if total == 0:
            break
        r = rng.r.randrange(total)
        for i, (w, wt) in enumerate(left):
            if r < wt:
                out.append(w)
                left.pop(i)
                break
            r -= wt
    return out


def offered(rules, kit, f, rng):
    """the three cards after f fights won: from the pool, by weight, ones that give an option"""
    pool = [o for o in rules.offers if o[2] <= f]
    return draw(rng, pool, lambda c: bool(item_options(rules, kit, [c])))


def pick(rules, pol, kit, hp, f, fought, prng, rng=None):
    """the reward after fight index fought (its door), before fight index f. Gives the new kit,
    the hit points and what was taken (a list of words). rng: the game's, for the random offers"""
    taken = []
    fight = rules.fights[fought]
    if kit.items is not None and rules.offers:
        fight = content.Fight.__new__(content.Fight)
        fight.cards = offered(rules, kit, f, rng)
        fight.nap = rules.fights[fought].nap
        fight.charms = []
        if rules.fights[fought].charm:
            have = set(kit.charms)
            pool = [o for o in rules.charm_offers if o[2] <= f]
            fight.charms = draw(rng, pool, lambda c: rules.charm_table[c]["kind"] not in have)
    if kit.items is None:
        opts = bagpick.options(rules, kit, fight.offers, f)
        def applied(o):
            return bagpick.apply(rules, kit, fight.offers, o)
    else:
        opts = item_options(rules, kit, fight.cards)
        def applied(o):
            return item_apply(rules, kit, o)
    if opts:
        o = choose(rules, pol, kit, hp, f, opts, applied, prng)
        kit, words = applied(o)
        taken.append(words)
    if fight.charms:
        opts = [("charm", c) for c in fight.charms]
        k0 = kit
        o = choose(rules, pol, kit, hp, f, opts, lambda o: item_apply(rules, k0, o), prng)
        kit, words = item_apply(rules, kit, o)
        if rules.charm_table[o[1]]["kind"] == "fishbone":
            hp += 5
        taken.append(words)
    if fight.nap:
        hp, kit, words = nap(rules, pol, kit, hp, f, prng)
        taken.append(words)
    return kit, hp, taken


def nap(rules, pol, kit, hp, f, prng):
    """after an elite, a nap: NAP_HEAL hit points back, or a level (the item model: a slot;
    the bag model: the upgrade the reward would give)"""
    heal = min(kit.max_hp(), hp + rules.nap_heal)
    if rules.rest_heal is not None:  # a share of what she is missing, rounded up
        heal = hp + ((kit.max_hp() - hp) * rules.rest_heal + 99) // 100
    if kit.items is not None:
        ups = [("level", s) for s in range(6) if kit.level(s) < rules.item_most]
        def applied(o):
            return item_apply(rules, kit, o)
    else:
        ups = bagpick.upgrade_options(rules, kit, f)
        def applied(o):
            return bagpick.apply(rules, kit, [], o)
    if not ups:
        return heal, kit, "rest: heal"
    best_up = max(ups, key=lambda o: worth(rules, applied(o)[0]))
    if pol.name == "random":
        take_heal = prng.random() < 0.5
    elif pol.name == "greedy":
        take_heal = heal - hp >= (rules.nap_heal * 0.7 if rules.rest_heal is None else 5)
    else:
        seeds = [prng.getrandbits(30) for _ in range(ROLLOUTS)]
        take_heal = rollout(rules, kit, heal, f, seeds) >= rollout(rules, applied(best_up)[0], hp, f, seeds)
    if take_heal:
        return heal, kit, "rest: heal"
    k, words = applied(best_up)
    return hp, k, "rest: " + words


def pick_door(rules, pol, kit, hp, f, other, prng):
    """fight f or its other door; the player sees both before choosing"""
    if pol.name == "random":
        return f if prng.random() < 0.5 else other
    if pol.name == "greedy":
        def total(i):
            return sum(rules.kinds[k].hp for k in rules.fights[i].enemies)
        return f if total(f) <= total(other) else other
    seeds = [prng.getrandbits(30) for _ in range(ROLLOUTS)]
    a = rollout(rules, kit, hp, f, seeds)
    b = rollout(rules, kit, hp, other, seeds)
    return f if a >= b else other
