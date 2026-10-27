# mockup 1, revision 3: the composition of the real battle screen, on hi-res.
#
# proportions taken from the game's battle screenshots, scaled to 280 x 192:
# - horizon about 40% down (y 72); actors stand on a ground line just past half (y 104);
#   the dog is about a quarter of the screen tall; open ground between actors and cards.
# - depth: pale haze sky, a soft distant treeline, big dark trees only at the edges,
#   framing a clearing. darker ground towards the bottom.
# - quiet UI: small HUD, frameless pills, a die for re-roll.
#
# run: tools/.venv/bin/python mockup/battle_forest_v3.py

import math
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "tools"))
from hgr import Canvas, render, text_width  # noqa: E402

OUT = os.path.join(os.path.dirname(__file__), "out")
os.makedirs(OUT, exist_ok=True)
c = Canvas("K")
GROUND = 104


def fat(x, y, s, colour="W"):
    c.text(x, y, s, colour, 2, 1)


def capsule(x0, y0, x1, y1, colour):
    r = (y1 - y0) // 2
    c.rect(x0 + r, y0, x1 - r, y1, colour)
    c.ellipse(x0 + r, y0 + r, r, r, colour)
    c.ellipse(x1 - r, y0 + r, r, r, colour)


# --- sky: green fading to pale haze at the horizon, ordered (bayer) dither ---
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
c.rect(0, 0, 280, 72, "G")
for y in range(0, 72):
    t = (y / 72) ** 1.3
    for x in range(280):
        # pairs of pixels so the white is clean (a lone pixel would show as colour)
        if BAYER[y % 4][(x // 2) % 4] < int(t * 13):
            c.set(x, y, "W")

# --- distant treeline: solid green crowns against the pale haze ---
for i in range(17):
    x = i * 18 + (i * 7) % 9
    c.ellipse(x, 66, 11 + (i * 5) % 6, 7 + (i * 3) % 5, "G")
c.rect(0, 66, 280, 78, "G")

# --- ground: solid near the horizon, darker towards the viewer ---
c.rect(0, 76, 280, 146, "G")
c.checker(0, 118, 280, 146, "G")


# --- framing trees at the edges: black trunks, big black crowns ---
def tree(x, trunk_w, top, crown_r):
    c.rect(x - trunk_w // 2, top, x + trunk_w // 2, 146, "K")
    c.ellipse(x, top, crown_r, crown_r * 0.8, "K")
    c.ellipse(x - crown_r * 0.6, top + crown_r * 0.3, crown_r * 0.7, crown_r * 0.6, "K")
    c.ellipse(x + crown_r * 0.6, top + crown_r * 0.4, crown_r * 0.7, crown_r * 0.6, "K")


tree(8, 12, 22, 30)
tree(276, 14, 16, 34)
c.ellipse(30, 146, 30, 10, "K")       # foreground dark at the corners
c.ellipse(258, 146, 34, 12, "K")


# --- the dog witch: big head, small body, tall hat ---
def dog(x, feet):
    c.ellipse(x, feet, 14, 3, "K")                                # shadow
    c.rect(x - 5, feet - 9, x - 2, feet, "K")                     # legs
    c.rect(x + 2, feet - 9, x + 5, feet, "K")
    c.poly([(x - 9, feet - 24), (x + 9, feet - 24), (x + 12, feet - 8), (x - 12, feet - 8)], "K")  # robe
    head_y = feet - 34
    c.ellipse(x - 13, head_y + 3, 4, 9, "K")                      # ears, droopy
    c.ellipse(x + 13, head_y + 3, 4, 9, "K")
    c.ellipse(x, head_y, 12, 11, "W")                             # face
    c.ellipse(x - 5, head_y - 1, 4, 4, "K")                       # eye patches
    c.ellipse(x + 5, head_y - 1, 4, 4, "K")
    c.ellipse(x - 5, head_y - 1, 3, 3, "W")
    c.ellipse(x + 5, head_y - 1, 3, 3, "W")
    for ex in (x - 5, x + 5):                                     # diamond pupils
        c.poly([(ex, head_y - 3), (ex + 2, head_y - 1), (ex, head_y + 1), (ex - 2, head_y - 1)], "K")
    c.rect(x - 2, head_y + 5, x + 2, head_y + 7, "K")             # nose
    brim = head_y - 9
    c.poly([(x - 22, brim + 2), (x + 20, brim), (x + 22, brim + 3), (x - 20, brim + 5)], "K")  # brim
    c.poly([(x - 9, brim + 1), (x + 9, brim), (x + 2, brim - 30), (x - 1, brim - 30)], "K")    # cone
    c.poly([(x - 9, brim - 3), (x + 9, brim - 4), (x + 8, brim - 1), (x - 9, brim)], "V")      # band
    c.line(x + 10, feet - 18, x + 22, feet - 28, "W", 2)          # wand


# --- mushos and a bwat ---
def musho(x, feet, s):
    c.ellipse(x, feet, 10 * s, 2.5 * s, "K")
    c.rect(int(x - 5 * s), int(feet - 13 * s), int(x + 5 * s), int(feet), "W")    # stem
    c.ellipse(x, feet - 1, 6 * s, 2 * s, "W")
    cap = feet - 15 * s
    c.ellipse(x, cap, 12 * s, 8 * s, "V")                                          # cap
    c.rect(int(x - 12 * s), int(cap), int(x + 12 * s) + 1, int(cap + 3 * s), "V")
    c.ellipse(x - 5 * s, cap - 3 * s, 2.5 * s, 2 * s, "W")
    c.ellipse(x + 4 * s, cap - 4 * s, 2 * s, 1.5 * s, "W")
    c.ellipse(x + 8 * s, cap, 1.5 * s, 1.5 * s, "W")
    c.rect(int(x - 3 * s), int(feet - 9 * s), int(x - 1 * s), int(feet - 6 * s), "K")  # eyes
    c.rect(int(x + 1 * s), int(feet - 9 * s), int(x + 3 * s), int(feet - 6 * s), "K")


def bwat(x, y):
    c.ellipse(x, GROUND + 1, 12, 2, "K")                            # shadow far below
    wing = [(x - 6, y - 2), (x - 28, y - 10), (x - 24, y - 2), (x - 30, y + 2), (x - 20, y + 2),
            (x - 22, y + 8), (x - 10, y + 5)]
    c.poly(wing, "K")
    c.poly([(2 * x - px, py) for px, py in wing], "K")
    c.ellipse(x, y + 1, 9, 10, "K")
    c.poly([(x - 8, y - 6), (x - 5, y - 16), (x - 2, y - 7)], "K")
    c.poly([(x + 2, y - 7), (x + 5, y - 16), (x + 8, y - 6)], "K")
    c.rect(x - 6, y - 2, x - 2, y + 2, "W")
    c.rect(x + 2, y - 2, x + 6, y + 2, "W")


dog(70, GROUND + 2)
musho(158, GROUND, 1.15)
musho(193, GROUND - 2, 0.85)
bwat(232, 70)


def pill(x, y, hp, res):
    s = f"*{hp}" + (f" @{res}" if res is not None else "")
    w = text_width(s, 2) + 8
    capsule(x - w // 2, y, x + w // 2, y + 11, "K")
    fat(x - text_width(s, 2) // 2, y + 2, s)


pill(70, 110, 8, None)
pill(158, 108, 9, None)
pill(193, 108, 7, None)
pill(232, 108, 6, None)

# intents, small, above heads
fat(152, 64, "!2")
fat(187, 74, "!1")
fat(228, 42, "!3")

# --- HUD: small, top left, top centre ---
capsule(2, 2, 48, 13, "K")
c.rect(6, 3, 16, 12, "O")
fat(7, 4, "1", "K")
fat(20, 4, "2")
fat(34, 4, "3")
capsule(52, 2, 84, 13, "K")
for x in (58, 70):
    c.stamp(x, 4, ["...#...", "..###..", ".#####.", "..###..", "...#..."], {"#": "W"})
capsule(104, 2, 176, 13, "K")
for i, x in enumerate((110, 124, 138)):
    c.ellipse(x + 3, 7, 3, 3, "W" if i == 0 else "V")
c.line(113, 7, 135, 7, "V")
c.stamp(152, 4, ["#.#.#", "#####", "#####"], {"#": "W"})

# --- the hand: five icon cards centred on the byte grid, a die for re-roll ---
def card(col, draw):
    x = col * 7
    c.rect(x, 150, x + 35, 190, "K")
    c.frame(x, 150, x + 35, 190, "W", 2)
    draw(x, 150)


card(5, lambda x, y: (c.line(x + 9, y + 32, x + 24, y + 9, "O", 3), c.ellipse(x + 25, y + 8, 4, 4, "W")))
card(11, lambda x, y: (c.ellipse(x + 17, y + 12, 7, 6, "W"), c.rect(x + 11, y + 17, x + 24, y + 33, "W"),
                       c.rect(x + 6, y + 20, x + 29, y + 24, "W"), c.line(x + 14, y + 9, x + 18, y + 13, "K", 2),
                       c.line(x + 18, y + 9, x + 14, y + 13, "K", 2), c.rect(x + 15, y + 25, x + 20, y + 29, "O")))
card(17, lambda x, y: c.poly([(x + 17, y + 6), (x + 27, y + 14), (x + 24, y + 33), (x + 11, y + 33), (x + 8, y + 14)], "G"))
card(23, lambda x, y: (c.rect(x + 8, y + 7, x + 27, y + 34, "V"), c.rect(x + 11, y + 9, x + 27, y + 32, "W"),
                       c.poly([(x + 19, y + 13), (x + 24, y + 21), (x + 14, y + 21)], "V")))
card(29, lambda x, y: (c.line(x + 11, y + 27, x + 23, y + 13, "W", 4), c.ellipse(x + 9, y + 29, 4, 4, "W"),
                       c.ellipse(x + 13, y + 31, 4, 4, "W"), c.ellipse(x + 24, y + 10, 4, 4, "W"),
                       c.ellipse(x + 27, y + 14, 4, 4, "W")))
# re-roll: a die showing five pips, with the rolls left under it
c.rect(252, 156, 274, 178, "W")
for px, py in ((256, 160), (268, 160), (262, 166), (256, 172), (268, 172)):
    c.rect(px, py, px + 3, py + 3, "K")
for x in (255, 265):
    c.stamp(x, 182, ["..#..", ".###.", "#####", ".###.", "..#.."], {"#": "W"})

for look in ("color", "ntsc"):
    render(c, os.path.join(OUT, f"battle_forest_v3_{look}.png"), look)
print("ok")
