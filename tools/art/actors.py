# the enemies of the forest battle, drawn in the v6 mockup style (mockup/battle_forest_v6.py):
# two cap mushrooms and a bat, each with its moods, and the battle's effects. The hero is in
# hero.py (it was the witch dog here until the cat took over), the final boss in boss.py.
# Every function draws on a Canvas whose empty pixels are "." at absolute screen positions;
# export.py adds the sticker outline and cuts sprites out on the byte grid.
#
# art rules (owner, 2026-10-27): stylized silhouettes with depth, three-quarter angles, 2-px
# strokes, dither in pixel pairs, expressive faces that carry state. NTSC artifact colour is
# the real target; check the clean look for readability.

def cap(c, x, feet, s, mood="idle"):
    # a cap mushroom leaning left towards the cat, a face on the stem
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
