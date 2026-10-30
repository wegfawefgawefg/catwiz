# a native double hi-res canvas: 140 x 192 wide pixels (one pixel = one 4-dot colour group),
# drawn directly at that size. None is clear (sprites) or black (screens).
#
# a pixel is about 1.83 rows wide on a 4:3 screen (4/140 of the width against 3/192 of the
# height), so round shapes take ASPECT: an ellipse that looks round has rx = ry / ASPECT.
# Every helper takes pixel x and row y.

import math

from dhgr import W, H

ASPECT = 1.83


class Canvas:
    def __init__(self, fill=None):
        self.px = [[fill] * W for _ in range(H)]

    def copy(self):
        c = Canvas()
        c.px = [row[:] for row in self.px]
        return c

    def set(self, x, y, c):
        x, y = int(x), int(y)
        if 0 <= x < W and 0 <= y < H and c is not None:
            self.px[y][x] = c

    def get(self, x, y):
        if 0 <= x < W and 0 <= y < H:
            return self.px[y][x]
        return None

    def rect(self, x0, y0, x1, y1, c):
        for y in range(max(0, int(y0)), min(H, int(y1))):
            for x in range(max(0, int(x0)), min(W, int(x1))):
                self.px[y][x] = c

    def hline(self, x0, x1, y, c):
        self.rect(x0, y, x1, y + 1, c)

    def ellipse(self, cx, cy, rx, ry, c, test=None):
        # pixel centres inside the ellipse (pixel x covers x..x+1, centre x+0.5)
        for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
            for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
                dx = (x + 0.5 - cx) / rx
                dy = (y + 0.5 - cy) / ry
                if dx * dx + dy * dy <= 1 and 0 <= x < W and 0 <= y < H and (test is None or test(x, y)):
                    self.set(x, y, c)

    def poly(self, pts, c, test=None):
        ys = [p[1] for p in pts]
        for y in range(int(min(ys)) - 1, int(max(ys)) + 2):
            yc = y + 0.5
            xs = []
            n = len(pts)
            for i in range(n):
                (ax, ay), (bx, by) = pts[i], pts[(i + 1) % n]
                if (ay <= yc < by) or (by <= yc < ay):
                    xs.append(ax + (yc - ay) * (bx - ax) / (by - ay))
            xs.sort()
            for a, b in zip(xs[0::2], xs[1::2]):
                for x in range(int(math.floor(a)) - 1, int(math.ceil(b)) + 1):
                    if a <= x + 0.5 < b and 0 <= x < W and 0 <= y < H and (test is None or test(x, y)):
                        self.set(x, y, c)

    def line(self, x0, y0, x1, y1, c, w=1, h=1):
        # a stroke as a run of w x h blocks
        n = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
        for i in range(n + 1):
            t = i / n
            x = x0 + (x1 - x0) * t
            y = y0 + (y1 - y0) * t
            xa = int(round(x - (w - 1) / 2))
            ya = int(round(y - (h - 1) / 2))
            self.rect(xa, ya, xa + int(w), ya + int(h), c)

    def stamp(self, x, y, rows, key):
        # a hand-pixelled patch: rows of characters; key maps a character to a colour
        # (characters not in key are left alone)
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in key and key[ch] is not None:
                    self.set(x + i, y + j, key[ch])

    def paste(self, other, dx=0, dy=0):
        for y in range(H):
            for x in range(W):
                v = other.px[y][x]
                if v is not None:
                    self.set(x + dx, y + dy, v)

    def recolour(self, table):
        for row in self.px:
            for x, v in enumerate(row):
                if v in table:
                    row[x] = table[v]

    def bbox(self):
        xs = [x for y in range(H) for x in range(W) if self.px[y][x] is not None]
        ys = [y for y in range(H) for x in range(W) if self.px[y][x] is not None]
        if not xs:
            return None
        return min(xs), min(ys), max(xs) + 1, max(ys) + 1

    def shifted(self, dx, dy):
        c = Canvas()
        c.paste(self, dx, dy)
        return c

    def mirrored(self, axis):
        # flipped left to right about pixel column axis (x -> 2 * axis - 1 - x)
        c = Canvas()
        for y in range(H):
            for x in range(W):
                v = self.px[y][x]
                if v is not None:
                    c.set(2 * axis - 1 - x, y, v)
        return c

    def outline(self, c, sides=1, tops=1):
        # a ring around every set pixel: sides pixels left and right, tops rows above and below
        src = [row[:] for row in self.px]
        for y in range(H):
            for x in range(W):
                if src[y][x] is not None:
                    continue
                for dx, dy in ((-sides, 0), (sides, 0), (0, -tops), (0, tops)):
                    hit = False
                    for k in range(1, max(abs(dx), abs(dy)) + 1):
                        xx = x + (k if dx > 0 else -k if dx < 0 else 0)
                        yy = y + (k if dy > 0 else -k if dy < 0 else 0)
                        if 0 <= xx < W and 0 <= yy < H and src[yy][xx] is not None:
                            hit = True
                    if hit:
                        self.px[y][x] = c
                        break


def fill_holes(c, col, most=40):
    # clear pockets inside a figure (gaps the shapes leave between them) filled in; open
    # space that reaches the canvas edge, or a pocket bigger than `most`, stays clear
    seen = [[False] * W for _ in range(H)]
    for sy in range(H):
        for sx in range(W):
            if seen[sy][sx] or c.px[sy][sx] is not None:
                continue
            stack = [(sx, sy)]
            seen[sy][sx] = True
            cells = []
            edge = False
            while stack:
                x, y = stack.pop()
                cells.append((x, y))
                if x in (0, W - 1) or y in (0, H - 1):
                    edge = True
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < W and 0 <= ny < H and not seen[ny][nx] and c.px[ny][nx] is None:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            if not edge and len(cells) <= most:
                for x, y in cells:
                    c.px[y][x] = col


def sticker(c, ink, holes=40):
    # the one black line every figure gets: pockets filled, a ring a pixel wide and a row
    # tall (a wide pixel is already twice a row), then the specks the ring left closed
    fill_holes(c, ink, holes)
    c.outline(ink, 1, 1)
    fill_holes(c, ink, 12)
    return c


def bands(c, y0, y1, colours, blend=4, x0=0, x1=W, test=None):
    # a vertical gradient by bands: each colour a solid run of rows, and over the last
    # `blend` rows of a band the next colour comes in on more and more whole rows (an
    # ordered dither by rows: no dots side by side, so NTSC keeps it clean)
    n = len(colours)
    span = (y1 - y0) / n
    order = [0.1, 0.6, 0.35, 0.85]
    for y in range(y0, y1):
        k = min(n - 1, int((y - y0) / span))
        pos = (y - y0) - k * span
        col = colours[k]
        if k + 1 < n and pos > span - blend:
            f = (pos - (span - blend)) / blend
            if f > order[y % 4]:
                col = colours[k + 1]
        for x in range(max(0, x0), min(W, x1)):
            if test is None or test(x, y):
                c.px[y][x] = col


def ridge(x, seed, base, amp):
    # a soft skyline height for column x: a few sines, deterministic
    return base + amp * (0.55 * math.sin(x * 0.19 + seed) + 0.3 * math.sin(x * 0.47 + seed * 2.3)
                         + 0.15 * math.sin(x * 1.1 + seed * 0.7))
