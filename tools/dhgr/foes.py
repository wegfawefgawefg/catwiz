# the forest's enemies, in materials like the cat (light.py colours them for a zone):
#   puffcap   a big pink cap mushroom with white spots, a face on its stem
#   sporelet  a small orange cap, yellow spots, a cheeky face
#   nightflap a round bat on wide wings, flying
# frames: idle, attack (leaning in at the cat, mouth open), hurt (squashed, eyes shut), and
# for the bat a second wingbeat (flap). Everyone faces left, towards the cat.

import math

from canvas import ASPECT, Canvas, sticker
from shade import lit_ellipse, shape_pixels, span_shade, volume

FRAMES = {"puffcap": ["idle", "attack", "hurt"], "sporelet": ["idle", "attack", "hurt"],
          "nightflap": ["idle", "flap", "attack", "hurt"]}

CAP_CUTS = (0.42, 0.9)
STEM_CUTS = (0.3,)

EYES = {
    "idle": ["KK", "WK", "KK", "KK", "KK", "KK"],
    "attack": ["K.", "KK", "WK", "KK", "KK"],
    "hurt": ["...", "KK.", "..K", "KK."],
}


def mushroom(x, feet, s, m, frame="idle"):
    # x the stem's middle, feet the row under it, s the size; m the cap's material prefix
    c = Canvas()
    squash = 0.85 if frame == "hurt" else 1.0
    lean = {"attack": -3.0, "hurt": 1.5}.get(frame, -1.0) * s
    sw = 5.0 * s                                   # the stem's half width at the foot (pixels)
    st = feet - int(19 * s * squash)               # the stem's top
    # the stem: a soft barrel, fatter low down, white with the shade on the right
    stem = [(x - sw, feet - 1), (x - sw - 0.6 * s, feet - 5 * s), (x - sw * 0.8 + lean, st),
            (x + sw * 0.8 + lean, st), (x + sw + 0.6 * s, feet - 5 * s), (x + sw, feet - 1)]
    c.poly(stem, "stem")
    c.poly([(x + sw * 0.35, feet - 1), (x + sw + 0.6 * s, feet - 5 * s), (x + sw * 0.8 + lean, st),
            (x + sw * 0.3 + lean, st)], "stem_sh")
    c.rect(int(x - sw), feet - 1, int(x + sw) + 1, feet, "stem_sh")
    # the cap: a dome on a flat underside, lit from the upper left, a band of gills beneath
    cx = x + lean * 1.3
    top = st + 1
    rx, ry = 13.5 * s, 18 * s * squash
    c.rect(int(cx - rx * 0.8), top, int(cx + rx * 0.8), top + 2, "gill")
    lit_ellipse(c, cx, top, rx, ry, (m + "_sh", m, m + "_hi"), CAP_CUTS,
                test=lambda xx, yy: yy < top + 1)
    c.ellipse(cx, top, rx, ry, m + "_sh", test=lambda xx, yy: top - 1 <= yy < top + 1)
    for dx, dy, r in ((-0.52, -0.42, 0.2), (0.22, -0.72, 0.16), (0.62, -0.28, 0.14), (-0.08, -0.2, 0.12)):
        sx, sy = cx + dx * rx, top + dy * ry
        c.ellipse(sx, sy, max(1.1, r * rx), max(1.6, r * ry * 1.5), m + "_spot",
                  test=lambda xx, yy: yy < top - 1)
    # the face on the stem, turned left towards the cat
    fx = int(round(x + lean * 0.5 - 1.5 * s))
    fy = feet - int(16 * s * squash)
    face(c, fx, fy, frame)
    sticker(c, "ink")
    return c


def face(c, fx, fy, frame):
    key = {"K": "eye", "W": "shine", "M": "mouth"}
    eye = EYES[frame]
    c.stamp(fx - 3, fy, eye, key)
    c.stamp(fx + 2, fy, eye, key)
    if frame == "attack":
        c.stamp(fx - 1, fy + 6, ["KKKK", "KMMK", ".KK."], key)
    elif frame == "hurt":
        c.stamp(fx - 1, fy + 6, [".KK.", "K..K"], key)
    else:
        c.stamp(fx - 1, fy + 7, ["K..K", ".KK."], key)
    c.rect(fx - 5, fy + 6, fx - 3, fy + 7, "blush")
    c.rect(fx + 4, fy + 6, fx + 6, fy + 7, "blush")


def puffcap(x, feet, frame="idle"):
    return mushroom(x, feet, 1.0, "puff", frame)


def sporelet(x, feet, frame="idle"):
    # a chubby little stem under a tall bell of a cap that leans back, a few white dots
    c = Canvas()
    squash = 0.85 if frame == "hurt" else 1.0
    lean = {"attack": -2.0, "hurt": 1.0}.get(frame, 0.0)
    sw = 4.2
    st = feet - int(12 * squash)
    c.poly([(x - sw, feet - 1), (x - sw - 0.8, feet - 5), (x - sw + 0.5 + lean, st), (x + sw - 0.5 + lean, st),
            (x + sw + 0.8, feet - 5), (x + sw, feet - 1)], "stem")
    c.poly([(x + 1.5, feet - 1), (x + sw + 0.8, feet - 5), (x + sw - 0.5 + lean, st), (x + 1 + lean, st)], "stem_sh")
    c.rect(int(x - sw), feet - 1, int(x + sw) + 1, feet, "stem_sh")
    # the bell: a tall rounded cone leaning back, cut flat underneath, shaded as a puff
    bx = x + lean * 1.4
    top = st + 1
    h = 21 * squash
    # a rounded bell, taller than wide, its crown tipped back a little
    outline = [(-6.6, 0), (-6.4, 0.22), (-5.6, 0.45), (-4.4, 0.65), (-2.8, 0.82), (-1.0, 0.95), (0.8, 1.0),
               (2.6, 0.95), (4.0, 0.82), (5.2, 0.62), (6.2, 0.4), (6.9, 0.2), (7.2, 0)]
    left = [(bx + u, top - v * h) for u, v in outline]
    right = []
    bell = shape_pixels(lambda s: s.poly(left + right, "x"))
    span_shade(c, bell, ("spore_sh", "spore", "spore_hi"), (0.2, 0.9), tilt=0.45)
    c.rect(int(bx - 7), top - 1, int(bx + 8), top + 1, "spore_sh")
    k = squash
    for sx, sy in ((bx - 3, top - 7 * k), (bx + 3, top - 9 * k), (bx + 1, top - 15 * k)):
        c.ellipse(sx, sy, 1.1, 1.6, "spore_spot")
    fx = int(round(x + lean * 0.5 - 1))
    fy = feet - int(10 * squash)
    face(c, fx, fy, frame)
    sticker(c, "ink")
    return c


# the bat's right wing by wingbeat, in pixels and rows from the body's middle: the shoulder,
# the wrist, then the finger tips along the trailing edge out to in, and where the edge meets
# the body. The left wing is the same, mirrored.
WINGS = {
    "up": [(4, -3), (12, -14), (22, -10), (20, 0), (13, 5), (5, 4)],
    "down": [(4, -3), (13, 2), (21, 9), (15, 14), (8, 11), (4, 5)],
    "glide": [(4, -3), (13, -8), (23, -2), (18, 6), (10, 8), (4, 5)],
}
BEATS = {"idle": "up", "flap": "down", "attack": "glide", "hurt": "up"}


def nightflap(x, y, frame="idle"):
    # x, y the body's middle; wings out to both sides by the wingbeat
    c = Canvas()
    if frame == "attack":
        x -= 2
        y += 2
    for side in (-1, 1):
        wing(c, x, y, side, WINGS[BEATS[frame]])
    # the ears, the round body, then the face
    for side, h in ((-1, 10), (1, 9)):
        b0, b1 = (x + side * 0.5, y - 6), (x + side * 5, y - 4)
        tip = (x + side * 4.5, y - 6 - h)
        c.poly([b0, b1, tip], "bat")
        c.poly([(x + side * 2.0, y - 6), (x + side * 4.0, y - 5), (x + side * 3.9, y - 6 - h * 0.7)], "ear_in")
    volume(c, [(x, y, 9, 0)], ("bat_sh", "bat", "bat_hi"), (0.2, 0.93), height=0.0)
    key = {"K": "eye", "W": "shine", "Y": "bat_eye", "F": "fang", "M": "mouth"}
    if frame == "hurt":
        c.stamp(x - 4, y - 2, ["K..", ".K.", "K.."], key)
        c.stamp(x + 1, y - 2, ["..K", ".K.", "..K"], key)
        c.stamp(x - 1, y + 4, [".K.", "K.K"], key)
    else:
        eye = ["YYK", "YKK", "YYK"] if frame != "attack" else ["K..", "YKK", "YYK"]
        c.stamp(x - 4, y - 2, eye, key)
        c.stamp(x + 1, y - 2, eye, key)
        if frame == "attack":
            c.stamp(x - 2, y + 3, ["KKKKK", "KFMFK", ".KKK."], key)
        else:
            c.stamp(x - 1, y + 3, ["KKK", "F.F"], key)
    sticker(c, "ink")
    return c


def wing(c, x, y, side, shape):
    # the membrane with scallops cut between the finger tips, then the fingers
    pts = [(x + side * u, y + v) for u, v in shape]
    shoulder, wrist, tips, body_pt = pts[0], pts[1], pts[2:5], pts[5]
    edge = [shoulder, wrist, tips[0]]
    for a, b in zip(tips + [body_pt], tips[1:] + [body_pt]):
        if a == b:
            continue
        # the scallop: a point pulled in towards the wrist between two tips
        mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
        edge.append((mx + (wrist[0] - mx) * 0.22, my + (wrist[1] - my) * 0.22))
        edge.append(b)
    c.poly(edge, "wing")
    for t in tips:
        c.line(wrist[0], wrist[1], t[0], t[1], "bone", 1, 1)
