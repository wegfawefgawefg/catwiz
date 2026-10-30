# the full screens: the forest backdrop the battle is drawn over, and the title in its glow
# steps. Both come from the v6 mockup's composition (mockup/battle_forest_v6.py).

import math

from hgr import Canvas, FONT
import hero

GROUND = 104
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

# the dice tray, in a black band from row 127 down to the text (rows 160 on are under the text
# in mixed mode, black too). Each die's face picture goes in a tile at byte column DIE_COL[i],
# rows DIE_TOP to DIE_TOP + 20, with its number in a pill below (the game draws those: battle/
# hud.tsp) over the foot of a tilted card with a white rim. Right of the dice the re-roll and
# end-turn buttons, slanted white boxes; the game writes R and the re-rolls left on the first
# and the mana stars under them
DIE_COLS = (2, 8, 14, 20, 26)
DIE_TILTS = (-4, 3, -3, 4, -3)
DIE_TOP = 130
BAND_TOP = 127
BUTTON_TOP, BUTTON_BOTTOM = 128, 142
REROLL_X = (212, 238)  # the top edge; the bottom one 2 px to the left
END_X = (242, 280)


def forest():
    c = Canvas("K")
    # sky: green fading to pale haze at the horizon, bayer dither in pixel pairs
    c.rect(0, 0, 280, 72, "G")
    for y in range(0, 72):
        t = (y / 72) ** 1.3
        for x in range(280):
            if BAYER[y % 4][(x // 2) % 4] < int(t * 13):
                c.set(x, y, "W")
    # distant treeline: solid green crowns against the haze
    for i in range(17):
        x = i * 18 + (i * 7) % 9
        c.ellipse(x, 66, 11 + (i * 5) % 6, 7 + (i * 3) % 5, "G")
    c.rect(0, 66, 280, 78, "G")
    # ground: solid near the horizon, darker towards the viewer
    c.rect(0, 76, 280, 146, "G")
    c.checker(0, 118, 280, 146, "G")
    tree(c, 8, 12, 22, 30)
    tree(c, 276, 14, 16, 34)
    c.ellipse(30, 146, 30, 10, "K")
    c.ellipse(258, 146, 34, 12, "K")
    tray(c)
    return c


def tray(c):
    c.rect(0, BAND_TOP, 280, 192, "K")
    for col, deg in zip(DIE_COLS, DIE_TILTS):
        cx = col * 7 + 10.5
        c.poly_rot(cx, 142, 31, 29, deg, "W")
        c.poly_rot(cx, 142, 27, 25, deg, "K")
    for x0, x1 in (REROLL_X, END_X):
        c.poly([(x0, BUTTON_TOP), (x1, BUTTON_TOP), (x1 - 2, BUTTON_BOTTOM), (x0 - 2, BUTTON_BOTTOM)], "W")
    c.text(END_X[0] + 1, BUTTON_TOP + 3, "END", "K", scale=2, sy=1)


def tree(c, x, trunk_w, top, crown_r):
    c.rect(x - trunk_w // 2, top, x + trunk_w // 2, 146, "K")
    c.ellipse(x, top, crown_r, crown_r * 0.8, "K")
    c.ellipse(x - crown_r * 0.6, top + crown_r * 0.3, crown_r * 0.7, crown_r * 0.6, "K")
    c.ellipse(x + crown_r * 0.6, top + crown_r * 0.4, crown_r * 0.7, crown_r * 0.6, "K")


# ---- the title

TITLE = "CATWIZ"
TITLE_SX, TITLE_SY = 6, 4          # each font dot is 6 px wide (even: clean white), 4 rows tall
TITLE_Y = 30


def title_letters():
    # where each lit pixel of the big letters is: a set of (x, y). The letters bob on a wave
    # (a forward lean was tried: its 1-px steps break up into notches on NTSC), and the I
    # wears a hat
    lit = set()
    step = 6 * TITLE_SX + 2
    width = len(TITLE) * step - 2 - TITLE_SX
    x0 = (280 - width) // 2
    for i, ch in enumerate(TITLE):
        glyph = FONT[ch]
        lx = x0 + i * step
        ly = TITLE_Y + round(5 * math.sin(i * 0.8 + 0.4))
        for gy, row in enumerate(glyph):
            for gx, bit in enumerate(row):
                if bit != "#":
                    continue
                for py in range(TITLE_SY):
                    y = ly + gy * TITLE_SY + py
                    for px in range(TITLE_SX):
                        lit.add((lx + gx * TITLE_SX + px, y))
        if ch == "I":
            lit |= little_hat(lx + 5 * TITLE_SX // 2, ly - 6)
    return lit


def little_hat(x, y):
    # a small crooked witch hat perched on the I, brim at y: lit like the letters, so it glows
    c = Canvas(".")
    ang = math.radians(-18)

    def turn(pts):
        ca, sa = math.cos(ang), math.sin(ang)
        return [(x + px * ca - py * sa, y + px * sa + py * ca) for px, py in pts]

    c.poly(turn([(-13, 0), (13, 0), (13, 3), (-13, 3)]), "W")       # brim
    c.poly(turn([(-7, 0), (7, 0), (1, -17), (-1, -17)]), "W")       # cone
    return {(px, py) for py in range(192) for px in range(280) if c.px[py][px] != "."}


def glow_distance(lit, reach):
    # the distance from every pixel near the letters to the closest lit one
    dist = {}
    for x, y in lit:
        for dy in range(-reach, reach + 1):
            for dx in range(-reach, reach + 1):
                d = math.sqrt(dx * dx + dy * dy)
                if d > reach:
                    continue
                key = (x + dx, y + dy)
                if d < dist.get(key, 99):
                    dist[key] = d
    return dist


def title(step):
    # step 0 to 3: the glow round the letters, from faint to full
    c = Canvas("K")
    clouds(c)
    moon(c, 138, 116, 46)
    hills(c)
    lit = title_letters()
    reach = (3, 5, 7, 9)[step]
    strength = (5, 8, 11, 14)[step]
    for (x, y), d in glow_distance(lit, reach).items():
        if (x, y) in lit or not (0 <= x < 280 and 0 <= y < 192):
            continue
        if d < 1.5:
            c.set(x, y, "K")              # a black rim keeps the letters crisp
            continue
        # closer pixels glow more: a bayer threshold falling off with distance, in pairs
        level = strength * (1 - (d - 1.5) / (reach - 0.5))
        if BAYER[y % 4][(x // 2) % 4] < level:
            c.set(x, y, "W" if d < 2.5 and step >= 2 else "O")
    for x, y in lit:
        c.set(x, y, "W")
    cat_card = Canvas(".")
    hero.cat(cat_card, 136, 160, "happy")
    cat_card.outline("K", inside=lambda col, x, y: col != ".", t=1)
    for y in range(192):
        for x in range(280):
            if cat_card.px[y][x] != ".":
                c.px[y][x] = cat_card.px[y][x]
    text = "PRESS RETURN"
    tw = len(text) * 12 - 2
    c.text((280 - tw) // 2, 180, text, "W", 2, 1)
    return c


def clouds(c):
    # dark night clouds: puffy banks of blue, dense along their tops and thinning underneath,
    # on a black sky with a few stars
    for sx, sy in ((14, 8), (40, 120), (70, 70), (102, 140), (186, 96), (214, 14), (250, 128),
                   (266, 64), (8, 88), (150, 76)):
        c.rect(sx, sy, sx + 2, sy + 1, "W")
    banks = [(0, 18, 70), (150, 6, 90), (60, 78, 80), (196, 70, 84), (-20, 128, 90), (210, 140, 80)]
    for bx, by, bw in banks:
        puffs = [(bx + i * bw / 5, by + 6 * math.sin(i * 2.1 + bx), bw / 6 + 4 * math.sin(i * 1.3 + by))
                 for i in range(6)]
        for y in range(max(0, int(by - bw / 4)), min(192, int(by + bw / 5))):
            for x in range(max(0, int(bx - 10)), min(280, int(bx + bw + 10))):
                inside = any(((x - px) / (r * 1.6)) ** 2 + ((y - py) / r) ** 2 <= 1 for px, py, r in puffs)
                if not inside:
                    continue
                top = min(py - r for px, py, r in puffs if abs(x - px) < r * 1.6)
                depth = (y - top) / (bw / 4)
                level = 9 - 8 * depth
                if BAYER[y % 4][(x // 2) % 4] < level:
                    c.set(x, y, "B")


def moon(c, x, y, r):
    # a big pale moon for the cat to stand against: white, grey seas in pixel pairs
    c.ellipse(x, y, r + 2, r + 1, "K")
    c.ellipse(x, y, r, r - 1, "W")
    for sx, sy, sr in ((-0.45, -0.35, 0.22), (0.35, -0.1, 0.3), (-0.1, 0.45, 0.18)):
        ax, ay, rr = x + sx * r, y + sy * r, sr * r
        c.grey(int(ax - rr), int(ay - rr), int(ax + rr) + 1, int(ay + rr) + 1,
               lambda px, py, ax=ax, ay=ay, rr=rr: ((px - ax) / rr) ** 2 + ((py - ay) / rr) ** 2 <= 1)


def hills(c):
    # the forest line at the bottom, black against the clouds and the moon's foot
    for x in range(280):
        top = 162 + int(4 * math.sin(x * 0.04) + 3 * math.sin(x * 0.13))
        for y in range(top, 192):
            c.set(x, y, "K")
    for tx, h in ((16, 46), (40, 30), (62, 22), (222, 26), (244, 38), (266, 52)):
        c.poly([(tx - 10, 166), (tx + 10, 166), (tx, 166 - h)], "K")
        c.rect(tx - 1, 166 - h // 2, tx + 1, 168, "K")
