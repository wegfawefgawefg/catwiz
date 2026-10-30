# the day forest, fights 1-4: one picture drawn from a fight's palette (roles to colours,
# palettes.py) and a variant - clearing, path, brook, thicket - that changes only the ground
# and a few near shapes, so a variant is stored as patches over the clearing (export.py).
#
# the look (storybook, by daylight): a high-key backdrop of the light colours NTSC keeps
# fairly clean (light blue, aqua, yellow, white), the mid and dark tones only in small
# pieces, and the fighters (black outlines, the black cat) as the darkest, strongest shapes
# on it. The sun is up to the left: tree crowns are shaded volumes (shade.py) lit from
# there. The big cloud stands behind the cat's hat the way the moon does at night; the near
# trees stand behind the mushrooms; the sky stays open on the right for the bat.
#
# rows 0-123 are the stage; the tray and text below belong to hud.py and fonts.py.

import math
import random

from canvas import Canvas, ASPECT, bands, ridge
from shade import volume
import dhgr

STAGE = 124
HORIZON = 84          # where the meadow meets the wood

# the far wood: crowns rising out of the haze (x, height in rows, half width in pixels)
FAR = [(8, 18, 6), (20, 26, 5), (34, 20, 6), (46, 30, 5), (58, 24, 6), (112, 26, 5), (121, 36, 6),
       (131, 28, 5), (139, 40, 6)]

# the near wood: x, foot row, crown width (pixels), height (rows), seed, near (the near ramp)
TREES = [(52, 84, 12, 24, 11, False), (108, 84, 12, 26, 14, False), (24, 85, 8, 12, 7, False),
         (66, 86, 14, 34, 4, True), (86, 87, 16, 46, 3, True), (103, 87, 13, 32, 5, True),
         (4, 86, 10, 14, 6, True)]

# leaves hanging in at the top corners: cluster bumps (x, y, radius in rows)
CANOPY = [(-2, -2, 12), (8, -4, 10), (16, -6, 8), (3, 8, 7), (126, -4, 10), (136, 0, 12),
          (141, 12, 9), (118, -6, 7)]


def crown(cx, cy, w, h, seed, n=9):
    # the bumps of a tree crown: a big middle, a ring over the top, three in front low down
    rnd = random.Random(seed)
    out = [(cx, cy, h * 0.5, 0)]
    for i in range(n):
        a = math.pi * (0.95 + 1.1 * i / (n - 1)) + rnd.uniform(-0.15, 0.15)
        out.append((cx + w * 0.5 * math.cos(a), cy + h * 0.42 * math.sin(a),
                    h * rnd.uniform(0.26, 0.36), rnd.uniform(-1, 1)))
    for _ in range(3):
        out.append((cx + rnd.uniform(-0.4, 0.4) * w, cy + h * rnd.uniform(0.1, 0.3), h * 0.3,
                    2 + rnd.uniform(0, 1)))
    return out


def tree(c, x, base, w, h, seed, ramp, cuts, trunk):
    trunk_h = 4 + h // 8
    c.rect(int(x - 1), int(base - trunk_h - 8), int(x + 1), base, trunk)
    cy = base - trunk_h - h * 0.5
    volume(c, crown(x, cy, w, h, seed), ramp, cuts)


def cloud(c, P, puffs):
    # a storybook cumulus: round puffs on a flat foot, white; the shade colour comes in on
    # every other row over its lower third (a soft belly that NTSC keeps clean)
    m = Canvas()
    for cx, cy, r in puffs:
        m.ellipse(cx, cy, r / ASPECT * 1.15, r, 1)
    top = min(cy - r for cx, cy, r in puffs)
    foot = max(cy + r * 0.5 for cx, cy, r in puffs)
    for y in range(max(0, int(top)), int(foot) + 1):
        for x in range(dhgr.W):
            if m.px[y][x]:
                low = (y - top) / max(1, foot - top)
                c.px[y][x] = P["cloud_sh"] if (low > 0.72 and y % 2 == 1) or low > 0.93 else P["cloud"]


CLOUD = [(8, 30, 8), (18, 22, 11), (31, 21, 10), (41, 28, 8), (0, 36, 6), (50, 36, 6), (26, 32, 9),
         (12, 37, 6), (39, 37, 6)]
CLOUD2 = [(98, 13, 4), (104, 10, 5.5), (111, 13, 4)]


def sky(c, P):
    bands(c, 0, 66, P.get("sky_bands") or [P["sky"]] * 4 + [P["haze"]] * 2, blend=7)
    c.rect(0, 66, dhgr.W, HORIZON, P["haze"])
    cloud(c, P, CLOUD)
    cloud(c, P, CLOUD2)


def far_wood(c, P):
    for x in range(dhgr.W):
        top = int(ridge(x, 1.0, 74, 2))
        for y in range(top, HORIZON):
            c.px[y][x] = P["far"]
    for x, h, w in FAR:
        c.ellipse(x, 76 - h * 0.18, w, h * 0.3, P["far"])


def wood(c, P, trees):
    for x, base, w, h, seed, near in trees:
        ramp = P["leaf_near"] if near else P["leaf_far"]
        cuts = P["cuts_near"] if near else P["cuts_far"]
        tree(c, x, base, w, h, seed, ramp, cuts, P["trunk"])


def canopy(c, P, bumps=CANOPY):
    volume(c, [(x, y, r, 0) for x, y, r in bumps], P["leaf_near"], P["cuts_near"], height=0.0)


def meadow(c, P):
    c.rect(0, HORIZON - 2, dhgr.W, STAGE, P["grass"])
    # the wood's shade along the back, deeper under the near trees
    for x in range(dhgr.W):
        deep = 4 + (5 if 56 <= x <= 112 else 0) + int(2 * math.sin(x * 0.4))
        for y in range(HORIZON - 2, HORIZON + deep):
            if y < HORIZON + deep - 2 or (x + y) % 2 == 0 and y % 2 == 0:
                c.px[y][x] = P["grass_sh"]
    # sun where the fighters stand, its edge every other row (soft, and clean in NTSC)
    for cx, cy, rx, ry in ((80, 104, 46, 6.5), (34, 106, 21, 5)):
        c.ellipse(cx, cy, rx, ry, P["sun"], test=lambda x, y, cx=cx, cy=cy, rx=rx, ry=ry:
                  y % 2 == 0 or ((x + .5 - cx) / rx) ** 2 + ((y + .5 - cy) / ry) ** 2 < 0.6)
    bands(c, STAGE - 9, STAGE, [P["grass"], P["grass_sh"]], blend=5,
          test=lambda x, y: c.px[y][x] in (P["grass"], P["sun"]))


def tufts(c, P, seed=3, n=26):
    # little grass tufts, two strokes in a v, bigger towards the front
    rnd = random.Random(seed)
    for _ in range(n):
        y = rnd.randint(HORIZON + 10, STAGE - 4)
        x = rnd.randint(0, dhgr.W - 3)
        if c.px[y][x] not in (P["grass"], P["sun"]):
            continue
        tall = 2 if y > 108 else 1
        c.rect(x, y - tall, x + 1, y + 1, P["grass_sh"])
        c.rect(x + 2, y - tall, x + 3, y + 1, P["grass_sh"])
        c.rect(x + 1, y, x + 2, y + 1, P["grass_sh"])


FLOWERS = [(4, 96, 0), (14, 113, 1), (50, 94, 0), (58, 116, 2), (96, 94, 1), (120, 98, 0),
           (132, 112, 1), (70, 119, 0), (110, 117, 2), (26, 95, 2), (124, 104, 2), (40, 116, 0)]


def flowers(c, P, spots=FLOWERS):
    # a head of two pixels on a stalk
    for x, y, k in spots:
        col = P["flower"][k % len(P["flower"])]
        c.rect(x, y, x + 2, y + 1, col)
        c.rect(x, y + 1, x + 1, y + 2, P["grass_sh"])


# ---- the variants: what each adds over the clearing

def path(c, P):
    # a sandy path winding in from the back to the front under the fighters, its edges
    # grown over (every other row the grass's shade), a few pebbles
    for y in range(HORIZON + 2, STAGE):
        t = (y - HORIZON) / (STAGE - HORIZON)
        mid = 70 - 26 * math.sin(t * 2.6) + 14 * t
        half = 2 + 34 * t ** 1.3
        for x in range(int(mid - half) - 1, int(mid + half) + 2):
            if not 0 <= x < dhgr.W:
                continue
            d = abs(x + 0.5 - mid) - half
            if d < -1.0:
                c.px[y][x] = P["path"]
            elif d < 0.8 and y % 2 == 0:
                c.px[y][x] = P["grass_sh"]
    for x, y in ((48, 112), (92, 118), (70, 100), (60, 118), (80, 108)):
        if c.px[y][x] == P["path"]:
            c.rect(x, y, x + 2, y + 1, P["path_sh"])


def brook(c, P):
    # a brook across the meadow behind the fighters: the far bank in shade, the water lit
    # in rows, white glints, stepping stones
    def top(x):
        return int(92 + 2.5 * math.sin(x * 0.06 + 0.5) + 1.2 * math.sin(x * 0.19))
    for x in range(dhgr.W):
        y0 = top(x)
        c.px[y0 - 2][x] = P["grass_sh"]
        c.px[y0 - 1][x] = P["grass_sh"]
        for y in range(y0, y0 + 9):
            c.px[y][x] = P["water"]
        c.px[y0][x] = P["water_sh"]
        if x % 2 == 0:
            c.px[y0 + 1][x] = P["water_sh"]
        c.px[y0 + 9][x] = P["grass_sh"]
        k = (x * 7) % 17
        if k < 3:
            c.px[y0 + 3 + (x // 9) % 4][x] = P["glint"]
    for x, w in ((14, 4), (40, 3.5), (122, 4)):
        y0 = top(x)
        c.ellipse(x, y0 + 5, w, 2.4, P["stone"])
        c.hline(int(x - w + 1), int(x + w - 1), y0 + 3, P["glint"])


def thicket(c, P):
    # the wood closes in: bushes at the front corners and a second row of crowns behind
    wood(c, P, [(30, 85, 10, 20, 21, True), (124, 86, 12, 30, 22, True)])
    edge = [(4, 124, 16), (14, 128, 13), (24, 126, 9), (124, 126, 10), (134, 122, 15), (140, 130, 12)]
    volume(c, [(x, y, r, 0) for x, y, r in edge], P["leaf_near"], P["cuts_near"], height=0.2,
           test=lambda x, y: y < STAGE)
    canopy(c, P, CANOPY + [(28, -8, 9), (108, -8, 9), (40, -10, 8)])


VARIANTS = ["clearing", "path", "brook", "thicket"]


def picture(P, variant="clearing"):
    c = Canvas(dhgr.BLACK)
    sky(c, P)
    far_wood(c, P)
    wood(c, P, TREES)
    meadow(c, P)
    if variant == "path":
        path(c, P)
    tufts(c, P)
    flowers(c, P)
    if variant == "brook":
        brook(c, P)
    if variant == "thicket":
        thicket(c, P)
    c.rect(0, STAGE, dhgr.W, dhgr.H, dhgr.BLACK)
    return c
