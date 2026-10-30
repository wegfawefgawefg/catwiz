# flat toon shading of round volumes: a shape is a few spheres (centre, radius in rows, a
# depth bias), each pixel takes the front-most sphere's normal, and the light (upper left,
# towards us) splits it into a ramp of tones. A height term lights the top of the whole
# shape more than its foot, so a crown of many bumps reads as one mass with clusters in it.
#
# a ramp is a tuple of colours from shade to light, any length; None leaves a tone clear.
# `cuts` are the thresholds between tones (one fewer than the ramp).

import math

from canvas import ASPECT
from dhgr import W, H

LIGHT = (-0.55, -0.65, 0.52)


def unit(v):
    n = math.sqrt(sum(a * a for a in v))
    return tuple(a / n for a in v)


def tone(v, cuts):
    k = 0
    while k < len(cuts) and v > cuts[k]:
        k += 1
    return k


def volume(c, spheres, ramp, cuts, height=0.35, light=LIGHT, test=None, stretch=1.0):
    # spheres: (cx, cy, r, z): r in rows (the pixel radius is r / ASPECT * stretch), z the
    # depth bias that decides who is in front. returns the pixels drawn.
    L = unit(light)
    xs0 = int(min(s[0] - s[2] / ASPECT * stretch for s in spheres)) - 1
    xs1 = int(max(s[0] + s[2] / ASPECT * stretch for s in spheres)) + 2
    ys0 = int(min(s[1] - s[2] for s in spheres)) - 1
    ys1 = int(max(s[1] + s[2] for s in spheres)) + 2
    top, bottom = ys0, ys1
    drawn = []
    for y in range(max(0, ys0), min(H, ys1)):
        for x in range(max(0, xs0), min(W, xs1)):
            if test is not None and not test(x, y):
                continue
            best = None
            for cx, cy, r, zb in spheres:
                dx = (x + .5 - cx) * ASPECT / (r * stretch)
                dy = (y + .5 - cy) / r
                d2 = dx * dx + dy * dy
                if d2 < 1:
                    z = math.sqrt(1 - d2)
                    zz = z * r + zb
                    if best is None or zz > best[0]:
                        best = (zz, dx, dy, z)
            if best is None:
                continue
            _, dx, dy, z = best
            ndl = dx * L[0] + dy * L[1] + z * L[2]
            h = (bottom - y) / max(1, bottom - top)
            v = (1 - height) * ndl + height * (h * 1.2 - 0.2)
            col = ramp[tone(v, cuts)]
            if col is not None:
                c.px[y][x] = col
            drawn.append((x, y))
    return drawn


def lit_ellipse(c, cx, cy, rx, ry, ramp, cuts, light=LIGHT, test=None, flat=0.0):
    # one ellipse shaded as a dome (rx in pixels, ry in rows); flat lifts the dark side
    L = unit(light)
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if not (0 <= x < W and 0 <= y < H):
                continue
            dx = (x + .5 - cx) / rx
            dy = (y + .5 - cy) / ry
            d2 = dx * dx + dy * dy
            if d2 > 1 or (test is not None and not test(x, y)):
                continue
            z = math.sqrt(1 - d2)
            v = dx * L[0] + dy * L[1] + z * L[2]
            v = v * (1 - flat) + flat
            col = ramp[tone(v, cuts)]
            if col is not None:
                c.px[y][x] = col


def puff(c, pixels, ramp, cuts, radius=None, light=LIGHT, height=0.0):
    # any filled shape shaded as if inflated: each pixel's height comes from its distance to
    # the shape's edge (in rows, a pixel counting ASPECT), its normal from how that height
    # changes. pixels: a set of (x, y).
    L = unit(light)
    pix = set(pixels)
    edge = [(x, y) for x, y in pix
            if any((x + dx, y + dy) not in pix for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))]

    def dist(x, y):
        return min(math.hypot((x - ex) * ASPECT, y - ey) for ex, ey in edge) + 0.5

    d = {p: dist(*p) for p in pix}
    R = radius or max(d.values())
    hmap = {}
    for p, v in d.items():
        t = min(1.0, v / R)
        hmap[p] = math.sqrt(max(0.0, 1 - (1 - t) ** 2)) * R
    ys = [p[1] for p in pix]
    top, bottom = min(ys), max(ys) + 1
    for (x, y), hv in hmap.items():
        gx = (hmap.get((x + 1, y), 0) - hmap.get((x - 1, y), 0)) / (2 * ASPECT)
        gy = (hmap.get((x, y + 1), 0) - hmap.get((x, y - 1), 0)) / 2
        n = unit((-gx, -gy, 1.0))
        v = n[0] * L[0] + n[1] * L[1] + n[2] * L[2]
        hh = (bottom - y) / max(1, bottom - top)
        v = (1 - height) * v + height * (hh * 1.2 - 0.2)
        col = ramp[tone(v, cuts)]
        if col is not None:
            c.px[y][x] = col


def shape_pixels(draw):
    # the pixels a drawing call fills: draw(canvas) on a scratch canvas
    from canvas import Canvas
    s = Canvas()
    draw(s)
    return [(x, y) for y in range(H) for x in range(W) if s.px[y][x] is not None]


def span_shade(c, pixels, ramp, cuts, tilt=0.0, light=LIGHT):
    # a shape shaded row by row as a cylinder or cone: across each row's span the normal
    # turns from left to right; tilt leans every normal up (a cone narrowing upwards)
    L = unit(light)
    rows = {}
    for x, y in pixels:
        rows.setdefault(y, []).append(x)
    for y, xs in rows.items():
        a, b = min(xs), max(xs) + 1
        mid, half = (a + b) / 2, max(0.5, (b - a) / 2)
        for x in xs:
            u = max(-1.0, min(1.0, (x + 0.5 - mid) / half))
            n = unit((u, -tilt, math.sqrt(max(0.0, 1 - u * u))))
            v = n[0] * L[0] + n[1] * L[1] + n[2] * L[2]
            col = ramp[tone(v, cuts)]
            if col is not None:
                c.px[y][x] = col
