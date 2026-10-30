# the hud's data for the game: the tray's card shapes (a white span per row for each slot's
# tilted card; the picked card upright, lifted, in three rectangles), the twelve card
# pictures as pixels, the 3 x 5 hud font with its icons, and the 35-column font. The game
# draws the hud itself from these (game/draw/pix.tsp and game/battle/tray.tsp), the same
# shapes hud.py draws for the previews.

import fonts
import hud
import icons
from canvas import Canvas
from dhgr import BLACK, WHITE, YELLOW, PINK, MAGENTA, GREY, LBLUE, MBLUE, BROWN, ORANGE, PURPLE, AQUA

TRAY_TOP, TRAY_BOTTOM = 118, hud.TEXT_TOP   # from the stage's black gutter: a picked card rises into it
CARD_CX = list(hud.CARD_CX) + [95]       # the reward's sixth slot where the buttons are
CARD_TILT = list(hud.CARD_TILT) + [3]
PICK_LIFT = hud.LIFT


def spans(c, col):
    # per tray row, the first and last + 1 pixel of colour col (0, 0 for none)
    out = []
    for y in range(TRAY_TOP, TRAY_BOTTOM):
        xs = [x for x in range(140) if c.px[y][x] == col]
        out.append((min(xs), max(xs) + 1) if xs else (0, 0))
    return out


def card_spans(slot):
    # the white of the slot's tilted card, as hud.card draws it
    c = Canvas()
    c.poly(hud.card_poly(CARD_CX[slot], hud.CARD_CY, CARD_TILT[slot], hud.CARD_HW, hud.CARD_HH), WHITE)
    return spans(c, WHITE)


def rect_of(c, col):
    xs = [x for y in range(192) for x in range(140) if c.px[y][x] == col]
    ys = [y for y in range(192) for x in range(140) if c.px[y][x] == col]
    return min(xs), max(xs) + 1, min(ys), max(ys) + 1


def picked_rects(slot):
    # the picked card: the focus rim, the black edge, the white card; each (x0, x1, y0, y1)
    cx, cy = CARD_CX[slot], hud.CARD_CY - PICK_LIFT
    out = []
    for hw, hh, col in ((hud.CARD_HW + 2, hud.CARD_HH + 3, YELLOW), (hud.CARD_HW + 1, hud.CARD_HH + 1, BLACK),
                        (hud.CARD_HW, hud.CARD_HH, WHITE)):
        c = Canvas()
        c.poly(hud.card_poly(cx, cy, 0, hw, hh), 15 if col == BLACK else col)
        x0, x1, y0, y1 = rect_of(c, 15 if col == BLACK else col)
        out.append((x0, x1, max(y0, TRAY_TOP), min(y1, TRAY_BOTTOM), col))
    return out


def icon_at(slot, picked):
    cx = CARD_CX[slot]
    cy = hud.CARD_CY - (PICK_LIFT if picked else 0)
    return int(round(cx)) - 5, int(round(cy)) - 13


def caption_y(picked):
    return int(round(hud.CARD_CY - (PICK_LIFT if picked else 0))) + 6


# the icons in the game's order (content/faces' TILE numbers): 11 x 15 pixels, '.' the card
ICON_ORDER = ["wand", "tuna", "fluff", "star", "book", "fleas", "wet", "hiss", "bath", "plus1",
              "times2", "lint"]


def icon_pixels(name):
    # 15 rows of 11 colour numbers, the card's white where the picture has none; as nibbles,
    # two pixels a byte (high first), 6 bytes a row
    out = bytearray()
    for row in icons.ICONS[name]:
        vals = [WHITE if ch == "." else icons.KEY[ch] for ch in row] + [WHITE]
        for i in range(0, 12, 2):
            out.append(vals[i] << 4 | vals[i + 1])
    return bytes(out)


# ---- the 3 x 5 hud font, and its icons (3 x 4 and the mana star 5 x 6): a glyph is its width,
# its colour (0: the ink it is drawn in), then rows of bits, bit 0 the leftmost pixel

HUD_ICONS = {
    # code: (rows, colour)
    "*": (hud.HEART, PINK),            # hit points
    "!": (hud.SWORD, WHITE),           # an attack
    "#": (hud.SHIELD, LBLUE),          # shield
    ",": (["#.#", ".#.", "###", "#.#"], BROWN),  # fleas
    "%": ([".#.", "###", "###", ".#."], MBLUE),  # wet
    "@": (["###", "..#", ".#.", "###"], PURPLE), # hissed (a Z)
    "<": ([".#.", "###", ".#.", "..."], PINK),   # cheered: hits harder
    ";": (["###", "###", "###", ".#."], PURPLE), # a ward pip
    "&": (["###", "#.#", "###", "..."], ORANGE), # in a box
    ">": (["#.#", ".#.", "#.#", "..."], AQUA),   # the next die doubled
    "^": ([".#.", ".#.", "###", ".#."], WHITE),  # a dive: a big hit
    "'": (hud.STAR, YELLOW),           # mana, lit
    "$": (hud.STAR, GREY),             # mana, not yet
}


def glyph_rows(ch):
    if ch in HUD_ICONS:
        rows, col = HUD_ICONS[ch]
        return rows, col
    return fonts.FONT3.get(ch, fonts.FONT3[" "]), 0


HUD_CODES = [chr(c) for c in range(32, 96)]   # ' ' to '_'


def hud_font():
    # per code from ' ': width, colour, then 6 rows of bits (rows past the glyph's are 0)
    out = bytearray()
    for ch in HUD_CODES:
        rows, col = glyph_rows(ch)
        w = len(rows[0])
        out += bytes([w, col])
        for r in range(6):
            bits = 0
            if r < len(rows):
                for i, b in enumerate(rows[r]):
                    if b == "#":
                        bits |= 1 << i
            out.append(bits)
    return bytes(out)


# ---- the 35-column font: 95 glyphs from ' ', 8 rows of 3 pixels: 3 bytes a glyph, row r's
# bits at 3r (bit 0 the leftmost pixel)

def font35():
    out = bytearray()
    for i in range(32, 127):
        g = fonts.F35.get(chr(i), [])
        rows = [(r + "...")[:3] for r in g] + ["..."] * (8 - len(g))
        v = 0
        for r, row in enumerate(rows[:8]):
            for k, ch in enumerate(row):
                if ch == "#":
                    v |= 1 << (r * 3 + k)
        out += bytes([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF])
    return bytes(out)


def font40():
    # the 40-column font, for switching the text to it: 8 rows of (aux, main) a glyph
    out = bytearray()
    for i in range(32, 127):
        for a, m in fonts.cell_bytes(chr(i)):
            out += bytes([a, m])
    return bytes(out)
