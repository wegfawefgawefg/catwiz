# the night: the whole game is midnight since 2026-10-31. The fighters stand on pure black and
# their frames are drawn solid (the figure and the black round it in one copy), so every lane
# of the stage (lanes.py: wherever a look can go) is black, and the scenery lives only
# outside them: a sky band and pockets at the top, the edges, and a little ground below the
# feet. The moonlit-glow direction of the owner's round 2: black is the neutral the palette
# lacks, so next to it the colours read as light - the moon, stars, fireflies, glowing caps,
# rims. NTSC: big areas black, white and the light tier in small shapes, darks in small
# pieces, no dithered areas.
#
#   clearing (fight 1)  a big full moon in the pocket over the sporelet, an old oak at the
#                       left edge with moonlit bark, leaves hanging in at the top right,
#                       glowing pink caps and grass at its foot, fireflies
#   path (fight 2)      a thin crescent in the top band, a lantern on a post at the left edge
#                       with its warm light, a corner of leaves, flagstones under the feet
#
# Also the dusk forest (fights 5-7 in the old plan), for the lighting proof only: the day
# forest's shapes in a dusk palette.

import math
import random

from canvas import Canvas
import dhgr
from dhgr import (BLACK, WHITE, DBLUE, PURPLE, MAGENTA, PINK, AQUA, YELLOW, LBLUE, ORANGE, GREY,
                  DGREEN, BROWN)
import forest
import lanes

FIGHT_OF = {"clearing": 1, "path": 2}

DUSK = dict(band=PURPLE, paper=ORANGE, sun=YELLOW, sun_rim=PINK, cloud=PINK, far=BLACK,
            leaf=(BLACK, BLACK, ORANGE), cuts=(0.3, 0.88), trunk=BLACK, grass=BLACK,
            horizon=MAGENTA, tuft=MAGENTA, flower=(PINK,), path=MAGENTA, pebble=PINK,
            water=PINK, glint=YELLOW, bank=MAGENTA, stone=PURPLE, frame=BLACK, shadow=BLACK)


class Night:
    # a black stage and its lane mask: drawing calls put pixels only outside the lanes
    def __init__(self, n):
        self.c = Canvas(BLACK)
        self.lane = lanes.mask(n)

    def free(self, x, y):
        return 0 <= x < dhgr.W and 0 <= y < forest.STAGE and not self.lane[y][x]

    def set(self, x, y, col):
        x, y = int(x), int(y)
        if self.free(x, y):
            self.c.px[y][x] = col

    def ellipse(self, cx, cy, rx, ry, col):
        self.c.ellipse(cx, cy, rx, ry, col, test=self.free)

    def rect(self, x0, y0, x1, y1, col):
        for y in range(int(y0), int(y1)):
            for x in range(int(x0), int(x1)):
                self.set(x, y, col)

    def stars(self, seed, n, rows=(0, 60)):
        # single pixels where the sky is free, none within two of another light
        rnd = random.Random(seed)
        put = 0
        for _ in range(n * 40):
            if put >= n:
                break
            x, y = rnd.randrange(dhgr.W), rnd.randrange(*rows)
            if not self.free(x, y):
                continue
            if any(self.c.px[yy][xx] != BLACK for yy in range(max(0, y - 2), min(dhgr.H, y + 3))
                   for xx in range(max(0, x - 2), min(dhgr.W, x + 3))):
                continue
            self.c.px[y][x] = WHITE if rnd.random() < 0.3 else LBLUE
            put += 1

    def fireflies(self, spots):
        for x, y in spots:
            if self.free(x, y) and self.c.px[y][x] == BLACK:
                self.c.px[y][x] = YELLOW

    def finish(self):
        # the lanes black, whatever was drawn; the gutter and below black (the hud's)
        for y in range(dhgr.H):
            for x in range(dhgr.W):
                if y >= forest.STAGE or self.lane[y][x]:
                    self.c.px[y][x] = BLACK
        return self.c


def moon(N, cx, cy, rx, ry):
    # a full moon: white, light blue seas, its rim a ring of light blue a pixel out
    N.ellipse(cx, cy, rx + 1, ry + 1.5, LBLUE)
    N.ellipse(cx, cy, rx, ry, WHITE)
    for dx, dy, r in ((-2, -4, 1.6), (2, 3, 2.2), (-1.5, 6, 1.2), (3, -6, 1.1)):
        N.ellipse(cx + dx * rx / 6, cy + dy * ry / 11, r * rx / 6, r * 1.8 * ry / 11, LBLUE)


def crescent(N, cx, cy, rx, ry):
    # a thin crescent lit on its right: the disc, then its dark side taken out, and the dark
    # side's ghost as a dark blue edge every other row
    N.ellipse(cx, cy, rx, ry, WHITE)
    N.ellipse(cx - rx * 0.55, cy - ry * 0.12, rx * 0.9, ry * 0.95, BLACK)
    for y in range(int(cy - ry), int(cy + ry) + 1):
        if y % 2:
            continue
        t = (y + 0.5 - cy) / ry
        if abs(t) < 0.9:
            N.set(cx - rx * math.sqrt(1 - t * t), y, DBLUE)


def trunk(N, top, bottom, rim_x, seed):
    # a black trunk lit on one side by a broken line of light blue (bark), knots in grey
    rnd = random.Random(seed)
    y = top
    while y < bottom:
        run = rnd.randint(5, 14)
        for yy in range(y, min(bottom, y + run)):
            N.set(rim_x, yy, LBLUE)
        y += run + rnd.randint(2, 4)
    for _ in range(3):
        ky = rnd.randint(top + 8, bottom - 8)
        N.set(rim_x - 1, ky, GREY)
        N.set(rim_x - 1, ky + 1, GREY)


def leaves(N, cx, cy, n, spread, seed, rim=LBLUE):
    # a hanging cluster of leaves: each a short slanted dash in the light, some a dark tip
    rnd = random.Random(seed)
    for _ in range(n):
        x = cx + rnd.uniform(-spread, spread)
        y = cy + rnd.uniform(-spread * 0.9, spread * 0.9)
        d = rnd.choice((-1, 1))
        N.set(x, y, rim)
        N.set(x + d, y + 1, rim)
        if rnd.random() < 0.4:
            N.set(x + 2 * d, y + 2, DGREEN)


def caps(N, spots):
    # little glowing mushrooms: a pink cap two wide with a white stem under it
    for x, y in spots:
        N.set(x, y, PINK)
        N.set(x + 1, y, PINK)
        N.set(x, y + 1, WHITE)


def tufts(N, spots, col=DGREEN, tip=AQUA):
    # grass tufts: two blades and a lit tip
    for x, y in spots:
        N.set(x, y, col)
        N.set(x, y - 1, col)
        N.set(x + 2, y, col)
        N.set(x + 2, y - 1, tip)


def roots(N, x, y, spots):
    # moonlit roots from the trunk's foot: lines of light down to the right
    for dx, dy in spots:
        for k in range(dy):
            N.set(x + dx * k // dy, y + k, LBLUE)


def branch(N, x0, y0, x1, y1, leaves_at, seed):
    # a limb as a line of light along its top, leaves (dark green, a lit tip) hanging under it
    n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
    for i in range(n + 1):
        N.set(x0 + (x1 - x0) * i / n, y0 + (y1 - y0) * i / n, LBLUE)
    rnd = random.Random(seed)
    for t in leaves_at:
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t + 1
        drop = rnd.randint(1, 3)
        for k in range(drop):
            N.set(x, y + k, DGREEN)
        N.set(x, y + drop, AQUA)
        N.set(x + 1, y + drop, DGREEN)


def ring_of_caps(N, spots):
    # a fairy ring: glowing caps of two sizes, white stems, a pink glow pixel at the foot
    for x, y, big in spots:
        if big:
            N.rect(x - 1, y, x + 3, y + 1, PINK)
            N.rect(x, y - 1, x + 2, y, MAGENTA)
            N.rect(x, y + 1, x + 2, y + 3, WHITE)
        else:
            N.rect(x, y, x + 2, y + 1, PINK)
            N.set(x, y + 1, WHITE)


def clearing():
    N = Night(FIGHT_OF["clearing"])
    N.stars(11, 22)
    # the moon over the sporelet, in the one big pocket of the clearing's sky
    moon(N, 105, 26, 5.6, 10.5)
    # the old oak at the left edge, its crown off the top: moonlit bark, a limb across the
    # corner, roots at its foot
    trunk(N, 20, 106, 5, 7)
    for y in (34, 52, 77, 95):
        N.rect(2, y, 4, y + 1, GREY)
    roots(N, 5, 104, [(3, 8), (7, 12), (2, 13)])
    branch(N, 0, 14, 13, 5, (0.15, 0.4, 0.6, 0.85), 3)
    branch(N, 4, 3, 12, 0, (0.3, 0.7), 4)
    # a bough reaching in at the top right, a vine down the edge with pink buds
    branch(N, 139, 6, 112, 2, (0.05, 0.2, 0.35, 0.5, 0.65, 0.8, 0.95), 5)
    for y in range(8, 50):
        if y % 7 < 5:
            N.set(136 + (y // 9) % 2, y, DGREEN)
    for y in (16, 30, 44):
        N.set(135 + (y // 9) % 2, y, PINK)
    # between the cat and the puffcap, under their feet: a fairy ring of glowing caps
    ring_of_caps(N, [(52, 112, True), (58, 110, False), (63, 113, True), (56, 116, False),
                     (66, 116, False)])
    tufts(N, [(49, 116), (60, 114)])
    N.fireflies([(3, 70), (10, 112), (100, 48), (61, 109), (137, 52), (88, 9), (2, 44)])
    return N.finish()


def path():
    N = Night(FIGHT_OF["path"])
    N.stars(23, 22)
    # a thin crescent in the top band, over the gap between the cat and the enemies
    crescent(N, 91, 6, 3.6, 5.6)
    # the lantern at the left edge: a post, a hood, warm glass, its light on the post
    N.rect(2, 44, 4, forest.STAGE, BROWN)
    N.rect(0, 30, 6, 31, GREY)
    N.rect(1, 31, 5, 38, ORANGE)
    N.rect(2, 32, 4, 36, YELLOW)
    N.rect(1, 38, 5, 39, GREY)
    for y in (26, 28, 41, 43):
        N.set(3, y, ORANGE)
    # a corner of leaves at the top left and the top right
    leaves(N, 6, 4, 22, 6, 8)
    leaves(N, 132, 3, 18, 7, 9)
    # flagstones under the feet where the stage is free, grey (clean in NTSC)
    for x, y, w in ((0, 112, 4), (8, 109, 4), (6, 114, 5), (50, 110, 5), (57, 113, 6), (64, 110, 5),
                    (52, 116, 4), (62, 116, 4)):
        N.rect(x, y, x + w, y + 2, GREY)
    N.fireflies([(4, 60), (10, 4), (100, 14), (80, 3), (2, 96), (60, 109)])
    return N.finish()


def picture(variant):
    return {"clearing": clearing, "path": path}[variant]()


def dusk():
    return forest.picture(DUSK, "clearing")


def no_shadow(c, cx, y, rx):
    pass


def dusk_shadow(c, cx, y, rx):
    c.ellipse(cx, y, rx, 2.2, BLACK)
