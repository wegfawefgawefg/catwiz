# the garden at midnight (fights 4-6), drawn outside each fight's lanes like night.py's woods:
# a picket fence along the left edge with a tall sunflower nodding over it, a clothesline
# across the sky band with a sock and a shirt pegged on it, a half moon over the right-hand
# pocket, stars; a watering can and a flower bed's tulips along the ground, a bean pole with
# its pods at the right edge, fireflies. NTSC: white and the light tier in small shapes on the
# black, darks only as lines.

import math
import random

import dhgr
from dhgr import BLACK, WHITE, PINK, AQUA, YELLOW, LBLUE, ORANGE, GREY, DGREEN, GREEN, MAGENTA, MBLUE
import forest
from night import Night, moon


def half_moon(N, cx, cy, rx, ry):
    # lit on its left half, the right a dark blue ghost every other row
    N.ellipse(cx, cy, rx + 1, ry + 1.5, LBLUE)
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            dx, dy = (x + .5 - cx) / rx, (y + .5 - cy) / ry
            if dx * dx + dy * dy > 1:
                continue
            if x < cx:
                N.set(x, y, WHITE)
            elif y % 2 == 0:
                N.set(x, y, BLACK)
            else:
                N.set(x, y, BLACK)
    N.set(cx - rx * 0.4, cy - ry * 0.3, LBLUE)
    N.set(cx - rx * 0.5, cy + ry * 0.35, LBLUE)


def fence(N, x0, x1, top, bottom):
    # white pickets two pixels wide with pointed tops, a rail across, a pixel apart
    x = x0
    while x < x1:
        N.rect(x, top + 2, x + 2, bottom, WHITE)
        N.set(x, top + 1, WHITE)
        N.set(x + 1, top + 1, WHITE)
        N.set(x + (x // 3) % 2, top, WHITE)
        x += 4
    for ry in (top + 8, bottom - 8):
        N.rect(x0, ry, x1, ry + 1, LBLUE)


def sunflower(N, x, top, bottom):
    # a stalk up the fence, two leaves, a big head turned down at the stage, yellow petals
    for y in range(top + 6, bottom):
        N.set(x, y, GREEN)
    for ly, d in ((top + 22, 1), (top + 34, -1)):
        N.rect(x + d, ly, x + d * 4, ly + 1, GREEN)
        N.set(x + d * 4, ly - 1, AQUA)
    N.ellipse(x + 1, top + 3, 4.6, 6.5, YELLOW)
    N.ellipse(x + 1.5, top + 3.5, 2.4, 3.6, ORANGE)
    N.set(x + 1, top + 2, YELLOW)


def clothesline(N, y0, y1, x0, x1, pegs):
    # a sagging line of light blue, things pegged on it: (x, what)
    n = x1 - x0
    for i in range(n + 1):
        t = i / n
        N.set(x0 + i, y0 + (y1 - y0) * t + 3 * math.sin(t * math.pi), LBLUE)
    for x, what in pegs:
        t = (x - x0) / n
        y = int(y0 + (y1 - y0) * t + 3 * math.sin(t * math.pi)) + 1
        if what == "sock":
            N.rect(x, y, x + 3, y + 6, PINK)
            N.rect(x - 2, y + 5, x + 3, y + 8, PINK)
            N.rect(x, y, x + 3, y + 1, WHITE)
        elif what == "shirt":
            N.rect(x - 3, y, x + 6, y + 3, AQUA)
            N.rect(x - 1, y + 3, x + 4, y + 9, AQUA)
            N.set(x + 1, y + 1, WHITE)
        N.set(x, y - 1, YELLOW)
        N.set(x + 2, y - 1, YELLOW)


def tulips(N, spots):
    for x, y, col in spots:
        N.set(x, y, GREEN)
        N.set(x, y + 1, GREEN)
        N.rect(x - 1, y - 2, x + 2, y, col)
        N.set(x, y - 3, col)


def can(N, x, y):
    # a watering can on the ground: body, spout, handle, a drip
    N.rect(x, y, x + 6, y + 4, GREY)
    N.rect(x + 1, y - 1, x + 5, y, GREY)
    for k in range(4):
        N.set(x - 1 - k, y + 1 - k, GREY)
    N.set(x - 5, y - 3, LBLUE)
    N.rect(x + 6, y, x + 7, y + 3, GREY)


def beanpole(N, x, top, bottom, seed):
    rnd = random.Random(seed)
    for y in range(top, bottom):
        N.set(x, y, ORANGE if y % 9 else YELLOW)
        if y % 5 == 0:
            d = rnd.choice((-1, 1))
            N.set(x + d, y, GREEN)
            N.set(x + 2 * d, y + 1, AQUA if rnd.random() < 0.5 else GREEN)


def garden(n):
    N = Night(n)
    N.stars(41 + n, 20, rows=(0, 40))
    half_moon(N, 114, 20, 5.0, 9.5)
    clothesline(N, 3, 6, 0, 76, [(8, "sock"), (26, "shirt"), (50, "sock"), (64, "shirt")])
    clothesline(N, 5, 2, 105, 139, [(116, "sock"), (130, "shirt")])
    fence(N, 0, 14, 40, forest.STAGE)
    sunflower(N, 6, 18, forest.STAGE)
    beanpole(N, 137, 10, forest.STAGE, n)
    beanpole(N, 133, 30, forest.STAGE, n + 1)
    tulips(N, [(18, 112, PINK), (24, 114, YELLOW), (46, 113, PINK), (60, 112, YELLOW), (72, 114, PINK),
               (90, 113, YELLOW), (104, 112, PINK), (120, 114, YELLOW)])
    can(N, 36, 112)
    N.fireflies([(3, 30), (12, 110), (98, 40), (126, 60), (70, 9), (52, 116)])
    return N.finish()
