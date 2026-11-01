# the fight screens, one for each row of the game's FIGHTS (content/encounters.tsp, read with
# the sim's tools/sim/tsp.py, so the art follows the table: reorder the fights and run
# make.py game again). A screen carries the figures of everyone who can stand there: the
# fight's spots up to its count, the spots past it when someone there calls friends (its
# summons), and what each becomes when beaten (an enemy's then), with their kinds' role
# tables (figures.py). The backdrop is the zone's, drawn outside the screen's lanes.

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
sys.path.append(os.path.join(ROOT, "tools", "sim"))

import figures  # noqa: E402
import tsp  # noqa: E402

CONTENT = os.path.join(ROOT, "game", "content")
NOTHING = 255

# the figures an enemy can be drawn as, in their numbers' order (art/sprites FIG_*): every kind
# but the hero's
FIGURES = [k for k in figures.KINDS if k != "cat"]


def content():
    c = tsp.Content([CONTENT])
    return c.module("content/encounters"), c.module("content/enemies")


def figure_of(enemy):
    # the figure an enemy row names: art.FIG_NAME
    word = enemy["figure"]
    name = word.split(".")[-1]
    if not name.startswith("FIG_"):
        raise SystemExit("screens.py: an enemy's figure is %s, not an art.FIG_ one" % word)
    return name[4:].lower()


def fights():
    # [dict(n, row, zone, spots: [(enemy row, figure, col)], kinds: [figure...])] for every
    # FIGHTS row (n = row + 1, as lanes.py and the screens' names count them)
    enc, en = content()
    enemies = en.consts["ENEMIES"]
    out = []
    for row, F in enumerate(enc.consts["FIGHTS"]):
        spots = F["spots"]
        count = F["count"]
        # who calls friends: an enemy at a spot, or what it becomes
        callers = []
        for s in spots[:count]:
            e = s["enemy"]
            while e != NOTHING:
                if enemies[e]["calls"] != NOTHING:
                    callers.append(e)
                e = enemies[e]["then"]
        calls = bool(callers)
        used = spots if calls else spots[:count]
        cast = []
        for s in used:
            cast.append((s["enemy"], figure_of(enemies[s["enemy"]]), s["col"]))
        # who can come: the summons, and each one's then, in their spots
        kinds = []

        def add(e):
            while e != NOTHING:
                f = figure_of(enemies[e])
                if f not in kinds:
                    kinds.append(f)
                c = enemies[e]["calls"]
                if c != NOTHING and figure_of(enemies[c]) not in kinds:
                    add(c)
                e = enemies[e]["then"]

        for e, _, _ in cast[:count]:
            add(e)
        for c in callers:
            add(enemies[c]["calls"])
        # the spots past the count hold the callers' summons (and their thens)
        spot_kinds = []
        for i, (e, f, col) in enumerate(cast):
            if i < count:
                spot_kinds.append((col, then_chain(enemies, e)))
            else:
                called = []
                for c in callers:
                    called += then_chain(enemies, enemies[c]["calls"])
                spot_kinds.append((col, called))
        zone = F["zone"]
        out.append(dict(n=row + 1, row=row, zone=zone, elite=F["elite"], cast=cast, kinds=kinds,
                        spots=spot_kinds, backdrop=F["backdrop"]))
    return out


_ROOM = {}


def room_of(block):
    # how far a block's frames may reach from its idle frame's column, left and right, on every
    # screen it stands on: (the least spot column, 40 less the greatest); None when it is on
    # none. A sprite past column 39 would wrap to the left edge 64 rows down (the hi-res
    # memory map), so the frames must fit: game_sprites.block_sprites keeps them in
    if not _ROOM:
        for F in fights():
            for col, ks in F["spots"]:
                for k in ks:
                    b = figures.KINDS[k].block
                    left, right = _ROOM.get(b, (40, 40))
                    _ROOM[b] = (min(left, col), min(right, 40 - col))
        _ROOM["cat"] = (4, 36)
    return _ROOM.get(block)


def then_chain(enemies, e):
    # the figures enemy e shows as: its own, then what it becomes when beaten, and on
    out = []
    while e != NOTHING:
        f = figure_of(enemies[e])
        if f not in out:
            out.append(f)
        e = enemies[e]["then"]
    return out


def blocks_of(kinds):
    # a screen's blocks (the runs it unpacks), in order: each kind's block, once, then the
    # kinds that borrow one go after them in the role tables
    blocks = []
    for k in kinds:
        b = figures.KINDS[k].block
        if b not in blocks:
            blocks.append(b)
    own = [k for k in kinds if figures.KINDS[k].block == k]
    for b in blocks:
        if b not in own:
            own.append(b)
    borrowed = [k for k in kinds if figures.KINDS[k].block != k]
    return blocks, blocks + borrowed
