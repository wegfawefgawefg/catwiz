# the game's sprites: every frame of the fighters lit for a zone, and the small shared ones
# (the target marker, the bolt, the poof, the floating digits), as lib/dhgr runs.
#
# a sprite is cut on the 7-pixel grid (dhgr.cut) and split into its two memories' halves: the
# aux bytes (even ones of each row) and the main bytes (odd ones). Each half is stored as runs
# (lib/dhgr's runs, Tisple docs/dhgr.md): per row, control bytes up to a 0: 1-63 skip that many
# bytes, $40 + n then n picture bytes (opaque), $80 + n then n picture bytes and their n masks.
# A kind's frames go in one block per half; the game unpacks a fight's kinds into its sprite
# buffers (aux halves in aux memory, main halves in the aux language card).
#
# The fighters' frames are solid (2026-10-31, the midnight decision): the figure flattened onto
# black over its whole box, so each row is only opaque runs, no skips and no masks. The stage
# is black wherever a look can go (lanes.py), so one copy of a frame erases the last pose and
# draws the new one. Each fighter kind also has a flash frame: the white silhouette of its hurt
# frame (its idle one when it has none), solid, in the hurt frame's box, for the hit flash
# (a masked frame drawn all white would whiten a solid frame's whole box). The small sprites
# (marker, bolt, poofs, digits, the title's glow) stay masked.

import dhgr
import light
import screen
import cat
import foes
from canvas import Canvas
from dhgr import BLACK, WHITE, YELLOW, GREY, LBLUE, PINK, ORANGE

KINDS = ["cat", "puffcap", "sporelet", "nightflap", "misc"]

# what the engine asks each kind for, and the frame that answers: (role, frame)
ROLES = {
    "cat": [("idle", "idle"), ("attack", "attack"), ("hurt", "hit"), ("happy", "meow"),
            ("surprised", "ears"), ("flap", None), ("flash", "flash")],
    "puffcap": [("idle", "idle"), ("attack", "attack"), ("hurt", "hurt"), ("happy", None),
                ("surprised", None), ("flap", None), ("flash", "flash")],
    "sporelet": [("idle", "idle"), ("attack", "attack"), ("hurt", "hurt"), ("happy", None),
                 ("surprised", None), ("flap", None), ("flash", "flash")],
    "nightflap": [("idle", "idle"), ("attack", "attack"), ("hurt", "hurt"), ("happy", None),
                  ("surprised", None), ("flap", "flap"), ("flash", "flash")],
}
ROLE_NAMES = [r for r, _ in ROLES["cat"]]


def frames(kind):
    # the kind's drawn frames (the flash is made from one of them, after them in the tables)
    return cat.FRAMES if kind == "cat" else foes.FRAMES[kind]


def hurt_frame(kind):
    # the frame the flash is the silhouette of: the kind's hurt one, else its idle one
    for role, frame in ROLES[kind]:
        if role == "hurt" and frame:
            return frame
    return frames(kind)[0]


def runs_half(pic, mask, bw, h, half):
    # one memory's bytes of a cut sprite as runs (half 0: aux, the even bytes; 1: main)
    out = bytearray()
    for y in range(h):
        row = [(pic[y * bw + k], mask[y * bw + k]) for k in range(half, bw, 2)]
        end = len(row)
        while end > 0 and row[end - 1][1] == 0x7F:
            end -= 1
        x = 0
        while x < end:
            m = row[x][1]
            kind = "t" if m == 0x7F else "o" if m == 0 else "p"
            n = 1
            while x + n < end and n < 63:
                mn = row[x + n][1]
                kn = "t" if mn == 0x7F else "o" if mn == 0 else "p"
                if kn != kind:
                    break
                n += 1
            if kind == "t":
                out.append(n)
            elif kind == "o":
                out.append(0x40 + n)
                out += bytes(p for p, _ in row[x:x + n])
            else:
                out.append(0x80 + n)
                out += bytes(p for p, _ in row[x:x + n])
                out += bytes(mm for _, mm in row[x:x + n])
            x += n
        out.append(0)
    return bytes(out)


class Sprite:
    # one frame: its box on the screen and its two halves as runs; solid: flattened onto black
    # over the whole box (every byte opaque)
    def __init__(self, name, canvas, box=None, solid=False):
        box = box or canvas.bbox()
        s = dhgr.cut(name, canvas.px, box)
        bw = s.bytes_wide()
        if solid:
            s.mask = [0] * len(s.mask)    # the clear pixels' picture bits are 0: black
        self.solid = solid
        self.name = name
        self.col = s.x0 // 7 * 2     # byte column of its left edge
        self.top = s.y0
        self.cols = bw // 2          # byte columns wide
        self.rows = s.h
        self.aux = runs_half(s.pic, s.mask, bw, s.h, 0)
        self.main = runs_half(s.pic, s.mask, bw, s.h, 1)


def fighter(kind, frame, zone):
    return Sprite("%s_%s" % (kind, frame), light.lit(screen.figure(kind, frame), zone), solid=True)


def flash(kind):
    # the white silhouette of the kind's hurt frame, outline and all, on black in its box
    c = screen.figure(kind, hurt_frame(kind))
    for row in c.px:
        for x, v in enumerate(row):
            if v is not None:
                row[x] = WHITE
    return Sprite("%s_flash" % kind, c, solid=True)


# ---- the shared small sprites, drawn here

DIGITS = {
    "0": [".###.", "##.##", "#...#", "#...#", "#...#", "#...#", "#...#", "##.##", ".###."],
    "1": ["..#..", ".##..", "###..", "..#..", "..#..", "..#..", "..#..", "..#..", "#####"],
    "2": [".###.", "##.##", "....#", "...##", "..##.", ".##..", "##...", "#....", "#####"],
    "3": ["####.", "...##", "....#", "...##", ".###.", "...##", "....#", "...##", "####."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#..#.", "#####", "...#.", "...#.", "...#."],
    "5": ["#####", "#....", "#....", "####.", "...##", "....#", "....#", "#..##", ".###."],
    "6": ["..##.", ".##..", "##...", "####.", "##.##", "#...#", "#...#", "##.##", ".###."],
    "7": ["#####", "....#", "...##", "...#.", "..##.", "..#..", ".##..", ".#...", ".#..."],
    "8": [".###.", "##.##", "#...#", "##.##", ".###.", "##.##", "#...#", "##.##", ".###."],
    "9": [".###.", "##.##", "#...#", "##.##", ".####", "....#", "...##", "..##.", ".##.."],
    "+": [".....", ".....", "..#..", "..#..", "#####", "..#..", "..#..", ".....", "....."],
}


def digit(ch):
    # a floating number's digit: white, a black outline, one 7-pixel step wide
    c = Canvas()
    c.stamp(1, 1, DIGITS[ch], {"#": WHITE})
    c.outline(BLACK, 1, 1)
    return Sprite("digit_" + ("plus" if ch == "+" else ch), c, (0, 0, 7, 11))


def marker():
    # the target arrow, its box two steps wide from column 0
    import hud
    c = Canvas()
    hud.marker(c, hud.U_DAY, 7, 6)
    return Sprite("marker", c)


def bolt():
    # the wand's bolt: a round spark, a white heart in yellow, outlined
    c = Canvas()
    c.ellipse(3.5, 5, 2.6, 4.6, YELLOW)
    c.ellipse(3.0, 4.5, 1.2, 2.2, WHITE)
    c.outline(BLACK, 1, 1)
    return Sprite("bolt", c)


def poof(k):
    # a beaten enemy puffing away: a cloud, then a thinner one
    c = Canvas()
    if k == 0:
        for x, y, r in ((7, 10, 6), (12, 7, 5), (4, 6, 4), (10, 13, 5)):
            c.ellipse(x, y, r / 1.83 * 1.6, r, WHITE)
        c.outline(GREY, 1, 1)
    else:
        for x, y, r in ((3, 4, 3), (12, 3, 3), (7, 12, 3), (2, 13, 2), (13, 12, 2)):
            c.ellipse(x, y, r / 1.83 * 1.6, r, LBLUE)
    return Sprite("poof%d" % k, c)


def misc():
    out = [marker(), bolt(), poof(0), poof(1)]
    out += [digit(ch) for ch in "0123456789+"]
    return out
