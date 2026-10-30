# the actors of the forest battle, drawn in the v6 mockup style (mockup/battle_forest_v6.py):
# the witch dog, two cap mushrooms and a bat, each with its moods. Every function draws on a
# Canvas whose empty pixels are "." at absolute screen positions; export.py adds the sticker
# outline and cuts sprites out on the byte grid.
#
# art rules (owner, 2026-10-27): stylized silhouettes with depth, three-quarter angles, 2-px
# strokes, dither in pixel pairs, expressive faces that carry state. NTSC artifact colour is
# the real target; check the clean look for readability.

import math


def dog(c, x, feet, mood="idle"):
    # three-quarter view turned towards the enemies: features shifted right, the far ear
    # smaller. grey dithered head and ears, white muzzle and blaze, ringed eyes with diamond
    # pupils, a tall crooked hat that leans left as one rigid shape
    c.rect(x - 4, feet - 9, x - 1, feet, "K")                     # legs
    c.rect(x + 3, feet - 9, x + 6, feet, "K")
    c.poly([(x - 7, feet - 22), (x + 9, feet - 22), (x + 14, feet - 7), (x - 12, feet - 7)], "K")
    hy = feet - 32
    f = x + 2                                                     # face centre, turned right
    c.ellipse(x - 13, hy + 5, 5, 10, "K")                         # near ear
    c.ellipse(x - 13, hy + 5, 4, 9, "W")
    c.grey(x - 17, hy - 4, x - 8, hy + 15,
           lambda px, py: ((px - x + 13) / 3) ** 2 + ((py - hy - 3) / 7) ** 2 <= 1)
    c.ellipse(x + 11, hy + 3, 4, 8, "K")                          # far ear, tucked behind
    c.ellipse(x + 11, hy + 3, 3, 7, "W")
    c.grey(x + 7, hy - 5, x + 15, hy + 11,
           lambda px, py: ((px - x - 11) / 2.5) ** 2 + ((py - hy - 3) / 6) ** 2 <= 1)
    c.ellipse(x, hy, 12, 11, "K")                                 # head
    c.grey(x - 11, hy - 10, x + 12, hy + 11,
           lambda px, py: ((px - x) / 11) ** 2 + ((py - hy) / 10) ** 2 <= 1)
    c.ellipse(f + 1, hy + 6, 8, 5, "W")                           # muzzle
    c.rect(f - 1, hy - 10, f + 3, hy + 2, "W")                    # blaze
    dog_eyes(c, f, hy, mood)
    c.ellipse(f + 3, hy + 3, 3, 2, "K")                           # nose
    dog_mouth(c, f, hy, mood)
    dog_hat(c, x, hy)
    c.line(x + 12, feet - 17, x + 25, feet - 28, "W", 2)          # wand
    c.rect(x + 24, feet - 30, x + 28, feet - 26, "W")


def dog_eyes(c, f, hy, mood):
    for ex, r in ((f - 5, 4), (f + 6, 3)):                        # the far one smaller
        c.ellipse(ex, hy - 2, r + 1, r + 1, "K")
        c.ellipse(ex, hy - 2, r, r, "W")
        if mood in ("idle", "bark"):
            c.poly([(ex + 1, hy - 4), (ex + 3, hy - 2), (ex + 1, hy), (ex - 1, hy - 2)], "K")
        elif mood == "worried":
            c.rect(ex, hy - 2, ex + 2, hy + 1, "K")               # small pupils, low
            c.line(ex - r, hy - 5 - (r - 3), ex + r, hy - 8 - (r - 3), "K", 1)  # brows up
        elif mood == "hurt":
            c.ellipse(ex, hy - 2, r, r, "K")                      # squeezed shut: > <
            c.line(ex - r + 1, hy - 4, ex + r - 1, hy - 2, "W", 1)
            c.line(ex - r + 1, hy, ex + r - 1, hy - 2, "W", 1)
        elif mood == "happy":
            c.ellipse(ex, hy - 2, r, r, "K")                      # closed in a smile: ^ ^
            c.line(ex - r + 1, hy - 1, ex, hy - 4, "W", 2)
            c.line(ex, hy - 4, ex + r - 1, hy - 1, "W", 2)
        elif mood == "ko":
            c.line(ex - 2, hy - 4, ex + 2, hy, "K", 2)            # x eyes
            c.line(ex + 2, hy - 4, ex - 2, hy, "K", 2)


def dog_mouth(c, f, hy, mood):
    if mood == "bark":
        c.ellipse(f + 3, hy + 8, 4, 3, "K")                       # wide open
        c.rect(f + 1, hy + 9, f + 6, hy + 11, "V")                # tongue
    elif mood == "happy":
        c.ellipse(f + 3, hy + 8, 4, 2, "K")
        c.rect(f + 2, hy + 9, f + 6, hy + 11, "V")
    elif mood == "hurt":
        c.line(f - 1, hy + 9, f + 2, hy + 7, "K", 1)              # wobbly
        c.line(f + 2, hy + 7, f + 5, hy + 9, "K", 1)
        c.line(f + 5, hy + 9, f + 8, hy + 7, "K", 1)
    elif mood == "ko":
        c.line(f, hy + 8, f + 7, hy + 8, "K", 1)
        c.rect(f + 4, hy + 8, f + 7, hy + 12, "V")                # tongue out
    elif mood == "worried":
        c.ellipse(f + 3, hy + 8, 2, 2, "K")                       # little o
    else:
        c.line(f + 3, hy + 5, f, hy + 8, "K")
        c.line(f + 3, hy + 5, f + 6, hy + 8, "K")


def dog_hat(c, x, hy):
    # drawn upright, then turned as a whole: the brim stays at a right angle to the cone
    hx, hyb, ang = x - 1, hy - 9, math.radians(-26)

    def turn(pts):
        ca, sa = math.cos(ang), math.sin(ang)
        return [(hx + px * ca - py * sa, hyb + px * sa + py * ca) for px, py in pts]

    brim = [(27 * math.cos(t / 20 * 2 * math.pi), 3.5 * math.sin(t / 20 * 2 * math.pi) + 1)
            for t in range(20)]
    c.poly(turn(brim), "K")
    c.poly(turn([(-10, 0), (10, 0), (1, -40), (-1, -40)]), "K")   # cone, sharp
    c.poly(turn([(-10, -1), (10, -1), (9, -5), (-9, -5)]), "V")   # band


def cap(c, x, feet, s, mood="idle"):
    # a cap mushroom leaning left towards the dog, a face on the stem
    lean = -3 * s
    c.poly([(x - 5 * s, feet), (x + 5 * s, feet), (x + 5 * s + lean, feet - 13 * s),
            (x - 5 * s + lean, feet - 13 * s)], "W")
    top = feet - 15 * s
    cx = x + lean * 1.4
    c.ellipse(cx, top, 12 * s, 8 * s, "V")
    c.rect(int(cx - 12 * s), int(top), int(cx + 12 * s) + 1, int(top + 3 * s), "V")
    c.ellipse(cx - 6 * s, top - 3 * s, 2.5 * s, 2 * s, "W")
    c.ellipse(cx + 3 * s, top - 5 * s, 2 * s, 1.5 * s, "W")
    c.ellipse(cx + 8 * s, top - 1 * s, 1.5 * s, 1.5 * s, "W")
    fx = x + lean * 0.6 - 1 * s                                   # face, turned left
    ey = feet - 9 * s
    cap_face(c, x, feet, s, fx, ey, mood)


def cap_face(c, x, feet, s, fx, ey, mood):
    if mood not in ("hurt", "stunned"):
        c.rect(int(fx - 3 * s), int(ey), int(fx - 1 * s), int(ey + 3 * s), "K")   # eyes
        c.rect(int(fx + 1 * s), int(ey), int(fx + 3 * s), int(ey + 3 * s), "K")
    if mood == "angry":
        c.line(fx - 4 * s, ey - 3 * s, fx - 1 * s, ey - 1 * s, "K", 1)   # brows down
        c.line(fx + 4 * s, ey - 3 * s, fx + 1 * s, ey - 1 * s, "K", 1)
        c.rect(int(fx - 2 * s), int(ey + 5 * s), int(fx + 2 * s), int(ey + 6 * s), "K")
    elif mood == "worried":
        c.line(fx - 4 * s, ey - 1 * s, fx - 1 * s, ey - 3 * s, "K", 1)   # brows up
        c.line(fx + 4 * s, ey - 1 * s, fx + 1 * s, ey - 3 * s, "K", 1)
        c.ellipse(fx, ey + 5.5 * s, 1.5 * s, 1.5 * s, "K")               # little o
    elif mood == "hurt":
        for ex in (fx - 2 * s, fx + 2 * s):                                # > <
            c.line(ex - 1.5 * s, ey, ex + 1.5 * s, ey + 1.5 * s, "K", 1)
            c.line(ex - 1.5 * s, ey + 3 * s, ex + 1.5 * s, ey + 1.5 * s, "K", 1)
        c.line(fx - 3 * s, ey + 6 * s, fx + 3 * s, ey + 5 * s, "K", 1)
    elif mood == "stunned":
        for ex in (fx - 2 * s, fx + 2 * s):                                # x eyes
            c.line(ex - 1.5 * s, ey, ex + 1.5 * s, ey + 3 * s, "K", 1)
            c.line(ex + 1.5 * s, ey, ex - 1.5 * s, ey + 3 * s, "K", 1)
    else:
        c.rect(int(fx - 1 * s), int(ey + 5 * s), int(fx + 1 * s), int(ey + 6 * s), "K")


def bat(c, x, y, mood="angry", flap=0):
    # a jagged-winged bat glaring at the cat with a fanged grin. flap 0 is the upstroke, both
    # wings raised; flap 1 the downstroke, both wings swung down together, hanging lower than
    # they were raised (each turned over the middle of where it meets the body, then dropped)
    wing = [(x - 6, y - 2), (x - 30, y - 14), (x - 25, y - 4), (x - 32, y + 1), (x - 21, y + 1),
            (x - 23, y + 8), (x - 10, y + 5)]
    far = [(2 * x - px + 2, py - 3) for px, py in wing]
    if flap:
        drop = 2
        wing = [(px + 1, 2 * (y + 1.5) - py + drop) for px, py in wing]
        far = [(px - 1, 2 * (y - 1.5) - py + drop) for px, py in far]
    c.poly(wing, "K")
    c.poly(far, "K")
    c.ellipse(x, y + 1, 9, 10, "K")
    c.poly([(x - 8, y - 6), (x - 6, y - 17), (x - 2, y - 7)], "K")
    c.poly([(x + 2, y - 7), (x + 6, y - 15), (x + 8, y - 5)], "K")
    bat_face(c, x, y, mood)


def bat_face(c, x, y, mood):
    if mood == "hurt":
        for ex in (x - 4, x + 4):                                  # > <
            c.line(ex - 2, y - 3, ex + 2, y - 1, "W", 1)
            c.line(ex - 2, y + 1, ex + 2, y - 1, "W", 1)
        c.ellipse(x, y + 6, 3, 2, "W")                             # yelp
        return
    if mood == "worried":
        for ex in (x - 4, x + 4):                                  # wide round eyes
            c.ellipse(ex, y - 1, 3, 3, "W")
            c.rect(ex - 1, y - 1, ex + 1, y + 1, "K")
        c.rect(x - 2, y + 6, x + 2, y + 8, "W")
        return
    c.poly([(x - 7, y - 3), (x - 2, y - 1), (x - 3, y + 2), (x - 7, y + 1)], "W")   # glare
    c.poly([(x + 6, y - 3), (x + 1, y - 1), (x + 2, y + 2), (x + 6, y + 1)], "W")
    c.rect(x - 5, y + 5, x + 5, y + 7, "W")                        # grin
    c.poly([(x - 4, y + 7), (x - 2, y + 7), (x - 3, y + 10)], "W")  # fangs
    c.poly([(x + 2, y + 7), (x + 4, y + 7), (x + 3, y + 10)], "W")


def poof(c, x, y, step):
    # the puff an actor leaves when it dies: step 0 a tight white cloud, 1 bigger and broken
    if step == 0:
        for dx, dy, r in ((0, 0, 8), (-8, 3, 6), (8, 3, 6), (-4, -6, 6), (5, -6, 5)):
            c.ellipse(x + dx, y + dy, r, r * 0.8, "W")
        c.grey(x - 14, y - 12, x + 14, y + 10,
               lambda px, py: ((px - x) / 6) ** 2 + ((py - y) / 5) ** 2 <= 1)
        return
    for dx, dy, r in ((-11, 2, 5), (11, 1, 5), (-5, -9, 4), (6, -10, 4), (0, 8, 4), (0, -1, 3)):
        c.ellipse(x + dx, y + dy, r, r * 0.8, "W")
        c.grey(x + dx - r, y + dy - r, x + dx + r, y + dy + r,
               lambda px, py, ax=x + dx, ay=y + dy, rr=r - 2: ((px - ax) / rr) ** 2 + ((py - ay) / rr) ** 2 <= 1)


def bolt(c, x, y):
    # the wand's shot: a white star with a little tail
    c.poly([(x - 4, y + 2), (x + 4, y + 2), (x, y - 4)], "W")
    c.poly([(x - 4, y - 1), (x + 4, y - 1), (x, y + 5)], "W")


def marker(c, x, y):
    # the target arrow, pointing down at the enemy the dice go to
    c.poly([(x - 5, y), (x + 6, y), (x, y + 6)], "W")
    c.rect(x - 1, y - 4, x + 2, y, "W")


def shadow(c, x, y, rx):
    c.ellipse(x, y, rx, 2.5, "K")
