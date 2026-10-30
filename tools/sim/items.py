"""The item-slot model (tools/sim/proposal): Catwiz rolls five identical dice whose six faces
are her six item slots; the item in a slot decides what its face does, and its slot's level
adds the item's step to its number. This file plays a face (land): its number, the boosts,
its effect, and the combo when it is the third fluff (or twig wand) this turn; the kittens;
the hairball that clogs a slot; and the charms (which the bag variants use too). The game has
none of this yet; docs/balance.md lists what the engine would need.

Boosts on a played face, in this order: a pending times (a wand, fluff or book only: its number
times m, and it counts m towards its slot's three), then a pending plus (the next two dice,
any slot: each hit, each stack, each star), catnip's +1,
knead (the next fluff x2, the next wand +n), bad milk (wands +1), a wishing star (the next wand
x2), then a spook takes away.
"""


def ru():
    import rules  # here: rules imports this module

    return rules


KITTENS_MOST = 5
COMBO_AT = 3
PLUS_DICE = 2  # plus one: how many dice it boosts
MULT_SLOTS = ("wand", "fluff", "book")  # what a pending times takes


def amount(b, kind, default):
    """a charm's amount from the content's charm table (the bag variants' charms: default),
    times how many of it the run holds"""
    for c in getattr(b.R, "charm_table", ()):
        if c["kind"] == kind:
            return c["amount"] * b.charms.count(kind)
    return default * b.charms.count(kind)


def fight_start(b):
    r = ru()
    st = b.st[r.HERO]
    c = b.charms
    if not c:
        return
    b.maxhp[r.HERO] += amount(b, "fishbone", 5)
    st[r.MANA] = 2 * c.count("nightlight")
    st[r.WARD] = c.count("bell")
    st[r.KITTENS] = amount(b, "mother", 1)
    if "badmilk" in c:
        st[r.POISON] = 2
        st[r.FLEA_TURNS] = b.R.fx["FLEA_TURNS"]


def round_start(b):
    """the hero's turn begins (after statuses.turn_start took her shield): the charms, a kept
    shield, the combo counts start again"""
    r = ru()
    st = b.st[r.HERO]
    b.combo = {}
    b.rerolled = False
    if st[r.KEEP]:
        st[r.SHIELD] = b.old_shield
        st[r.KEEP] = 0
    c = b.charms
    if not c:
        return
    if "tail" in c:
        st[r.SHIELD] = max(st[r.SHIELD], b.old_shield // 2)
    b.rerolls += amount(b, "pocket", 1) - amount(b, "toe", 1)
    if "pillow" in c:
        st[r.SHIELD] += 2


def land(b, row, target, again=False):
    """a face of the item model lands: its number, the boosts, its effect, its combo"""
    r = ru()
    face = b.R.faces[row]
    st = b.st[r.HERO]
    n = face.amount + b.levels.get(row, 0) * face.step
    if face.slot == "trick":
        trick(b, face, n)
        return
    counts = 1
    if st[r.MULT] and face.slot in MULT_SLOTS:
        n *= st[r.MULT]
        counts = st[r.MULT]
        st[r.MULT] = 0
    if st[r.PLUS_LEFT]:
        n += st[r.PLUS]
        st[r.PLUS_LEFT] -= 1
        if not st[r.PLUS_LEFT]:
            st[r.PLUS] = 0
    if st[r.NIP]:
        n += 1
        st[r.NIP] -= 1
    if face.slot == "fluff" and st[r.KNEAD_FLUFF]:
        n *= 2
        st[r.KNEAD_FLUFF] = 0
    if face.slot == "wand":
        n += st[r.KNEAD_WAND] + amount(b, "badmilk", 1)
        st[r.KNEAD_WAND] = 0
        if st[r.WISH]:
            n *= 2  # a wishing star: the next wand times 2
            st[r.WISH] = 0
    if st[r.SPOOK]:
        n = max(0, n - st[r.SPOOK])
    before = b.combo.get(face.slot, 0)
    b.combo[face.slot] = before + counts
    three = before < COMBO_AT <= before + counts
    if not again:
        b.last_face = row
        b.last_on = target
    if face.slot == "book":
        # with too little mana a book gives 1 mana instead (she studies it); a copycat's
        # book is paid again
        if st[r.MANA] < face.cost:
            b.apply("mana", r.HERO, r.HERO, 1)
            return
        st[r.MANA] -= face.cost
    effect(b, face.effect, target, n)
    if three and face.combo and face.combo != "none":
        combo(b, face.combo, face.combo_n, target, n)
        if "trio" in b.charms:
            for i in range(1, r.ACTORS):
                if b.alive[i]:
                    b.strike_plain(i, amount(b, "trio", 1))


def trick(b, face, n):
    r = ru()
    st = b.st[r.HERO]
    e = face.effect
    if e == "plus":
        # +1 is wide: the next two dice get it, each hit and stack of them
        st[r.PLUS] = max(st[r.PLUS], n)
        st[r.PLUS_LEFT] = PLUS_DICE
    elif e == "double":
        # x2 is tall: the next wand, fluff or book (a star or curse leaves it waiting), and it
        # counts as two towards a three; played after a +1 it doubles that too
        st[r.PLUS] *= n
        st[r.MULT] = max(st[r.MULT], 1) * n
    elif e == "copy":
        if b.last_face != r.NOTHING:
            if n:
                st[r.PLUS] += n
                st[r.PLUS_LEFT] = max(st[r.PLUS_LEFT], 1)
            on = b.last_on if b.alive[b.last_on] else b.target
            land(b, b.last_face, on, again=True)
    elif e == "catnip2":
        b.add(r.HERO, r.NIP, n)
        st[r.NIPPED] = 1
    elif e == "knead":
        st[r.KNEAD_FLUFF] = 1
        b.add(r.HERO, r.KNEAD_WAND, n)
    else:
        raise ValueError("trick the sim does not know: " + e)


def effect(b, e, t, n):
    r = ru()
    H = r.HERO
    st = b.st
    if e == "yarn":
        b.strike(H, t, n)
        if b.alive[t]:
            b.curse("tangled", t, 1)
    elif e == "spray":
        b.strike(H, t, n)
        if b.alive[t]:
            b.curse("wet", t, 1)
    elif e == "feather":
        b.strike(H, t, n)
        pounce(b, t, 1)
    elif e == "pierce":
        b.strike(H, t, n, pierce=True)
    elif e == "string":
        b.strike(H, t, n)
        t2 = b.next_standing(t)
        if t2 != r.NOTHING and t2 != H:
            b.strike(H, t2, n)
    elif e == "shoot":
        b.apply("mana", H, H, 1)
        b.strike(H, t, n)
    elif e == "moon":
        b.apply("mana", H, H, 1)
        b.add(H, r.SHIELD, n)
    elif e == "wish":
        b.apply("mana", H, H, n)
        st[H][r.WISH] = 1
    elif e == "litter":
        b.apply("mana", H, H, n + st[H][r.KITTENS])
    elif e == "kittens":
        st[H][r.KITTENS] = min(KITTENS_MOST, st[H][r.KITTENS] + n)
    elif e == "laserall":
        for i in range(1, r.ACTORS):
            if b.alive[i]:
                b.strike(H, i, n)
                if b.alive[i]:
                    st[i][r.LASER] = 1
    elif e == "knock":
        strip(b, t)
        b.strike(H, t, n)
    elif e == "cannon":
        b.strike(H, t, n * st[H][r.KITTENS])
    elif e == "pile":
        b.add(H, r.SHIELD, n + 2 * st[H][r.KITTENS])
    elif e in ("wet", "tangled", "brand"):
        b.curse(e, t, n)
    else:
        b.apply(e, H, t, n)


def strip(b, t):
    r = ru()
    for s in (r.SHIELD, r.CHEER, r.STRENGTH, r.REFLECT):
        b.st[t][s] = 0


def combo(b, c, k, t, n):
    """what the third fluff (or twig wand) in a turn adds; k: the item's combo_n, n: the
    face's number"""
    r = ru()
    H = r.HERO
    st = b.st
    live = [i for i in range(1, r.ACTORS) if b.alive[i]]
    if c == "sweep":
        for i in live:
            if i != t:
                b.strike(H, i, n)
    elif c == "keep":
        st[H][r.KEEP] = 1
    elif c == "thorns":
        st[H][r.THORNS] = max(st[H][r.THORNS], k)
    elif c == "box":
        st[H][r.BOX] = 1
        st[H][r.KITTENS] = min(KITTENS_MOST, st[H][r.KITTENS] + k)
    elif c == "heal":
        b.heal(H, k)
    elif c == "static":
        for i in live:
            b.strike(H, i, k * 2 if st[i][r.WET] else k)
    elif c == "ward":
        b.add(H, r.WARD, k)
    else:
        raise ValueError("combo the sim does not know: " + c)


def pounce(b, t, times):
    """every kitten pounces on t, times times: 1 each, more with mittens and marks"""
    r = ru()
    hit = 1 + amount(b, "mittens", 1)
    for _ in range(b.st[r.HERO][r.KITTENS] * times):
        if not b.alive[t]:
            return
        b.strike_plain(t, hit + b.st[t][r.BRAND])


def turn_end(b):
    """before the hero's statuses tick: the kittens pounce (on a marked enemy first, else the
    leftmost), twice in a turn with catnip; still water's mana"""
    r = ru()
    st = b.st[r.HERO]
    if "still" in b.charms and not b.rerolled:
        b.apply("mana", r.HERO, r.HERO, amount(b, "still", 2))
    k = st[r.KITTENS]
    times = 2 if st[r.NIPPED] else 1
    st[r.NIPPED] = 0
    st[r.NIP] = 0
    st[r.KNEAD_FLUFF] = 0
    st[r.KNEAD_WAND] = 0
    if not k:
        return
    for _ in range(times):
        live = [i for i in range(1, r.ACTORS) if b.alive[i]]
        if not live:
            break
        marked = [i for i in live if b.st[i][r.BRAND]]
        pounce(b, (marked or live)[0], 1)
    if not any(b.alive[1:]):
        b.result = "won"


def enemies_done(b, unhurt):
    """after the enemies' moves"""


def hero_hurt(b):
    """she lost hit points: a kitten runs off; grumpy face gives a mana"""
    r = ru()
    st = b.st[r.HERO]
    if st[r.KITTENS]:
        st[r.KITTENS] -= 1
    if "grumpy" in b.charms:
        st[r.MANA] = min(b.R.most_mana, st[r.MANA] + amount(b, "grumpy", 1))


def ward_blocked(b):
    """a ward pip took a curse (hers or an enemy's): rubber duck's shield"""
    r = ru()
    if "duck" in b.charms:
        b.add(r.HERO, r.SHIELD, amount(b, "duck", 3))


def enemy_beaten(b, who):
    """nothing yet"""


def clog(b, slot):
    """an enemy's hairball on face slot (0 wand, 1 fluff, ...) of every die, for the fight"""
    if b.R.junk_row is None or slot in b.clogged:
        return
    faces = list(b.dice[0])
    b.clogged[slot] = faces[slot]
    faces[slot] = b.R.junk_row
    b.dice = [faces] * len(b.dice)


def cough(b):
    """a re-roll coughs up the hairballs the re-rolled dice show: their slots come back"""
    b.rerolled = True
    if not b.clogged:
        return
    for s in range(b.hand_n):
        if not b.played[s] and b.hand[s] == b.R.junk_row:
            slot = b.face_of[s]
            if slot in b.clogged:
                faces = list(b.dice[0])
                faces[slot] = b.clogged.pop(slot)
                b.dice = [faces] * len(b.dice)
