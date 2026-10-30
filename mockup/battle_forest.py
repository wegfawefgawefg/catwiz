# mockup 1: the first forest battle on hi-res, to settle positions, sizes and negative space.
# 280 x 192, 40 byte columns of 7 pixels.
#
# hi-res rules learned in v1:
# - text needs 2-pixel-wide strokes (scale 2 across); 1-pixel strokes show as colour.
# - black disappears on dark: actors stand on a bright backdrop. black trees on green work
#   with either palette, so the green/orange byte clash never comes up.
# - darker shades use a staggered checker, not skipped rows (those read as scanlines).
#
# run: python3 mockup/battle_forest.py  -> mockup/out/battle_forest_*.png

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
from hgr import Canvas, render, text_width  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "out")
os.makedirs(OUT, exist_ok=True)

c = Canvas("K")


def fat(x, y, s, colour="W"):
    c.text(x, y, s, colour, 2, 1)


def fat_width(s):
    return text_width(s, 2)


# --- background: bright green forest, black trees, darker ground ---
c.rect(0, 16, 280, 120, "G")
for x, r in ((14, 30), (70, 22), (120, 26), (178, 20), (232, 30), (276, 18)):
    c.ellipse(x, 18, r, 14, "K")              # canopy blobs along the top
for x, w in ((6, 9), (86, 6), (110, 4), (168, 5), (226, 8), (268, 7)):
    c.rect(x, 20, x + w, 120, "K")            # trunks
c.checker(0, 120, 280, 144, "G")             # ground
for x, rx in ((50, 26), (147, 18), (196, 14), (245, 16)):
    c.ellipse(x, 121, rx, 3, "K")             # shadows

# --- top bar ---
c.frame(1, 1, 56, 14, "W")                    # wand charge 1 2 3
c.rect(2, 2, 18, 13, "O")
fat(4, 4, "1", "K")
fat(22, 4, "2")
fat(40, 4, "3")
for x in (64, 76):                            # mana
    c.stamp(x, 3, ["...#...", "..###..", ".#####.", "#######", ".#####.", "..###..", "...#..."], {"#": "W"})
fat(104, 4, "FOREST")
for i, x in enumerate((184, 198, 212)):       # stage track and boss
    c.rect(x, 6, x + 6, 10, "W" if i == 0 else "V")
c.stamp(226, 3, ["#.#.#.#", "#######", "#######", "#######"], {"#": "V"})

# --- the dog witch, left ---
cx = 50
c.poly([(cx - 2, 30), (cx - 17, 74), (cx + 15, 74)], "K")        # hat
c.rect(cx - 26, 72, cx + 24, 77, "K")                             # brim
c.rect(cx - 15, 66, cx + 13, 71, "V")                             # band
c.ellipse(cx, 89, 15, 13, "W")                                     # face
c.ellipse(cx - 13, 92, 5, 9, "K")                                  # ears
c.ellipse(cx + 13, 92, 5, 9, "K")
c.poly([(cx - 6, 83), (cx - 2, 88), (cx - 6, 93), (cx - 10, 88)], "K")   # diamond eyes
c.poly([(cx + 6, 83), (cx + 10, 88), (cx + 6, 93), (cx + 2, 88)], "K")
c.rect(cx - 2, 96, cx + 3, 99, "K")                                # nose
c.poly([(cx - 10, 102), (cx + 10, 102), (cx + 15, 120), (cx - 15, 120)], "K")  # robe
c.line(cx + 12, 106, cx + 24, 98, "O", 2)                          # wand in paw


# --- enemies, right: two mushos and a bwat ---
def musho(x, y, s):
    c.ellipse(x, y, 14 * s, 10 * s, "V")                          # cap
    c.ellipse(x - 6 * s, y - 2 * s, 3 * s, 2 * s, "W")             # spots
    c.ellipse(x + 6 * s, y - 4 * s, 3 * s, 2 * s, "W")
    c.rect(int(x - 7 * s), int(y + 6 * s), int(x + 7 * s), int(y + 26 * s), "W")   # stem
    c.rect(int(x - 4 * s), int(y + 11 * s), int(x - 1 * s), int(y + 16 * s), "K")  # eyes
    c.rect(int(x + 2 * s), int(y + 11 * s), int(x + 5 * s), int(y + 16 * s), "K")


def bwat(x, y):
    c.poly([(x - 32, y - 10), (x - 8, y - 2), (x - 14, y + 12)], "K")   # wings
    c.poly([(x + 32, y - 10), (x + 8, y - 2), (x + 14, y + 12)], "K")
    c.ellipse(x, y + 2, 12, 13, "K")                                   # body
    c.rect(x - 7, y - 2, x - 2, y + 3, "W")                            # eyes
    c.rect(x + 3, y - 2, x + 8, y + 3, "W")
    c.poly([(x - 10, y - 9), (x - 5, y - 20), (x - 2, y - 9)], "K")    # ears
    c.poly([(x + 3, y - 9), (x + 6, y - 20), (x + 10, y - 9)], "K")


musho(147, 90, 1.0)
musho(196, 96, 0.8)
bwat(245, 68)


def pill(x, hp, res):
    lines = [f"*{hp}"] + ([f"@{res}"] if res is not None else [])
    w = max(fat_width(s) for s in lines) + 8
    h = 10 * len(lines) + 2
    c.rect(x - w // 2, 124, x + w // 2, 124 + h, "K")
    c.frame(x - w // 2, 124, x + w // 2, 124 + h, "W")
    for i, s in enumerate(lines):
        fat(x - fat_width(s) // 2, 126 + i * 10, s)


pill(cx, 8, None)
pill(147, 9, 1)
pill(196, 7, 1)
pill(245, 6, 2)

# what each enemy will do next: a sword and its damage
fat(136, 58, "!2")
fat(186, 68, "!1")
fat(234, 36, "!3")

# --- the hand: five icon cards, five bytes wide, a byte apart ---
def card(i, draw):
    x = 7 + i * 42
    c.rect(x, 148, x + 35, 191, "K")
    c.frame(x, 148, x + 35, 191, "W", 2)
    draw(x, 148)


card(0, lambda x, y: (c.line(x + 8, y + 36, x + 25, y + 10, "O", 3), c.ellipse(x + 26, y + 9, 4, 4, "W")))
card(1, lambda x, y: (c.ellipse(x + 17, y + 13, 8, 7, "W"), c.rect(x + 10, y + 19, x + 25, y + 37, "W"),
                      c.rect(x + 5, y + 22, x + 30, y + 26, "W"), c.line(x + 13, y + 10, x + 18, y + 15, "K", 2),
                      c.line(x + 18, y + 10, x + 13, y + 15, "K", 2), c.rect(x + 15, y + 27, x + 20, y + 31, "O")))
card(2, lambda x, y: c.poly([(x + 17, y + 7), (x + 27, y + 15), (x + 24, y + 36), (x + 11, y + 36), (x + 8, y + 15)], "G"))
card(3, lambda x, y: (c.rect(x + 7, y + 8, x + 28, y + 37, "V"), c.rect(x + 11, y + 10, x + 28, y + 35, "W"),
                      c.poly([(x + 19, y + 14), (x + 24, y + 22), (x + 14, y + 22)], "V")))
card(4, lambda x, y: (c.line(x + 10, y + 30, x + 24, y + 14, "W", 4), c.ellipse(x + 8, y + 33, 4, 4, "W"),
                      c.ellipse(x + 12, y + 35, 4, 4, "W"), c.ellipse(x + 25, y + 11, 4, 4, "W"),
                      c.ellipse(x + 28, y + 15, 4, 4, "W")))

c.frame(217, 148, 274, 191, "W", 2)          # re-roll, with the rolls left as diamonds
c.text(227, 153, "RE-", "W", 2)
c.text(227, 169, "ROLL", "W", 2)
for x in (238, 248):
    c.stamp(x, 183, ["..#..", ".###.", "#####", ".###.", "..#.."], {"#": "W"})

for look in ("color", "ntsc"):
    render(c, os.path.join(OUT, f"battle_forest_{look}.png"), look)
print("ok")
