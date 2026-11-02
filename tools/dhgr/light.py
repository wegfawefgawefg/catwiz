# the zones' lighting on the one set of fighter sprites. A sprite is drawn in materials
# (cat.py, foes.py); a zone is a table from material to colour (the palette swap) and a list
# of rims (the light by code). Both are cheap enough for the game to do when a fight loads:
# the sprites are stored once, as material numbers, and turned into screen bytes for the
# fight's zone (export.py).
#
#   day    fights 1-4: the sun from the upper left, no rims: the fighters are the page's darks
#   dusk   fights 5-7: the low sun's orange on the left edge of every figure, a magenta
#          bounce on the right, pinker whites
#   night  the whole game since 2026-10-31 (midnight: the fighters stand on pure black):
#          moonlight (light blue) on the left edge and the whole top, the glowing mushrooms'
#          pink on the right edge from a fifth down, the caps themselves glowing. On black the
#          outline is gone, so the rims are the figure's edge: they go all the way round but
#          the feet
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
    "fur": BLACK, "sheen": DBLUE, "tip": WHITE, "robe": MBLUE, "robe_hi": MBLUE, "robe_star": WHITE, "trim": MAGENTA,
    "paw": WHITE,
    "face": WHITE, "face_sh": LBLUE, "nose": PINK, "ear_in": PINK, "hat": BLACK, "band": MAGENTA,
    "band_hi": PINK, "star": YELLOW, "star_hi": WHITE, "wand": YELLOW,
    # puffcap
    "puff": PINK, "puff_sh": MAGENTA, "puff_hi": WHITE, "puff_spot": WHITE,
    # sporelet
    "spore": ORANGE, "spore_sh": MAGENTA, "spore_hi": YELLOW, "spore_spot": WHITE,
    # both mushrooms' stems
    "stem": WHITE, "stem_sh": LBLUE, "gill": PINK,
    # the old shroom
    "old": PURPLE, "old_sh": DBLUE, "old_hi": PINK, "old_spot": WHITE, "moss": GREEN,
    "beard": GREY, "beard_sh": WHITE, "stick": ORANGE,
    # the squirrel
    "sq": ORANGE, "sq_sh": BROWN, "sq_hi": YELLOW, "tail": ORANGE, "tail_sh": BROWN, "tail_hi": YELLOW, "tail_tip": WHITE,
    "belly": WHITE, "belly_hi": WHITE, "acorn": YELLOW, "acorn_hi": WHITE, "cap": BROWN,
    # the possum
    "pos": GREY, "pos_sh": DBLUE, "pos_hi": WHITE, "pos_face": WHITE, "mask": GREY, "ptail": PINK,
    "paw_p": PINK, "tongue": PINK, "leaf": GREEN, "leaf_hi": AQUA,
    # the garden: the sprinkler, the lawnmower, the cucumber, the gnome, the mailman
    "spr": GREEN, "spr_hi": AQUA, "spr_sh": DGREEN, "spike": GREY, "brass": YELLOW, "brass_hi": WHITE,
    "water": LBLUE, "water_hi": WHITE,
    "mow": ORANGE, "mow_hi": YELLOW, "mow_sh": MAGENTA, "wheel": GREY, "hub": WHITE, "handle": GREY,
    "grip": PINK, "light": YELLOW, "eyewhite": WHITE, "teeth": WHITE, "blade": WHITE, "grass": GREEN, "grass_hi": AQUA,
    "smoke": GREY,
    "cuc": GREEN, "cuc_hi": AQUA, "cuc_bump": DGREEN, "cuc_end": YELLOW, "cuc_slice": AQUA,
    "cuc_seed": WHITE, "dust": GREY,
    "boot": GREY, "coat": LBLUE, "coat_hi": WHITE, "belt": BLACK, "buckle": YELLOW, "skin": PINK,
    "beard": WHITE, "gnose": PINK, "hat_g": ORANGE, "hat_hi": YELLOW, "rod": GREY, "line": LBLUE,
    "bobber": PINK, "hook": WHITE,
    "trousers": MBLUE, "shoe": GREY, "bag": ORANGE, "bag_hi": YELLOW, "parcel": YELLOW, "string": ORANGE,
    "uniform": LBLUE, "uniform_hi": WHITE, "shirt": WHITE, "button": YELLOW, "strap": BROWN,
    "skin_m": PINK, "skin_cross": ORANGE, "stamp_ink": MAGENTA, "stache": GREY, "nose_m": PINK, "mcap": MBLUE, "badge": YELLOW,
    "steam": WHITE,
    # the house: the dust bunny, the roomba, Hoover Jr., the vet, the big bath, the drain gremlin
    "dust_b": GREY, "dust_hi": WHITE, "dust_face": WHITE, "lint": PINK, "lint2": AQUA,
    "rmb": GREY, "rmb_sh": DBLUE, "rmb_side": MBLUE, "rmb_hi": WHITE, "bumper": LBLUE, "led": GREEN, "led_on": YELLOW,
    "screen": AQUA, "speed": WHITE, "spark": YELLOW,
    "hv_base": GREY, "hv_brush": YELLOW, "hv_bag": LBLUE, "hv_bag_hi": WHITE, "hv_bag_sh": MBLUE,
    "hv_stripe": WHITE, "hose": GREY, "nozzle": GREY, "hv_air": WHITE,
    "coat_v": WHITE, "coat_v_sh": LBLUE, "scrubs": AQUA, "trousers_v": AQUA, "pocket": LBLUE, "pen": PINK,
    "steth": GREY, "steth_hi": WHITE, "skin_v": PINK, "hair_v": ORANGE, "band_v": GREY, "mirror": WHITE,
    "glasses": LBLUE, "syringe": LBLUE, "needle_v": WHITE, "glove": AQUA, "snap": WHITE,
    "clipboard": ORANGE,
    "claw": YELLOW, "tub": LBLUE, "tub_hi": WHITE, "rim": WHITE, "suds": WHITE, "bubble": AQUA,
    "tap": YELLOW, "tap_eye": WHITE,
    "slime": GREEN, "slime_hi": AQUA, "chain": GREY, "plug": GREY, "gr_eye": YELLOW,
    # the Bulldog King and his pugs
    "dog": WHITE, "dog_hi": WHITE, "dog_jowl": WHITE, "dog_belly": LBLUE, "dog_ear": BROWN, "dog_nose": GREY,
    "red_eye": PINK, "drool": LBLUE, "zzz": LBLUE, "gold": YELLOW, "gold_hi": WHITE, "gem": PINK, "gem2": AQUA,
    "robe_k": PURPLE, "ermine": WHITE, "ermine_dot": BLACK, "velvet": MAGENTA, "velvet_hi": PINK,
    "cushion": PINK, "pug": ORANGE, "pug_mask": GREY,
    "brow": BLACK, "patch": ORANGE, "vein": MAGENTA, "mad": PINK, "mad_jowl": PINK, "fury_eye": MAGENTA,
    # nightflap
    "bat": PURPLE, "bat_sh": PURPLE, "bat_hi": PINK, "wing": BLACK, "wing_sh": BLACK,
    "bone": MAGENTA, "fang": WHITE, "bat_eye": WHITE,
}

DUSK = dict(DAY)
DUSK.update({"face_sh": PINK, "sheen": MAGENTA, "stem_sh": PINK, "puff_hi": YELLOW,
             "spore_hi": YELLOW, "spot_sh": PINK})

NIGHT = dict(DAY)
NIGHT.update({"sheen": BLACK, "trim": BLACK, "robe": BLACK, "robe_hi": BLACK, "robe_star": DBLUE,
              "band": PURPLE, "wand": GREY,
              "puff_hi": WHITE, "spore": AQUA, "spore_sh": DBLUE, "spore_hi": WHITE,
              "spore_spot": WHITE, "bat": BLACK, "bat_sh": BLACK, "bone": MBLUE, "bat_hi": PURPLE,
              "bat_eye": YELLOW})

# rims: (side, colour, first row from the figure's top as a share of its height); side is
# "left", "right", "top" (the top edge, on the figure's left half only) or "top_all" (the
# whole top edge)
RIMS = {
    "day": [],
    "dusk": [("left", ORANGE, 0.0), ("top", ORANGE, 0.0), ("right", MAGENTA, 0.45)],
    "night": [("left", LBLUE, 0.0), ("top_all", LBLUE, 0.0), ("right", PINK, 0.2)],
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
            for x in range(x0, x1 if side == "top_all" else (x0 + x1) // 2 + 2):
                ys = [y for y in range(y0, y1) if src.px[y][x] is not None]
                if ys and c.px[ys[0]][x] == BLACK:
                    c.px[ys[0]][x] = col
    return c


def lit(c, zone):
    # a material drawing as the zone shows it
    return rims(colour(c, zone), zone)
