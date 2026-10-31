# the fight's hud on the 140 x 192 picture: hit point and intent badges, the target marker,
# and the tray (rows 124-159): five dice cards, the picked one lifted and lit, the re-roll
# button, the mana stars and END. The 40-column text goes under it (fonts.text40).
#
# the tray is black in every zone (black is clean in NTSC and frames the stage); the cards
# are white paper with ink pictures (icons.py), so they read the same by day and by night.
# U holds the few colours a zone may change: the focus colour, the button, the badges.

import math

from canvas import ASPECT, Canvas
from dhgr import BLACK, WHITE, YELLOW, PINK, MAGENTA, GREY, LBLUE, ORANGE
from fonts import text3, text3_w
import icons

TRAY_TOP = 124
TEXT_TOP = 160
# each card owns 5 byte columns (17.5 pixels; slot n is columns 5n to 5n + 4) and never reaches
# out of them, so the game lifts a picked card by moving its columns' bytes up (battle/tray.tsp)
SLOT_COLS = 5
CARD_CX = tuple(8.75 + 17.5 * n for n in range(5))
CARD_TILT = (-5, 3, -2, 4, -4)
CARD_CY = 142
CARD_HW, CARD_HH = 7.5, 15          # half width in pixels, half height in rows
LIFT = 5
GLOW_ROWS = 2                       # the picked card's glow: a bar under it, its middle 3 columns

U_DAY = dict(focus=YELLOW, button=MAGENTA, button_hi=PINK, badge=BLACK, badge_ink=WHITE,
             heart=PINK, sword=WHITE, shield=LBLUE, mana=YELLOW, mana_off=GREY, card=WHITE,
             card_ink=BLACK, rim=GREY)
U_NIGHT = dict(U_DAY)

HEART = ["#.#", "###", "###", ".#."]
SWORD = ["..#", ".#.", "##.", "#.."]
SHIELD = ["###", "###", "###", ".#."]
STAR = ["..#..", ".###.", "#####", ".###.", ".#.#.", "#...#"]


def pill(c, x0, y0, x1, y1, fill, rim=None):
    # a rounded box: the corner pixels of the top and bottom rows cut away
    if rim is not None:
        pill(c, x0 - 1, y0 - 1, x1 + 1, y1 + 1, rim)
    for y in range(y0, y1):
        inset = 1 if y in (y0, y1 - 1) else 0
        c.rect(x0 + inset, y, x1 - inset, y + 1, fill)


def badge(c, U, cx, top, icon, icon_col, s, rim=None):
    # an icon and a number in a black pill, 9 rows tall, centred on cx
    iw = len(icon[0])
    w = iw + 1 + text3_w(s) + 4
    x0 = int(round(cx - w / 2))
    pill(c, x0, top, x0 + w, top + 9, U["badge"], rim)
    c.stamp(x0 + 2, top + 2, icon, {"#": icon_col})
    text3(c, x0 + 3 + iw, top + 2, s, U["badge_ink"])
    return x0, x0 + w


def marker(c, U, cx, y):
    # the target: a fat arrow pointing down, outlined
    m = Canvas()
    m.poly([(cx - 3.5, y), (cx + 3.5, y), (cx, y + 6)], U["focus"])
    m.rect(int(cx) - 1, y - 5, int(cx) + 1, y, U["focus"])
    m.outline(BLACK, 1, 1)
    c.paste(m)


def card_poly(cx, cy, deg, hw, hh):
    # a rectangle turned in visual space (x in rows), back on wide pixels
    a = math.radians(deg)
    ca, sa = math.cos(a), math.sin(a)
    pts = []
    for u, v in ((-hw * ASPECT, -hh), (hw * ASPECT, -hh), (hw * ASPECT, hh), (-hw * ASPECT, hh)):
        pts.append((cx + (u * ca - v * sa) / ASPECT, cy + u * sa + v * ca))
    return pts


def card(c, U, cx, cy, deg, icon, caption, picked=False):
    # a white card on its black outline; picked: lifted, a glow bar under it (as the game makes
    # it: the card's columns moved up LIFT rows, the bar filled into the rows it left)
    if picked:
        bottom = int(round(cy + LIFT + CARD_HH)) + 1
        col0 = int((cx - 8.75) / 17.5 + 0.5) * SLOT_COLS + 1
        x0, x1 = int(col0 * 3.5 + 0.5), int((col0 + 3) * 3.5)
        c.rect(x0, bottom - GLOW_ROWS, x1, bottom, U["focus"])
    c.poly(card_poly(cx, cy, deg, CARD_HW + 1, CARD_HH + 1), BLACK)
    c.poly(card_poly(cx, cy, deg, CARD_HW, CARD_HH), U["card"])
    icons.draw(c, int(round(cx)) - 5, int(round(cy)) - 13, icon)
    # the number at the card's foot
    w = text3_w(caption)
    x = int(round(cx - w / 2))
    text3(c, x, int(round(cy)) + 6, caption, U["card_ink"])


def tray(c, U, hand, picked=None, rerolls=2, mana=2):
    # hand: five (icon name, caption) pairs
    c.rect(0, TRAY_TOP, 140, TEXT_TOP, BLACK)
    for i, ((icon, cap), cx, deg) in enumerate(zip(hand, CARD_CX, CARD_TILT)):
        sel = i == picked
        cy = CARD_CY - (LIFT if sel else 0)
        card(c, U, cx, cy, deg, icon, cap, sel)
    # the re-roll button: a die and how many re-rolls are left
    rx, ry = 92, 128
    pill(c, rx, ry, rx + 7, ry + 12, WHITE)
    for px_, py_ in ((rx + 1, ry + 2), (rx + 5, ry + 2), (rx + 3, ry + 5), (rx + 1, ry + 8), (rx + 5, ry + 8)):
        c.rect(px_, py_, px_ + 1, py_ + 2, BLACK)
    text3(c, rx + 9, ry + 4, "X%d" % rerolls, WHITE)
    # mana: stars, held ones lit
    for k in range(5):
        c.stamp(109 + k * 6, ry + 3, STAR, {"#": U["mana"] if k < mana else U["mana_off"]})
    # END
    bx0, bx1, by0, by1 = 92, 137, 144, 156
    pill(c, bx0, by0, bx1, by1, U["button"], WHITE)
    c.hline(bx0 + 2, bx1 - 2, by0 + 1, U["button_hi"])
    s = "END TURN"
    text3(c, (bx0 + bx1 - text3_w(s)) // 2, by0 + 4, s, WHITE)
