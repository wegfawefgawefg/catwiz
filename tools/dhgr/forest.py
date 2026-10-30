# the day forest, fights 1-4: one picture drawn from a fight's palette (roles to colours,
# palettes.py) and a variant - clearing, path, brook, thicket - with one big shape of its
# own each. Only the ground and the edges change, so a variant is stored as patches over
# the clearing (export.py).
#
# the value plan, the night's turned over: the night is a black page with the fighters as
# its lights; the day is a white page (white is as clean in NTSC as black) with the fighters
# as its darks. Three tiers only: the paper (white, a light blue band at the top, the far
# wood light blue), the ground one flat light green, and the darkest values and strongest
# colours kept for the fighters. The sun is the day's moon: a disc behind the cat's hat.
# The trees stand at the edges as wings; the middle stays open behind the enemies. No
# dithered fills: every area is one flat colour.
#
# rows 0-117 are the stage, 118-123 a black gutter (the hit point badges sit in it), the
# tray and text below belong to hud.py and fonts.py.

import math
import random

from canvas import Canvas, ASPECT
from shade import volume
import dhgr

STAGE = 118           # the first row of the black gutter
TRAY = 124
HORIZON = 84          # where the meadow meets the far wood
SUN = (34, 31, 19)    # middle and radius (rows) of the sun behind the hat

# the far wood: low round crowns along the horizon (x, height in rows, half width in pixels)
FAR = [(4, 10, 6), (16, 14, 6), (30, 9, 5), (42, 13, 6), (56, 8, 5), (68, 12, 6), (82, 9, 5),
       (96, 13, 6), (110, 10, 6), (124, 14, 6), (137, 11, 6)]

# the wings: a tree at each edge, cut by the frame (x, foot, crown width, height, seed)
WINGS = [(-1, HORIZON + 2, 16, 70, 4), (139, HORIZON + 2, 16, 52, 3)]


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


def tree(c, P, x, foot, w, h, seed, trunk=None):
    # a trunk up into a crown lit from the upper left; the crown's foot sits high enough
    # that the trunk shows under it
    trunk = trunk or P["trunk"]
    c.rect(int(x - 2), int(foot - h * 0.55), int(x + 2), foot, trunk)
    cy = foot - h * 0.72
    volume(c, crown(x, cy, w, h * 0.62, seed), P["leaf"], P["cuts"])


def sky(c, P):
    c.rect(0, 0, dhgr.W, HORIZON, P["paper"])
    # the band at the top, its foot scalloped like a cloud bank
    for x in range(dhgr.W):
        foot = 7 + int(3 * abs(math.sin(x * 0.16 + 0.4)) + 1.5 * math.sin(x * 0.05))
        c.rect(x, 0, x + 1, foot, P["band"])
    # the sun: a flat disc, its rim a ring of the rim colour
    sx, sy, r = SUN
    c.ellipse(sx, sy, r / ASPECT + 1, r + 2, P["sun_rim"])
    c.ellipse(sx, sy, r / ASPECT, r, P["sun"])
    # one small cloud far off on the right, a flat light blue shape
    for cx, cy, rr in ((100, 22, 4), (105, 19, 5.5), (111, 22, 4)):
        c.ellipse(cx, cy, rr / ASPECT * 1.2, rr, P["cloud"])
    c.rect(96, 22, 115, 26, P["cloud"])


def far_wood(c, P):
    for x, h, w in FAR:
        c.ellipse(x, HORIZON - 2, w, h, P["far"])
    c.rect(0, HORIZON - 4, dhgr.W, HORIZON, P["far"])


def meadow(c, P):
    c.rect(0, HORIZON, dhgr.W, STAGE, P["grass"])
    c.hline(0, dhgr.W, HORIZON, P["horizon"])
    c.hline(0, dhgr.W, HORIZON + 1, P["horizon"])


def tufts(c, P, seed=3, n=14):
    # a few grass tufts away from where the fighters stand, bigger towards the front
    rnd = random.Random(seed)
    for _ in range(n):
        y = rnd.randint(HORIZON + 6, STAGE - 3)
        x = rnd.randint(0, dhgr.W - 3)
        if any(a <= x <= b for a, b in ((14, 48), (58, 118))) and 96 <= y <= 112:
            continue
        if c.px[y][x] != P["grass"]:
            continue
        tall = 2 if y > 104 else 1
        c.rect(x, y - tall, x + 1, y + 1, P["tuft"])
        c.rect(x + 2, y - tall, x + 3, y + 1, P["tuft"])
        c.rect(x + 1, y, x + 2, y + 1, P["tuft"])


FLOWERS = [(4, 96, 0), (8, 114, 1), (52, 90, 0), (124, 92, 1), (132, 112, 0), (120, 110, 1),
           (26, 90, 1), (54, 114, 0), (90, 90, 1)]


def flowers(c, P, spots=FLOWERS):
    for x, y, k in spots:
        if c.px[y][x] != P["grass"]:
            continue
        c.rect(x, y, x + 2, y + 1, P["flower"][k % len(P["flower"])])
        c.rect(x, y + 1, x + 1, y + 2, P["tuft"])


# ---- the variants: each one big shape over the clearing

def path(c, P):
    # a white sandy path from a point on the horizon, widening to the front under the fighters
    for y in range(HORIZON + 2, STAGE):
        t = (y - HORIZON) / (STAGE - HORIZON)
        mid = 72 - 22 * math.sin(t * 2.2) + 8 * t
        half = 1 + 42 * t ** 1.5
        c.rect(int(mid - half), y, int(mid + half) + 1, y + 1, P["path"])
    for x, y in ((50, 112), (94, 114), (70, 98), (62, 116), (84, 106), (76, 92)):
        if c.px[y][x] == P["path"]:
            c.rect(x, y, x + 2, y + 1, P["pebble"])


def brook(c, P):
    # a brook along the horizon, behind the fighters' feet: one flat band of water, glints
    # as short dashes, stepping stones
    def top(x):
        return int(HORIZON + 4 + 1.5 * math.sin(x * 0.07 + 0.5))
    for x in range(dhgr.W):
        y0 = top(x)
        c.px[y0 - 1][x] = P["bank"]
        for y in range(y0, y0 + 7):
            c.px[y][x] = P["water"]
        c.px[y0 + 7][x] = P["bank"]
    for x in range(2, dhgr.W - 4, 11):
        y0 = top(x) + 2 + (x // 11) % 3
        c.rect(x, y0, x + 3, y0 + 1, P["glint"])
    for x, w in ((18, 4), (44, 3.5), (126, 4)):
        c.ellipse(x, top(x) + 4, w, 2.2, P["stone"])


def thicket(c, P):
    # the wood closes in: black trunks and bushes framing the stage, the afternoon behind
    for x, w in ((6, 3), (19, 2), (124, 2), (134, 3)):
        c.rect(x - w, 0, x + w, STAGE, P["frame"])
    for x, y, r in ((0, 116, 12), (12, 118, 9), (138, 114, 13), (128, 118, 9), (2, 6, 14), (16, 0, 11),
                    (136, 4, 14), (122, 0, 10)):
        c.ellipse(x, y, r / ASPECT * 1.3, r, P["frame"])


VARIANTS = ["clearing", "path", "brook", "thicket"]


def picture(P, variant="clearing"):
    c = Canvas(dhgr.BLACK)
    sky(c, P)
    far_wood(c, P)
    meadow(c, P)
    if variant == "brook":
        brook(c, P)
    if variant == "path":
        path(c, P)
    for x, foot, w, h, seed in WINGS:
        tree(c, P, x, foot, w, h, seed)
    tufts(c, P)
    flowers(c, P)
    if variant == "thicket":
        thicket(c, P)
    c.rect(0, STAGE, dhgr.W, dhgr.H, dhgr.BLACK)
    return c
