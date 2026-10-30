# Catwiz, the hero: a chibi black cat in a leaning witch's hat, a white face, a wand with a
# star. Drawn in materials (names, not colours): light.py turns them into a zone's colours,
# so the one drawing serves day, dusk and night. The frames:
#   idle     the stance
#   attack   the wand thrust up and forward, the star flaring, a fierce face
#   hit      knocked back: leaning away, eyes squeezed, ears flat, the hat knocked askew
#   meow     the hop: up off the ground, eyes shut happy, mouth open
#   ears     the ears-pop: the hat jumps up off the head, the ears spring up, eyes wide
#
# shapes are worked out in rows (visual units: a pixel is ASPECT rows wide) and put down on
# whole pixels; the face is hand-pixelled. x is the body's middle pixel, feet the row under
# the feet.

import math

from canvas import ASPECT, Canvas, sticker
import light

HAT_ANGLE = -24

POSES = {
    "idle": dict(),
    "attack": dict(arm=1, eyes="fierce", mouth="grr", lean=1, star=1.35),
    "hit": dict(lean=-2, eyes="shut", mouth="wobble", ears="flat", hat_turn=-12, arm=-1, dy=-1),
    "meow": dict(dy=-5, eyes="happy", mouth="meow", ears="up", tail=1),
    "ears": dict(eyes="wide", mouth="o", ears="pop", hat_lift=13, hat_turn=10),
}
FRAMES = ["idle", "attack", "hit", "meow", "ears"]


def px(v):
    return v / ASPECT


EYES = {
    # near eye then far eye: K ink (the pupil), W the shine; '.' leaves the face
    "open": ([".KK.", "KWKK", "KWKK", "KKKK", "KKKK", "KKKK", ".KK."],
             [".KK.", "KWKK", "KKKK", "KKKK", "KKKK", ".KK."]),
    "fierce": (["K...", "KK..", "KWKK", "KKKK", "KKKK", ".KK."],
               ["...K", "..KK", "KWKK", "KKKK", ".KK."]),
    "shut": ([".....", "KK...", "..KK.", "KK...", "....."],
             ["....", "..KK", "KK..", "..KK"]),
    "happy": (["....", ".KK.", "K..K", "K..K"],
              ["....", ".KK.", "K..K", "K..K"]),
    "wide": ([".KK.", "KWWK", "KWKK", "KKKK", "KKKK", "KKKK", "KKKK", ".KK."],
             [".KK.", "KWWK", "KKKK", "KKKK", "KKKK", "KKKK", ".KK."]),
}
EYE_DY = {"open": (-2, -1), "fierce": (-1, 0), "shut": (-1, 0), "happy": (0, 0), "wide": (-3, -2)}
MOUTHS = {
    "w": ["..K..", "K.K.K", ".K.K."],
    "grr": ["KKKKK", "KWWWK", ".KKK."],
    "wobble": [".....", ".K.K.", "K.K.K"],
    "meow": ["..K..", ".KMK.", ".KMK.", "..K.."],
    "o": ["..K..", ".KMK.", "..K.."],
}


def cat(x, feet, frame="idle"):
    p = POSES[frame]
    dy = p.get("dy", 0)
    lean = p.get("lean", 0)
    feet_y = feet + dy
    c = Canvas()
    tail(c, x, feet_y, p.get("tail", 0))
    body(c, x, feet_y, lean, p.get("arm", 0), p.get("star", 1.0))
    hx, hy = x + 1 + lean, feet_y - 34
    head(c, hx, hy, p.get("eyes", "open"), p.get("mouth", "w"))
    hat(c, hx - 1, hy - 14 - p.get("hat_lift", 0), HAT_ANGLE + p.get("hat_turn", 0), p.get("ears", "ears"),
        hy, hx)
    sticker(c, "ink")
    return c


def tail(c, x, feet, swish):
    # a fat curl out behind the robe, its white tip turned in; swish lifts it
    s = swish * 3
    pts = [(x - 6, feet - 4), (x - 10, feet - 5 - s), (x - 13, feet - 9 - s), (x - 14, feet - 15 - s),
           (x - 13, feet - 20 - s), (x - 10.5, feet - 23 - s)]
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        c.line(ax, ay, bx, by, "fur", 2, 4)
    c.ellipse(x - 9.5, feet - 23.5 - s, 1.4, 2.4, "tip")


def body(c, x, feet, lean, arm, star_size):
    # feet, the robe (a bell, widest at the hem), a sleeve out to the wand and a white paw
    c.ellipse(x - 3.5, feet - 2, 2.4, 2.4, "fur")
    c.ellipse(x + 4, feet - 2, 2.4, 2.4, "fur")
    t = lean * 0.5
    c.poly([(x - 4 + t, feet - 23), (x + 5 + t, feet - 23), (x + 9, feet - 3), (x - 8, feet - 3)], "robe")
    c.poly([(x - 4 + t, feet - 23), (x - 2 + t, feet - 23), (x - 5, feet - 3), (x - 8, feet - 3)], "robe_hi")
    for sx, sy in ((x + 2, feet - 15), (x - 2, feet - 9), (x + 5, feet - 8)):
        c.set(sx, sy, "robe_star")
        c.set(sx, sy + 1, "robe_star")
    c.rect(x - 8, feet - 5, x + 10, feet - 3, "trim")
    if arm > 0:
        # the thrust: the sleeve out level, the wand pointing up and ahead
        sx, sy = x + 13, feet - 24
        c.poly([(x + 2, feet - 22), (x + 7, feet - 24), (x + 14, feet - 27), (x + 13, feet - 21), (x + 4, feet - 15)], "robe")
        c.line(sx + 1, sy - 2, sx + 7, sy - 15, "wand", 1, 2)
        c.ellipse(sx + 1.2, sy - 1, 1.9, 3.0, "paw")
        star(c, sx + 8, sy - 19, 3.2 * star_size, 6.0 * star_size, "star", "star_hi")
        sparkle(c, sx + 8, sy - 19, 9)
    elif arm < 0:
        # flung back
        c.poly([(x + 2, feet - 21), (x + 6, feet - 22), (x + 8, feet - 16), (x + 3, feet - 13)], "robe")
        c.line(x + 8, feet - 15, x + 13, feet - 26, "wand", 1, 2)
        c.ellipse(x + 8, feet - 15, 1.9, 3.0, "paw")
        star(c, x + 14, feet - 29, 2.6, 4.8, "star", "star_hi")
    else:
        c.poly([(x + 2, feet - 21), (x + 7, feet - 23), (x + 10, feet - 19), (x + 4, feet - 14)], "robe")
        c.line(x + 10, feet - 21, x + 14.5, feet - 36, "wand", 1, 2)
        c.ellipse(x + 10.5, feet - 20.5, 1.9, 3.0, "paw")
        star(c, x + 15, feet - 39, 3.2 * star_size, 6.0 * star_size, "star", "star_hi")


def head(c, hx, hy, eyes, mouth):
    # cheek tufts and the round head, then the white face in it, shaded away from the light
    c.poly([(hx - 11, hy + 4), (hx - 6, hy - 2), (hx - 6, hy + 9)], "fur")
    c.poly([(hx + 12, hy + 4), (hx + 7, hy - 2), (hx + 7, hy + 9)], "fur")
    c.ellipse(hx + 0.5, hy, 9, 13, "fur")
    c.ellipse(hx + 0.5, hy + 1, 8, 11.5, "face")
    c.ellipse(hx + 0.5, hy + 1, 8, 11.5, "face_sh",
              test=lambda xx, yy: ((xx + 0.5 - (hx - 1.7)) / 8) ** 2 + ((yy + 0.5 - (hy - 0.5)) / 11.5) ** 2 > 1)
    key = {"K": "eye", "W": "shine", "M": "mouth"}
    f = hx + 1                                         # the face's middle, turned to the right
    near, far = EYES[eyes]
    dn, df = EYE_DY[eyes]
    c.stamp(f - 6, hy + dn, near, key)
    c.stamp(f + 2, hy + df, far, key)
    c.rect(f - 1, hy + 5, f + 2, hy + 6, "nose")       # nose: a wide drop
    c.rect(f, hy + 6, f + 1, hy + 7, "nose")
    c.stamp(f - 2, hy + 7, MOUTHS[mouth], key)
    if eyes != "shut":
        c.rect(f - 7, hy + 6, f - 4, hy + 8, "blush")
        c.rect(f + 3, hy + 6, f + 6, hy + 8, "blush")


def hat(c, hx, hy, angle, ears, head_y, head_x):
    # the rigid leaning hat, drawn upright in rows around (hx, hy) then turned as a whole
    a = math.radians(angle)
    ca, sa = math.cos(a), math.sin(a)

    def turn(pts):
        return [(hx + px(u * ca - v * sa), hy + u * sa + v * ca) for u, v in pts]

    brim = [(28 * math.cos(t / 24 * 2 * math.pi), 4.2 * math.sin(t / 24 * 2 * math.pi) + 1) for t in range(24)]
    cone = [(-12, 0), (12, 0), (4, -24), (1, -40), (-2, -40), (-4, -24)]
    if ears == "pop":
        # the ears stand straight up on the head, the hat hangs in the air above them
        for side, size in ((-1, 1.0), (1, 0.85)):
            b0 = (head_x + side * 7.5, head_y - 8)
            b1 = (head_x + side * 2.5, head_y - 11.5)
            tip = (head_x + side * (7.5 + 2 * size), head_y - 12 - 19 * size)
            c.poly([b0, b1, tip], "fur")
            c.poly(inset([b0, b1, tip], 1.4, 2.6), "ear_in")
    c.poly(turn(brim), "hat")
    c.poly(turn(cone), "hat")
    c.poly(turn([(-12, -2), (12, -2), (10.6, -7), (-10.6, -7)]), "band")
    c.poly(turn([(-11.5, -2), (12, -2), (11.4, -3.5), (-11.2, -3.5)]), "band_hi")
    sx, sy = turn([(0, -16)])[0]
    star(c, sx, sy, 1.8, 3.4, "star")
    if ears == "pop":
        return
    # the ears, up through slits in the brim beside the cone: the near one bigger
    for side, size in ((-1, 1.0), (1, 0.85)):
        if ears == "flat":
            b0, b1, tip = (side * 21, 0.5), (side * 12, -3), (side * (24 + 4 * size), -4 - 6 * size)
        elif ears == "up":
            b0, b1, tip = (side * 21, 0.5), (side * 12, -3), (side * (12 + 4 * size), -6 - 16 * size)
        else:
            b0, b1, tip = (side * 21, 0.5), (side * 12, -3), (side * (14 + 4 * size), -4 - 14 * size)
        c.poly(turn([b0, b1, tip]), "fur")
        c.poly(turn(inset_rows([b0, b1, tip], 3.4)), "ear_in")


def inset_rows(pts, d):
    # a triangle shrunk towards its middle by d rows
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    out = []
    for u, v in pts:
        du, dv = u - cx, v - cy
        n = max(0.01, math.hypot(du, dv))
        k = max(0.0, (n - d) / n)
        out.append((cx + du * k, cy + dv * k))
    return out


def inset(pts, dx, dy):
    # the same in pixel space: dx pixels and dy rows
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    out = []
    for u, v in pts:
        du, dv = (u - cx) * ASPECT, v - cy
        n = max(0.01, math.hypot(du, dv))
        k = max(0.0, (n - (dx * ASPECT + dy) / 2) / n)
        out.append((cx + (u - cx) * k, cy + dv * k))
    return out


def star(c, cx, cy, rx, ry, col, hi=None):
    # a five point star, rx in pixels, ry in rows
    pts = []
    for i in range(10):
        r = 1.0 if i % 2 == 0 else 0.45
        t = -math.pi / 2 + i * math.pi / 5
        pts.append((cx + rx * r * math.cos(t), cy + ry * r * math.sin(t)))
    c.poly(pts, col)
    if hi:
        c.rect(int(cx) - 1, int(cy) - 1, int(cx), int(cy) + 1, hi)


def sparkle(c, cx, cy, r):
    # four short rays round the flaring star, every other row (they stay clean in NTSC)
    for k in range(3, r):
        if k % 2:
            continue
        c.set(cx, cy - k * 1.0 - 4, "star_hi")
        c.set(cx, cy + k * 1.0 + 4, "star_hi")
    for k in (4, 5):
        c.set(cx - k, cy, "star_hi")
        c.set(cx + k, cy, "star_hi")
