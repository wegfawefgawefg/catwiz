# the hero: Catwiz, a cat wizard in the rigid leaning hat the witch dog wore, three-quarter view
# turned towards the enemies. Its ears come up through two slits in the brim beside the cone:
# half out when calm, popped up long when it attacks, meows or cheers, folded over when it is
# hurt or beaten.
# Every mood only adds to the calm outline (the engine draws a mood patch over the body), and
# the calm and worried faces differ inside the head only, so they swap as one small patch.
#
# moods, in the engine's order, as the battle uses them for the hero: idle; angry (not used:
# the export draws it as attack); worried (low health); hurt; attack (a hiss, fangs
# bared); happy (the meow, a hop, and the win: ^ ^ and an open mouth); ko.

import math

HAT_ANGLE = math.radians(-26)


def cat(c, x, feet, mood="idle"):
    c.rect(x - 4, feet - 9, x - 1, feet, "K")                     # legs
    c.rect(x + 3, feet - 9, x + 6, feet, "K")
    tail(c, x, feet)
    c.poly([(x - 7, feet - 22), (x + 9, feet - 22), (x + 14, feet - 7), (x - 12, feet - 7)], "K")
    hy = feet - 31
    f = x + 2                                                     # face centre, turned right
    head(c, x, f, hy)
    cat_eyes(c, f, hy, mood)
    c.poly([(f + 1, hy + 2), (f + 6, hy + 2), (f + 3, hy + 5)], "V")   # nose
    cat_mouth(c, f, hy, mood)
    hat(c, x, hy, mood)
    c.line(x + 12, feet - 17, x + 25, feet - 28, "W", 2)          # wand
    c.rect(x + 24, feet - 30, x + 28, feet - 26, "W")


def tail(c, x, feet):
    # a grey tail swinging out low behind the robe on the near side, curling up to a white tip
    path = [(x - 9, feet - 8), (x - 18, feet - 8), (x - 23, feet - 12), (x - 24, feet - 18),
            (x - 21, feet - 22), (x - 18, feet - 21)]

    def near(px, py, r):
        for (ax, ay), (bx, by) in zip(path, path[1:]):
            dx, dy = bx - ax, by - ay
            t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
            if (px - ax - t * dx) ** 2 + (py - ay - t * dy) ** 2 <= r * r:
                return True
        return False

    for py in range(feet - 28, feet - 2):
        for px in range(x - 29, x - 4):
            if near(px, py, 3.2):
                c.set(px, py, "K")
    c.grey(x - 29, feet - 28, x - 4, feet - 2, lambda px, py: near(px, py, 2.0))
    c.ellipse(x - 19, feet - 22, 2.5, 2, "W")                     # the white tip


def head(c, x, f, hy):
    # a round head with cheek tufts: a white face
    c.ellipse(x, hy, 12, 10, "K")
    c.poly([(x - 15, hy + 5), (x - 9, hy), (x - 9, hy + 9)], "K")     # cheek tufts
    c.poly([(x + 15, hy + 5), (x + 9, hy), (x + 9, hy + 9)], "K")
    c.ellipse(x, hy, 11, 9, "W")
    for wy, d in ((hy + 5, -1), (hy + 8, 1)):                     # whiskers, past the cheeks
        c.line(x - 13, wy, x - 19, wy + d, "W", 1)
        c.line(x + 12, wy, x + 18, wy + d, "W", 1)


def cat_eyes(c, f, hy, mood):
    for ex, r in ((f - 5, 4), (f + 6, 3)):                        # the far one smaller
        c.ellipse(ex, hy - 2, r + 1, r + 1, "K")
        c.ellipse(ex, hy - 2, r, r, "W")
        if mood == "idle":
            c.ellipse(ex + 1, hy - 2, 1.6, r - 0.5, "K")          # tall cat's pupils
        elif mood == "attack":
            c.rect(ex, hy - 2, ex + 2, hy - 1 + r, "K")           # lids down: a glare
            lid = [(ex - r, hy - r - 2), (ex + r, hy - r - 2)]
            lid.append((ex + r, hy - 1) if ex < f else (ex - r, hy - 1))
            c.poly(lid, "K")
        elif mood == "worried":
            c.ellipse(ex + 1, hy - 1, r - 1, r - 1, "K")          # wide round pupils
            c.rect(ex, hy - 3, ex + 1, hy - 2, "W")
        elif mood == "hurt":
            c.ellipse(ex, hy - 2, r, r, "K")                      # squeezed shut: > <
            c.line(ex - r + 1, hy - 4, ex + r - 1, hy - 2, "W", 1)
            c.line(ex - r + 1, hy, ex + r - 1, hy - 2, "W", 1)
        elif mood == "happy":
            c.ellipse(ex, hy - 2, r, r, "K")                      # closed in a smile: ^ ^
            c.line(ex - r + 1, hy - 1, ex, hy - 4, "W", 2)
            c.line(ex, hy - 4, ex + r - 1, hy - 1, "W", 2)
        elif mood == "ko":
            c.ellipse(ex, hy - 2, r, r, "K")
            c.line(ex - 2, hy - 4, ex + 2, hy, "W", 2)            # x eyes
            c.line(ex + 2, hy - 4, ex - 2, hy, "W", 2)


def cat_mouth(c, f, hy, mood):
    if mood == "attack":
        c.ellipse(f + 3, hy + 7, 4, 3, "K")                       # the hiss: fangs bared
        c.rect(f + 1, hy + 8, f + 6, hy + 10, "V")
        c.poly([(f, hy + 5), (f + 2, hy + 5), (f + 1, hy + 8)], "W")
        c.poly([(f + 5, hy + 5), (f + 7, hy + 5), (f + 6, hy + 8)], "W")
    elif mood == "happy":
        # the meow, and the cheer: ^ ^ and a round open mouth
        c.ellipse(f + 3, hy + 7, 3, 3, "K")
        c.rect(f + 2, hy + 8, f + 5, hy + 10, "V")
    elif mood == "hurt":
        c.line(f - 1, hy + 7, f + 2, hy + 5, "K", 1)              # wobbly
        c.line(f + 2, hy + 5, f + 5, hy + 7, "K", 1)
        c.line(f + 5, hy + 7, f + 8, hy + 5, "K", 1)
    elif mood == "ko":
        c.line(f, hy + 6, f + 7, hy + 6, "K", 1)
        c.rect(f + 4, hy + 6, f + 7, hy + 10, "V")                # tongue out
    elif mood == "worried":
        c.ellipse(f + 3, hy + 7, 2, 2, "K")                       # little o
    else:
        c.line(f + 3, hy + 4, f + 1, hy + 7, "K", 1)              # the cat's w
        c.line(f + 3, hy + 4, f + 5, hy + 7, "K", 1)
        c.line(f + 1, hy + 7, f - 1, hy + 5, "K", 1)
        c.line(f + 5, hy + 7, f + 7, hy + 5, "K", 1)


def hat(c, x, hy, mood):
    # drawn upright, then turned as a whole: the brim stays at a right angle to the cone
    hx, hyb = x - 1, hy - 11                  # high enough to show both eyes

    def turn(pts):
        ca, sa = math.cos(HAT_ANGLE), math.sin(HAT_ANGLE)
        return [(hx + px * ca - py * sa, hyb + px * sa + py * ca) for px, py in pts]

    brim = [(27 * math.cos(t / 20 * 2 * math.pi), 3.5 * math.sin(t / 20 * 2 * math.pi) + 1)
            for t in range(20)]
    c.poly(turn(brim), "K")
    c.poly(turn([(-11, 0), (11, 0), (1, -37), (-1, -37)]), "K")   # cone, sharp
    c.poly(turn([(-11, -1), (11, -1), (10, -5), (-10, -5)]), "V")  # band
    ears(c, turn, mood)


def ears(c, turn, mood):
    # each ear comes up through a slit in the brim, hard against the cone, pointing up and out
    # like a cat's: black with pink insides, a dark shape against the pale sky. calm: half out;
    # popped: long; folded: the tip flopped over outwards, only the black back showing. the near
    # ear is on the left and bigger
    pop = mood in ("attack", "happy")
    fold = mood in ("hurt", "ko")
    for side, size in ((-1, 1.0), (1, 0.85)):
        b0 = (side * 15, 0)
        b1 = (side * 7.5, -6)
        mx, my = (b0[0] + b1[0]) / 2, (b0[1] + b1[1]) / 2
        if pop:
            tip = (mx + side * 1 * size, my - 15 * size)
        else:
            tip = (mx + side * 3 * size, my - 9 * size)
        c.poly(turn([b0, b1, tip]), "K")
        if fold:
            flop = (tip[0] + side * 6 * size, tip[1] + 7 * size)
            c.poly(turn([((tip[0] + b1[0]) / 2, (tip[1] + b1[1]) / 2), tip, flop,
                         ((tip[0] + b0[0]) / 2 + side, (tip[1] + b0[1]) / 2)]), "K")
            continue
        c.poly(turn(inset([b0, b1, tip], 2.6)), "V")


def inset(pts, d):
    # a polygon pulled in towards its middle by about d pixels
    cx = sum(p[0] for p in pts) / len(pts)
    cy = sum(p[1] for p in pts) / len(pts)
    out = []
    for px, py in pts:
        dx, dy = px - cx, py - cy
        n = max(0.01, (dx * dx + dy * dy) ** 0.5)
        k = max(0.0, (n - d) / n)
        out.append((cx + dx * k, cy + dy * k))
    return out
