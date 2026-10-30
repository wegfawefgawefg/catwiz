# the title in double hi-res: CATWIZ in big white letters with a glowing rim over a night
# page, the cat in the day's colours against a big white moon, small clouds and stars, and
# PRESS RETURN. One picture (packed) plus the rim in a few colours: the game draws the rim over
# itself in turn (faint, warm, bright, warm), a small glow, and leaves the rest alone.
#
# NTSC rule (AGENTS.md): the page black, the moon white, small pieces of colour.

import cat
import fonts
import light
from canvas import ASPECT, Canvas
from dhgr import BLACK, WHITE, YELLOW, ORANGE, MAGENTA, PINK, DBLUE, LBLUE, MBLUE, PURPLE

# the logo's letters on a 5 x 7 grid, each cell 3 pixels by 4 rows
LETTERS = {
    "C": [".####", "##...", "##...", "##...", "##...", "##...", ".####"],
    "A": [".###.", "##.##", "##.##", "#####", "##.##", "##.##", "##.##"],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "W": ["##.##", "##.##", "##.##", "##.##", "#####", "#####", "##.##"],
    "I": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
    "Z": ["#####", "...##", "..##.", ".##..", "##...", "##...", "#####"],
}
CELL_W, CELL_H = 3, 4
LOGO_TOP = 10
GAP = 3
GLOW = [MAGENTA, ORANGE, YELLOW, ORANGE]   # the rim's colours in turn, faint to bright
MOON = (68, 92, 50)                         # centre x, centre y, radius in rows
CAT_AT = (66, 140)                          # the cat's middle pixel and feet row


def logo():
    # the letters (white) on their own canvas, centred
    word = "CATWIZ"
    w = len(word) * 5 * CELL_W + (len(word) - 1) * GAP
    x = (140 - w) // 2
    c = Canvas()
    for ch in word:
        for j, row in enumerate(LETTERS[ch]):
            for i, b in enumerate(row):
                if b == "#":
                    c.rect(x + i * CELL_W, LOGO_TOP + j * CELL_H, x + (i + 1) * CELL_W,
                           LOGO_TOP + (j + 1) * CELL_H, WHITE)
        x += 5 * CELL_W + GAP
    return c


def rim(letters, col):
    # the glow: a pixel ring around the letters, in col only
    ring = letters.copy()
    ring.outline(col, 1, 2)
    out = Canvas()
    for y in range(192):
        for x in range(140):
            if ring.px[y][x] == col and letters.px[y][x] is None:
                out.px[y][x] = col
    return out


def sky(c):
    import random
    rnd = random.Random(7)
    for _ in range(46):
        x, y = rnd.randrange(140), rnd.randrange(150)
        c.set(x, y, WHITE if rnd.random() < 0.7 else LBLUE)
    # thin clouds across the moon's foot and the corners: dark blue with a light blue top
    for x0, x1, y in ((0, 30, 78), (96, 140, 70), (8, 46, 132), (100, 136, 128), (30, 120, 150)):
        c.rect(x0, y, x1, y + 3, DBLUE)
        c.rect(x0 + 2, y, x1 - 2, y + 1, MBLUE)


def picture():
    c = Canvas(BLACK)
    sky(c)
    cx, cy, r = MOON
    c.ellipse(cx, cy, r / ASPECT, r, WHITE)
    # the moon's few craters, light blue
    for x, y, rr in ((cx - 16, cy - 30, 4), (cx + 17, cy - 8, 5), (cx + 12, cy + 30, 3)):
        c.ellipse(x, y, rr / ASPECT, rr, LBLUE)
    hero = light.lit(cat.cat(CAT_AT[0], CAT_AT[1], "meow"), "day")
    c.paste(hero)
    letters = logo()
    c.paste(letters)
    c.paste(rim(letters, GLOW[0]))
    s = "PRESS RETURN"
    fonts.text35(c, 22, s.center(35), WHITE)
    s = "a dice battle in the woods"
    fonts.text35(c, 20, s.center(35), LBLUE)
    return c


def rims():
    # the rim in each colour of the glow, as sprites over the letters
    letters = logo()
    return [rim(letters, col) for col in GLOW]
