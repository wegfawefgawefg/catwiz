# mockup 1, revision 5: the composition of the real battle screen, on hi-res.
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


# --- actors go on their own layer, so the sticker outline never touches the scenery ---
scene = c
c = Canvas(".")


def dog(x, feet):
    # a three-quarter view turned towards the enemies: features shifted right, the far ear
    # smaller. grey dithered head and ears (soft colour bleed), white muzzle and blaze, ringed
    # eyes with diamond pupils, a tall crooked hat
    c.rect(x - 4, feet - 9, x - 1, feet, "K")                     # legs
    c.rect(x + 3, feet - 9, x + 6, feet, "K")
    c.poly([(x - 7, feet - 22), (x + 9, feet - 22), (x + 14, feet - 7), (x - 12, feet - 7)], "K")  # robe
    hy = feet - 32
    f = x + 2                                                     # face centre, turned right
    c.ellipse(x - 13, hy + 5, 5, 10, "K")                         # near ear (left)
    c.grey(x - 17, hy - 4, x - 8, hy + 15, lambda px, py: ((px - x + 13) / 4) ** 2 + ((py - hy - 5) / 9) ** 2 <= 1)
    c.ellipse(x + 15, hy + 3, 3, 7, "K")                          # far ear (right), smaller
    c.ellipse(x, hy, 12, 11, "K")                                 # head
    c.grey(x - 11, hy - 10, x + 12, hy + 11, lambda px, py: ((px - x) / 11) ** 2 + ((py - hy) / 10) ** 2 <= 1)
    c.ellipse(f + 1, hy + 6, 8, 5, "W")                           # muzzle
    c.rect(f - 1, hy - 10, f + 3, hy + 2, "W")                    # blaze
    for ex, r in ((f - 5, 4), (f + 6, 3)):                        # eyes, the far one smaller
        c.ellipse(ex, hy - 2, r + 1, r + 1, "K")
        c.ellipse(ex, hy - 2, r, r, "W")
        c.poly([(ex + 1, hy - 4), (ex + 3, hy - 2), (ex + 1, hy), (ex - 1, hy - 2)], "K")
    c.ellipse(f + 3, hy + 3, 3, 2, "K")                           # nose
    c.line(f + 3, hy + 5, f, hy + 8, "K")
    c.line(f + 3, hy + 5, f + 6, hy + 8, "K")
    brim = hy - 9
    c.poly([(x - 26, brim + 4), (x + 24, brim - 1), (x + 27, brim + 2), (x - 24, brim + 7)], "K")  # brim, tilted
    c.poly([(x - 10, brim + 2), (x + 10, brim), (x + 5, brim - 20), (x + 1, brim - 21)], "K")   # cone
    c.poly([(x + 5, brim - 20), (x + 1, brim - 21), (x + 9, brim - 31), (x + 12, brim - 30)], "K")  # crooked tip
    c.poly([(x - 10, brim - 2), (x + 10, brim - 4), (x + 9, brim - 1), (x - 10, brim + 1)], "V")  # band
    c.line(x + 12, feet - 17, x + 25, feet - 28, "W", 2)          # wand
    c.rect(x + 24, feet - 30, x + 28, feet - 26, "W")


# --- mushos and a bwat ---
def musho(x, feet, s, mood):
    # leaning left towards the dog; a face on the stem with brows and a mouth
    lean = -3 * s
    c.poly([(x - 5 * s, feet), (x + 5 * s, feet), (x + 5 * s + lean, feet - 13 * s), (x - 5 * s + lean, feet - 13 * s)], "W")
    cap = feet - 15 * s
    cx = x + lean * 1.4
    c.ellipse(cx, cap, 12 * s, 8 * s, "V")
    c.rect(int(cx - 12 * s), int(cap), int(cx + 12 * s) + 1, int(cap + 3 * s), "V")
    c.ellipse(cx - 6 * s, cap - 3 * s, 2.5 * s, 2 * s, "W")
    c.ellipse(cx + 3 * s, cap - 5 * s, 2 * s, 1.5 * s, "W")
    c.ellipse(cx + 8 * s, cap - 1 * s, 1.5 * s, 1.5 * s, "W")
    fx = x + lean * 0.6 - 1 * s                                    # face, turned left
    ey = feet - 9 * s
    c.rect(int(fx - 3 * s), int(ey), int(fx - 1 * s), int(ey + 3 * s), "K")   # eyes
    c.rect(int(fx + 1 * s), int(ey), int(fx + 3 * s), int(ey + 3 * s), "K")
    if mood == "angry":
        c.line(fx - 4 * s, ey - 3 * s, fx - 1 * s, ey - 1 * s, "K", 1)        # brows down in the middle
        c.line(fx + 4 * s, ey - 3 * s, fx + 1 * s, ey - 1 * s, "K", 1)
        c.rect(int(fx - 2 * s), int(ey + 5 * s), int(fx + 2 * s), int(ey + 6 * s), "K")  # flat mouth
    else:
        c.line(fx - 4 * s, ey - 1 * s, fx - 1 * s, ey - 3 * s, "K", 1)        # worried brows
        c.line(fx + 4 * s, ey - 1 * s, fx + 1 * s, ey - 3 * s, "K", 1)
        c.ellipse(fx, ey + 5.5 * s, 1.5 * s, 1.5 * s, "K")                    # little o mouth


def bwat(x, y):
    # a jagged-winged bat, flapping, glaring at the dog with a fanged grin
    wing = [(x - 6, y - 2), (x - 30, y - 14), (x - 25, y - 4), (x - 32, y + 1), (x - 21, y + 1),
            (x - 23, y + 8), (x - 10, y + 5)]
    c.poly(wing, "K")
    c.poly([(2 * x - px + 2, py - 3) for px, py in wing], "K")       # far wing up, mid-flap
    c.ellipse(x, y + 1, 9, 10, "K")
    c.poly([(x - 8, y - 6), (x - 6, y - 17), (x - 2, y - 7)], "K")
    c.poly([(x + 2, y - 7), (x + 6, y - 15), (x + 8, y - 5)], "K")
    c.poly([(x - 7, y - 3), (x - 2, y - 1), (x - 3, y + 2), (x - 7, y + 1)], "W")   # angled eyes
    c.poly([(x + 6, y - 3), (x + 1, y - 1), (x + 2, y + 2), (x + 6, y + 1)], "W")
    c.rect(x - 5, y + 5, x + 5, y + 7, "W")                             # grin
    c.poly([(x - 4, y + 7), (x - 2, y + 7), (x - 3, y + 10)], "W")      # fangs
    c.poly([(x + 2, y + 7), (x + 4, y + 7), (x + 3, y + 10)], "W")


dog(70, GROUND + 2)

# the wand's shot: a dotted arc of small triangles from the wand to the bwat
import math as _m
for i in range(1, 9):
    t = i / 9
    px = 94 + (226 - 94) * t
    py = 76 - 34 * _m.sin(_m.pi * t) + (70 - 76) * t
    c.poly([(px - 3, py + 2), (px + 3, py + 2), (px, py - 3)], "W")
musho(158, GROUND, 1.15, "angry")
musho(193, GROUND - 2, 0.85, "worried")
bwat(232, 70)



# sticker outline round every actor, then onto the scene, then shadows under them
c.outline("K", inside=lambda col, x, y: col != ".", t=1)
actor_layer = c
c = scene
for x, rx in ((70, 14), (158, 12), (193, 9), (232, 11)):
    c.ellipse(x, GROUND + 1, rx, 2.5, "K")
for y in range(192):
    for x in range(280):
        if actor_layer.px[y][x] != ".":
            c.px[y][x] = actor_layer.px[y][x]

def pill(x, y, hp, res):
    s = f"*{hp}" + (f" @{res}" if res is not None else "")
    w = text_width(s, 2) + 8
    capsule(x - w // 2, y, x + w // 2, y + 11, "K")
    fat(x - text_width(s, 2) // 2, y + 2, s)


pill(70, 110, 8, None)
pill(158, 108, 9, None)
pill(193, 108, 7, None)
pill(232, 108, 6, None)

# statuses under the pills: skull (doomed), blood drop (bleeding)
SKULL = ["..####..", ".######.", "##..##..", "##..##..", "########", ".##..##.", ".######."]
DROP = ["...##...", "...##...", "..####..", ".######.", "########", "########", ".######."]
for x, icon in ((158, SKULL), (193, DROP), (232, DROP)):
    c.ellipse(x, 128, 8, 6, "K")
    c.stamp(x - 4, 125, icon, {"#": "W"})

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

# --- the hand: five tilted dice, black faces with a white rim ---
def die(cx, deg, draw):
    c.poly_rot(cx, 170, 37, 37, deg, "K")
    c.poly_rot(cx, 170, 34, 34, deg, "W")
    c.poly_rot(cx, 170, 30, 30, deg, "K")
    draw(cx - 17, 153)


die(38, -6, lambda x, y: (c.line(x + 9, y + 30, x + 24, y + 8, "O", 3), c.ellipse(x + 25, y + 7, 4, 4, "W")))
die(80, 4, lambda x, y: (c.ellipse(x + 17, y + 11, 7, 6, "W"), c.rect(x + 11, y + 16, x + 24, y + 30, "W"),
                         c.rect(x + 7, y + 19, x + 28, y + 23, "W"), c.line(x + 14, y + 8, x + 18, y + 12, "K", 2),
                         c.line(x + 18, y + 8, x + 14, y + 12, "K", 2), c.rect(x + 15, y + 23, x + 20, y + 27, "O")))
die(122, -3, lambda x, y: c.poly([(x + 17, y + 5), (x + 27, y + 13), (x + 24, y + 31), (x + 11, y + 31), (x + 8, y + 13)], "G"))
die(164, 5, lambda x, y: (c.rect(x + 8, y + 6, x + 26, y + 31, "V"), c.rect(x + 11, y + 8, x + 26, y + 29, "W"),
                          c.poly([(x + 18, y + 12), (x + 23, y + 20), (x + 13, y + 20)], "V")))
die(206, -4, lambda x, y: (c.line(x + 11, y + 25, x + 23, y + 11, "W", 4), c.ellipse(x + 9, y + 27, 4, 4, "W"),
                           c.ellipse(x + 13, y + 29, 4, 4, "W"), c.ellipse(x + 24, y + 8, 4, 4, "W"),
                           c.ellipse(x + 27, y + 12, 4, 4, "W")))
# re-roll: a die showing five pips, with the rolls left under it
c.rect(252, 156, 274, 178, "W")
for px, py in ((256, 160), (268, 160), (262, 166), (256, 172), (268, 172)):
    c.rect(px, py, px + 3, py + 3, "K")
for x in (255, 265):
    c.stamp(x, 182, ["..#..", ".###.", "#####", ".###.", "..#.."], {"#": "W"})

for look in ("color", "ntsc"):
    render(c, os.path.join(OUT, f"battle_forest_v5_{look}.png"), look)
print("ok")
