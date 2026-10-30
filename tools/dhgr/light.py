# the zones' lighting on the one set of fighter sprites. A sprite is drawn in materials
# (cat.py, foes.py); a zone is a table from material to colour (the palette swap) and a list
# of rims (the light by code). Both are cheap enough for the game to do when a fight loads:
# the sprites are stored once, as material numbers, and turned into screen bytes for the
# fight's zone (export.py).
#
#   day    fights 1-4: warm sun from the upper left, no rims, the fur's sheen a dark blue
#   dusk   fights 5-7: the low sun's orange on the left edge of every figure, a magenta
#          bounce on the right, pinker whites
#   night  fights 8-10 and the boss: moonlight (light blue) on the left and top edges, the
#          glowing mushrooms' pink on the right edge, the caps themselves glowing
#
# a rim recolours the outermost pixel of a figure on one side, row by row (that pixel is the
# black outline), or on the top, column by column: a line of light where the outline was.

from canvas import Canvas
import dhgr
from dhgr import (BLACK, MAGENTA, DBLUE, PURPLE, DGREEN, GREY, MBLUE, LBLUE, BROWN, ORANGE,
                  PINK, GREEN, YELLOW, AQUA, WHITE)

# every material and its day colour
DAY = {
    # everyone
    "ink": BLACK, "eye": BLACK, "shine": WHITE, "mouth": PINK, "blush": PINK,
    # the cat
    "fur": BLACK, "sheen": DBLUE, "tip": WHITE, "robe": DBLUE, "robe_hi": MBLUE, "robe_star": YELLOW, "trim": PURPLE, "paw": WHITE,
    "face": WHITE, "face_sh": LBLUE, "nose": PINK, "ear_in": PINK, "hat": BLACK, "band": MAGENTA,
    "band_hi": PINK, "star": YELLOW, "star_hi": WHITE, "wand": ORANGE,
    # puffcap
    "puff": PINK, "puff_sh": MAGENTA, "puff_hi": WHITE, "puff_spot": WHITE,
    # sporelet
    "spore": ORANGE, "spore_sh": BROWN, "spore_hi": YELLOW, "spore_spot": WHITE,
    # both mushrooms' stems
    "stem": WHITE, "stem_sh": LBLUE, "gill": PINK,
    # nightflap
    "bat": PURPLE, "bat_sh": DBLUE, "bat_hi": PINK, "wing": MAGENTA, "wing_sh": DBLUE,
    "bone": BLACK, "fang": WHITE, "bat_eye": YELLOW,
}

DUSK = dict(DAY)
DUSK.update({"face_sh": PINK, "sheen": MAGENTA, "stem_sh": PINK, "puff_hi": YELLOW,
             "spore_hi": YELLOW, "spot_sh": PINK, "wand": ORANGE})

NIGHT = dict(DAY)
NIGHT.update({"sheen": BLACK, "trim": BLACK, "robe": BLACK, "robe_hi": BLACK, "band": PURPLE, "wand": GREY,
              "puff_hi": WHITE, "spore": AQUA, "spore_sh": DBLUE, "spore_hi": WHITE,
              "spore_spot": WHITE, "bat": BLACK, "bat_sh": BLACK, "wing": DBLUE, "wing_sh": BLACK,
              "bat_hi": PURPLE})

# rims: (side, colour, first row from the figure's top as a share of its height); side is
# "left", "right" or "top" (the top edge, on the figure's left half only)
RIMS = {
    "day": [],
    "dusk": [("left", ORANGE, 0.0), ("top", ORANGE, 0.0), ("right", MAGENTA, 0.45)],
    "night": [("left", LBLUE, 0.35), ("top", LBLUE, 0.0), ("right", PINK, 0.5)],
}
ZONES = {"day": DAY, "dusk": DUSK, "night": NIGHT}


def sheen(c, mat="fur", into="sheen"):
    # the lit edge inside a dark figure: material pixels just inside the outline, above or to
    # the left of it (the sun's side), become `into`. Done on the drawing, so it is material.
    src = [row[:] for row in c.px]
    for y in range(1, dhgr.H - 1):
        for x in range(1, dhgr.W - 1):
            if src[y][x] != mat:
                continue
            if src[y][x - 1] == "ink" or src[y - 1][x] == "ink":
                c.px[y][x] = into


def colour(c, zone):
    # the palette swap: materials to colours
    table = ZONES[zone]
    out = Canvas()
    for y in range(dhgr.H):
        for x in range(dhgr.W):
            v = c.px[y][x]
            if v is not None:
                out.px[y][x] = table[v] if isinstance(v, str) else v
    return out


def rims(c, zone, src=None):
    # the light by code on a coloured figure: the outermost pixels on each rim's side
    src = src or c
    box = src.bbox()
    if box is None:
        return c
    x0, y0, x1, y1 = box
    for side, col, start in RIMS[zone]:
        if side in ("left", "right"):
            for y in range(int(y0 + (y1 - y0) * start), y1):
                xs = [x for x in range(x0, x1) if src.px[y][x] is not None]
                if xs:
                    x = xs[0] if side == "left" else xs[-1]
                    if c.px[y][x] == BLACK:
                        c.px[y][x] = col
        else:
            for x in range(x0, (x0 + x1) // 2 + 2):
                ys = [y for y in range(y0, y1) if src.px[y][x] is not None]
                if ys and c.px[ys[0]][x] == BLACK:
                    c.px[ys[0]][x] = col
    return c


def lit(c, zone):
    # a material drawing as the zone shows it
    return rims(colour(c, zone), zone)
