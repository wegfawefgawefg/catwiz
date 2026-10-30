# hi-res mockups that are exact: draw at 280x192 in the six hi-res colours, convert to real
# HGR bytes on the 7-pixel byte grid, and render them through Tisple's own Apple IIe.
#
# colours: K black, W white, V violet, G green, B blue, O orange.
# rules of the hardware this follows:
# - 7 pixels per byte, bit 0 leftmost; bit 7 picks the byte's palette: 0 violet/green,
#   1 blue/orange. a byte cannot hold both palettes, so plan colour edges on byte columns.
# - a lone lit pixel shows violet or blue on even x, green or orange on odd x; two lit
#   pixels side by side show white. a solid colour is every other pixel lit.

import os
import re
import subprocess

W, H = 280, 192
TISPLE = os.environ.get("TISPLE", os.path.expanduser("~/Coding/LangDev/tisple/build/tisple"))
FONT_CPP = os.path.expanduser("~/Coding/LangDev/tisple/src/machine/font.cpp")
PALETTE_1 = {"B", "O"}
COLOURED = {"V", "G", "B", "O"}


class Canvas:
    def __init__(self, fill="K"):
        self.px = [[fill] * W for _ in range(H)]

    def set(self, x, y, c):
        if 0 <= x < W and 0 <= y < H:
            self.px[y][x] = c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(max(0, y0), min(H, y1)):
            for x in range(max(0, x0), min(W, x1)):
                self.px[y][x] = c

    def frame(self, x0, y0, x1, y1, c, t=1):
        self.rect(x0, y0, x1, y0 + t, c)
        self.rect(x0, y1 - t, x1, y1, c)
        self.rect(x0, y0, x0 + t, y1, c)
        self.rect(x1 - t, y0, x1, y1, c)

    def poly(self, pts, c):
        # scanline fill of a simple polygon
        ys = [p[1] for p in pts]
        for y in range(max(0, int(min(ys))), min(H, int(max(ys)) + 1)):
            xs = []
            for i in range(len(pts)):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % len(pts)]
                if (ya <= y < yb) or (yb <= y < ya):
                    xs.append(xa + (y - ya) * (xb - xa) / (yb - ya))
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                for x in range(int(round(xs[i])), int(round(xs[i + 1]))):
                    self.set(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(int(cy - ry), int(cy + ry) + 1):
            for x in range(int(cx - rx), int(cx + rx) + 1):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    self.set(x, y, c)

    def line(self, x0, y0, x1, y1, c, t=1):
        n = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for i in range(n + 1):
            x = x0 + (x1 - x0) * i / n
            y = y0 + (y1 - y0) * i / n
            self.rect(int(x), int(y), int(x) + t, int(y) + t, c)

    def dither(self, x0, y0, x1, y1, c, keep=None):
        # every other row of a colour region dropped to black: a darker version of it
        for y in range(max(0, y0), min(H, y1)):
            if y % 2 == 0:
                continue
            for x in range(max(0, x0), min(W, x1)):
                if keep is None or self.px[y][x] == keep:
                    self.px[y][x] = c

    def text(self, x, y, s, c, scale=1, sy=None):
        # scale widens strokes; on hi-res only 2-pixel-wide strokes show as clean white
        sy = scale if sy is None else sy
        for i, ch in enumerate(s):
            glyph = GLYPHS.get(ch) or FONT.get(ch, FONT.get("?"))
            for gy, row in enumerate(glyph):
                for gx, bit in enumerate(row):
                    if bit == "#":
                        self.rect(x + (i * 6 + gx) * scale, y + gy * sy,
                                  x + (i * 6 + gx + 1) * scale, y + (gy + 1) * sy, c)

    def checker(self, x0, y0, x1, y1, c):
        # a staggered quarter-lit pattern: a darker shade of c without stripes
        for y in range(max(0, y0), min(H, y1)):
            for x in range(max(0, x0), min(W, x1)):
                lit = (x + 2 * (y % 2)) % 4 in (0, 1)
                self.px[y][x] = c if lit else "K"

    def stamp(self, x, y, rows, colours):
        # small bitmap: rows of characters, each mapped through colours ('.' is transparent)
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch != ".":
                    self.set(x + dx, y + dy, colours.get(ch, ch))

    def grey(self, x0, y0, x1, y1, mask=None):
        # grey as a white/black dither in pixel pairs; only where mask(x, y) is true
        for y in range(max(0, y0), min(H, y1)):
            for x in range(max(0, x0), min(W, x1)):
                if mask is None or mask(x, y):
                    self.px[y][x] = "W" if ((x // 2) + y) % 2 == 0 else "K"

    def outline(self, colour="K", inside=None, t=1):
        # a t-pixel border in colour around every pixel inside(c) is true for, on pixels
        # where it is false: the sticker look
        src = [row[:] for row in self.px]
        for y in range(H):
            for x in range(W):
                if inside(src[y][x], x, y):
                    continue
                for dy in range(-t, t + 1):
                    for dx in range(-t, t + 1):
                        yy, xx = y + dy, x + dx
                        if 0 <= yy < H and 0 <= xx < W and inside(src[yy][xx], xx, yy):
                            self.px[y][x] = colour
                            break
                    else:
                        continue
                    break

    def poly_rot(self, cx, cy, w, h, deg, c):
        import math
        a = math.radians(deg)
        pts = []
        for px, py in ((-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)):
            pts.append((cx + px * math.cos(a) - py * math.sin(a), cy + px * math.sin(a) + py * math.cos(a)))
        self.poly(pts, c)


def load_font():
    text = open(FONT_CPP).read()
    rows = re.findall(r'\{((?:"[.#]{5}",?\s*){7})\},\s*//\s*(.+)', text)
    font = {}
    for body, name in rows:
        glyph = re.findall(r'"([.#]{5})"', body)
        name = name.strip()
        ch = {"space": " "}.get(name, name[0] if len(name) >= 1 else " ")
        font[ch] = glyph
    return font


FONT = load_font()

# extra glyphs for the HUD: heart, resist swirl, sword
GLYPHS = {
    "*": [".#.#.", "#####", "#####", "#####", ".###.", "..#..", "....."],
    "@": [".###.", "#...#", "#.#.#", "#.###", "#....", ".###.", "....."],
    "!": ["....#", "...#.", "#.#..", ".#...", "#.#..", ".....", "....."],
}


def text_width(s, scale=1):
    return len(s) * 6 * scale - scale


def row_address(y):
    return 0x2000 + (y & 7) * 0x400 + ((y >> 3) & 7) * 0x80 + (y >> 6) * 0x28


def to_hgr(canvas, default_high=False):
    # default_high: the palette of bytes with no colour in them, so white runs line up with
    # orange and blue neighbours (bit 7 shifts a byte's dots half a pixel)
    page = bytearray(0x2000)
    for y in range(H):
        base = row_address(y) - 0x2000
        for col in range(40):
            cells = canvas.px[y][col * 7:col * 7 + 7]
            coloured = [c for c in cells if c in COLOURED]
            high = sum(c in PALETTE_1 for c in coloured) * 2 > len(coloured)
            if not coloured:
                high = default_high
            byte = 0x80 if high else 0
            for bit, c in enumerate(cells):
                x = col * 7 + bit
                lit = c == "W" or (c in ("V", "B") and x % 2 == 0) or (c in ("G", "O") and x % 2 == 1)
                if lit:
                    byte |= 1 << bit
            page[base + col] = byte
    return bytes(page)


# a stub at $1F00 that shows hi-res page 1, full screen, and waits; the picture follows at $2000
STUB = bytes([0xAD, 0x50, 0xC0, 0xAD, 0x52, 0xC0, 0xAD, 0x54, 0xC0, 0xAD, 0x57, 0xC0, 0x4C, 0x0C, 0x1F])


def render(canvas, out_png, look="color", default_high=False):
    page = to_hgr(canvas, default_high)
    blob = STUB + bytes(0x100 - len(STUB)) + page
    bin_path = out_png[:-4] + ".bin"
    open(bin_path, "wb").write(blob)
    args = [TISPLE, "machine", bin_path, "--origin", "0x1F00", "--frames", "2", "--screenshot", out_png]
    if look != "color":
        args.append("--" + look)
    subprocess.run(args, check=True, capture_output=True)
    return page
