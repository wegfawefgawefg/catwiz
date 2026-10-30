# the night clearing (fights 8-10 and the boss), the moonlit-glow direction the owner chose
# from round 2, and the dusk forest (fights 5-7) between it and the day. Here only as far as
# the lighting proof needs: one backdrop each, with the night's lights on the ground.
#
# night: mostly black, so the loud colours appear only as light - the glowing caps, the
# fireflies, the wand, the moon. Black is the neutral the palette lacks; next to it the
# colours read as glow, not paint. The hat stands against a big moon. Glows are drawn on
# every other row (scanline halos): no dots side by side, so NTSC keeps them clean.
#
# dusk: the day forest's shapes (forest.py) in a dusk palette - an orange sky, the sun low
# and the woods gone to black silhouettes - so it costs no new drawing.

import math

from canvas import Canvas, bands
import dhgr
from dhgr import BLACK, WHITE, DBLUE, PURPLE, MAGENTA, PINK, AQUA, YELLOW, LBLUE, ORANGE
import forest

MOON = (25, 33, 10.5, 19)

DUSK = dict(band=PURPLE, paper=ORANGE, sun=YELLOW, sun_rim=PINK, cloud=PINK, far=BLACK,
            leaf=(BLACK, BLACK, ORANGE), cuts=(0.3, 0.88), trunk=BLACK, grass=BLACK,
            horizon=MAGENTA, tuft=MAGENTA, flower=(PINK,), path=MAGENTA, pebble=PINK,
            water=PINK, glint=YELLOW, bank=MAGENTA, stone=PURPLE, frame=BLACK, shadow=BLACK)


def ring(c, cx, cy, rx, ry, col, every=2, inner=0.0, ymax=124):
    # a halo on every other row: the black pixels of an ellipse outside `inner` of its size
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        if y % every or not (0 <= y < ymax):
            continue
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if not 0 <= x < dhgr.W:
                continue
            d = ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2
            if inner * inner < d <= 1 and c.px[y][x] == BLACK:
                c.px[y][x] = col


def night():
    c = Canvas(BLACK)
    # the night sky: black, a dark blue glow low down, a purple line where the day went
    bands(c, 40, 76, [BLACK, BLACK, DBLUE], blend=9)
    c.hline(0, dhgr.W, 74, PURPLE)
    c.hline(0, dhgr.W, 72, PURPLE)
    for sx, sy in ((48, 8), (70, 20), (96, 6), (120, 18), (60, 40), (110, 36), (84, 30), (132, 46),
                   (8, 60), (40, 24)):
        c.set(sx, sy, LBLUE if (sx + sy) % 3 else WHITE)
    # the moon, big, behind where the hat will be: white with light blue seas, a halo
    mx, my, rx, ry = MOON
    ring(c, mx, my, rx * 1.45, ry * 1.45, DBLUE, 2, 1.0 / 1.45)
    c.ellipse(mx, my, rx, ry, WHITE)
    for dx, dy, r in ((-3.5, -6, 2.4), (3, 4, 3.0), (-2, 9, 1.6), (5, -8, 1.4)):
        c.ellipse(mx + dx, my + dy, r, r * 1.8, LBLUE)
    # the far wood and the framing trees: black against the low glow
    for x in range(dhgr.W):
        top = int(64 + 3 * math.sin(x * 0.21) + 2.5 * math.sin(x * 0.53 + 1) + (3 if (x // 5) % 3 == 0 else 0))
        for y in range(top, 124):
            c.px[y][x] = BLACK
    for x, side in ((1, 1), (139, -1)):
        c.rect(x - 4, 20, x + 4, 124, BLACK)
        c.ellipse(x + side * 3, 4, 14, 24, BLACK)
        c.ellipse(x + side * 10, 22, 7, 10, BLACK)
    c.rect(0, 124, dhgr.W, dhgr.H, BLACK)
    return c


GLOWS = {"puffcap": (PINK, MAGENTA), "sporelet": (AQUA, DBLUE)}


def night_lights(kinds):
    # the night's light on the ground for screen.build: pools under the glowing caps, halos
    # round them, a moonlit pool under the cat, fireflies. The rims are the sprites' own
    # (light.py), so only the ground is lit here.
    def lights(c, figs):
        for k, f in zip(kinds, figs):
            if k not in GLOWS:
                continue
            light, pool = GLOWS[k]
            x0, y0, x1, y1 = f.bbox()
            mx = (x0 + x1) / 2
            ring(c, mx, y0 + (y1 - y0) * 0.35, (x1 - x0) * 0.8, (y1 - y0) * 0.75, pool, 2, 0.0, y1 - 6)
            for y in range(y1 - 4, y1 + 5):
                for x in range(int(mx - 22), int(mx + 23)):
                    if 0 <= x < dhgr.W and c.px[y][x] == BLACK and f.get(x, y) is None:
                        d = ((x + 0.5 - mx) / 21) ** 2 + ((y + 0.5 - (y1 - 0.5)) / 4.5) ** 2
                        if d <= 1:
                            c.px[y][x] = pool if (d > 0.3 or y % 2) else light
        cat = figs[0]
        x0, y0, x1, y1 = cat.bbox()
        for y in range(y1 - 4, y1 + 4):
            for x in range(x0 - 4, x1 + 4):
                d = ((x + 0.5 - (x0 + x1) / 2 - 2) / 18) ** 2 + ((y + 0.5 - (y1 - 1)) / 4) ** 2
                if d <= 1 and y % 2 == 0 and 0 <= x < dhgr.W and c.px[y][x] == BLACK and cat.get(x, y) is None:
                    c.px[y][x] = DBLUE
        for fx, fy in ((14, 92), (50, 78), (100, 96), (128, 82), (62, 112), (92, 66), (24, 112), (70, 90)):
            if c.px[fy][fx] == BLACK:
                c.set(fx, fy, YELLOW)
    return lights


def dusk():
    return forest.picture(DUSK, "clearing")


def no_shadow(c, cx, y, rx):
    pass


def dusk_shadow(c, cx, y, rx):
    c.ellipse(cx, y, rx, 2.2, BLACK)
