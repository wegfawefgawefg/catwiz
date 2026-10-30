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
CLOUD = [(-3, 40, 8, 0), (7, 30, 10, 0), (18, 20, 13, 0), (30, 22, 11, 0), (41, 31, 8, 0),
         (50, 39, 6, 0), (6, 42, 8, 2), (21, 40, 9, 2), (35, 42, 8, 2), (46, 44, 6, 2)]

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


def sky(c, P):
    bands(c, 0, 66, P.get("sky_bands") or [P["sky"], P["sky"], P["haze"]], blend=10)
    c.rect(0, 66, dhgr.W, HORIZON, P["haze"])
    volume(c, CLOUD, (P["cloud_sh"], P["cloud"], P["cloud"]), (0.12, 0.9), height=0.5, stretch=1.1)
    for cx, cy, ry in ((98, 12, 4), (103, 10, 5), (109, 13, 4)):
        c.ellipse(cx, cy, ry / ASPECT * 1.2, ry, P["cloud"])
    c.rect(93, 13, 114, 15, P["cloud"])


def far_wood(c, P):
    for x in range(dhgr.W):
        top = int(ridge(x, 1.0, 66, 3))
        for y in range(top, HORIZON):
            c.px[y][x] = P["far"]
    for x, h, w in FAR:
        c.ellipse(x, 70 - h * 0.45, w, h * 0.55, P["far"])


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
    # sun where the fighters stand
    c.ellipse(80, 104, 46, 6.5, P["sun"])
    c.ellipse(34, 106, 21, 5, P["sun"])
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
    # a sandy path winding in from the back to the front, the fighters' ground
    for y in range(HORIZON + 4, STAGE):
        t = (y - HORIZON) / (STAGE - HORIZON)
        mid = 76 - 30 * math.sin(t * 2.4) + 10 * t
        half = 3 + 46 * t ** 1.4
        for x in range(int(mid - half), int(mid + half) + 1):
            if 0 <= x < dhgr.W:
                edge = abs(x + 0.5 - mid) > half - 1.2 - t * 1.5
                c.px[y][x] = P["path_sh"] if edge and y % 2 == 0 else P["path"]
    for x, y in ((40, 110), (96, 116), (66, 100), (110, 106), (22, 118)):
        if c.px[y][x] == P["path"]:
            c.rect(x, y, x + 2, y + 1, P["path_sh"])


def brook(c, P):
    # a brook across the meadow behind the fighters, a lit far bank, glints, stepping stones
    for x in range(dhgr.W):
        y0 = int(91 + 3 * math.sin(x * 0.07 + 0.5) + 1.5 * math.sin(x * 0.21))
        c.px[y0 - 1][x] = P["grass_sh"]
        for y in range(y0, y0 + 6):
            c.px[y][x] = P["water"]
        c.px[y0][x] = P["water_sh"]
        c.px[y0 + 6][x] = P["grass_sh"]
        if (x * 7) % 13 == 0:
            c.rect(x, y0 + 2 + (x % 3), x + 2, y0 + 3 + (x % 3), P["glint"])
    for x, w in ((18, 4), (44, 3), (118, 4)):
        y0 = int(91 + 3 * math.sin(x * 0.07 + 0.5) + 1.5 * math.sin(x * 0.21))
        c.ellipse(x, y0 + 3, w, 2.2, P["stone"])
        c.hline(x - w + 1, x + w - 1, y0 + 2, P["glint"])


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
    canopy(c, P)
    if variant == "thicket":
        thicket(c, P)
    c.rect(0, STAGE, dhgr.W, dhgr.H, dhgr.BLACK)
    return c
