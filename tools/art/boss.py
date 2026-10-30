# the final boss: a big smug bulldog king, turned left towards the cat. A broad grey head with
# heavy jowls and an underbite (two fangs up), small folded ears, a black patch round one eye,
# a little crooked crown, a spiked collar, a cape to the ground and a bone for a sceptre. Every
# face sits inside the head, so the moods swap as one patch.
#
# moods, in the engine's order: idle (smug), angry (the snarl before it hits), worried (low
# health), hurt, attack (falls back to angry), happy (a laugh), ko.


def boss_dog(c, x, feet, mood="idle"):
    f = feet
    c.rect(x - 11, f - 11, x - 4, f, "K")                        # legs
    c.rect(x + 5, f - 11, x + 12, f, "K")
    c.poly([(x - 19, f - 40), (x + 17, f - 40), (x + 25, f - 8), (x + 21, f - 5),
            (x - 20, f - 5), (x - 24, f - 8)], "K")              # the cape
    c.poly([(x - 20, f - 28), (x - 17, f - 38), (x - 13, f - 38), (x - 14, f - 8),
            (x - 21, f - 8)], "V")                               # its lining, on the near edge
    c.poly([(x - 10, f - 40), (x + 6, f - 40), (x - 2, f - 24)], "W")   # chest
    c.rect(x - 15, f - 43, x + 12, f - 39, "K")                  # the spiked collar
    for sx in range(x - 13, x + 11, 6):
        c.poly([(sx, f - 39), (sx + 3, f - 39), (sx + 1.5, f - 34)], "W")
    sceptre(c, x - 21, f)
    hy = f - 52
    hx = x + 4                                                   # the head sits a little forward
    head(c, hx, hy)
    face(c, hx, hy, mood)
    crown(c, hx + 4, hy - 13)


def sceptre(c, x, f):
    # a big bone held upright in the near paw
    c.rect(x - 1, f - 42, x + 3, f - 8, "W")
    for kx, ky in ((x - 2, f - 44), (x + 4, f - 44), (x - 2, f - 8), (x + 4, f - 8)):
        c.ellipse(kx, ky, 3, 3, "W")
    c.ellipse(x + 2, f - 25, 5, 4, "K")                          # the paw round it
    c.rect(x, f - 26, x + 5, f - 25, "W")


def head(c, x, hy):
    # a broad white head, the face turned left: rose ears folded out and down at the top
    # corners, a grey brow with wrinkles, a black patch round the near eye, and the jowls
    # hanging low on either side of the jutting jaw
    c.poly([(x - 12, hy - 11), (x - 20, hy - 12), (x - 23, hy - 4), (x - 18, hy - 6)], "K")   # far ear
    c.poly([(x + 6, hy - 12), (x + 16, hy - 13), (x + 20, hy - 4), (x + 14, hy - 6)], "K")    # near ear
    c.ellipse(x - 2, hy, 17, 12, "K")
    c.ellipse(x - 2, hy, 16, 11, "W")
    c.grey(x - 19, hy - 12, x + 16, hy - 6,
           lambda px, py: ((px - x + 2) / 16) ** 2 + ((py - hy) / 11) ** 2 <= 1)
    c.ellipse(x + 4, hy - 3, 6, 5, "K")                          # the patch round the near eye
    c.ellipse(x - 17, hy + 9, 7, 6, "K")                         # jowls
    c.ellipse(x - 17, hy + 9, 6, 5, "W")
    c.ellipse(x + 2, hy + 9, 7, 6, "K")
    c.ellipse(x + 2, hy + 9, 6, 5, "W")
    c.ellipse(x - 7, hy + 3, 5, 2.5, "K")                        # the big nose
    c.rect(x - 10, hy + 2, x - 8, hy + 3, "W")


def face(c, x, hy, mood):
    # the eyes (the far one, left, smaller; the near one in its black patch) and the jaw
    # between the jowls: an underbite, two fangs pointing up
    eyes = ((x - 15, hy - 3, 3), (x + 4, hy - 2, 4))
    jaw = (x - 8, hy + 9)
    c.ellipse(eyes[0][0], eyes[0][1], 4, 4, "K")                 # the far eye's dark rim

    def fangs(y):
        for fx in (jaw[0] - 4, jaw[0] + 3):
            c.poly([(fx, y), (fx + 2, y), (fx + 1, y - 4)], "W")

    if mood in ("idle", "angry", "attack"):
        for ex, ey, r in eyes:
            c.ellipse(ex, ey, r, r - 1, "W")
            c.rect(ex - 2, ey - 1, ex, ey + r - 1, "K")          # pupils, looking left
        if mood == "idle":
            for ex, ey, r in eyes:
                c.rect(ex - r, ey - r, ex + r, ey, "K")          # heavy lids: smug
                c.line(ex - r - 1, ey - r - 1, ex + r - 1, ey - r + 1, "K", 2)
            c.ellipse(jaw[0], jaw[1], 6, 2, "K")                 # a closed grin, fangs up
            c.line(jaw[0] + 5, jaw[1] - 1, jaw[0] + 8, jaw[1] - 4, "K", 1)
            fangs(jaw[1])
        else:
            for ex, ey, r in eyes:                               # brows down hard: a glare
                c.poly([(ex - r, ey - r - 2), (ex + r, ey - r - 2),
                        (ex + r if ex > x - 6 else ex - r, ey)], "K")
            c.ellipse(jaw[0], jaw[1], 7, 3, "K")                 # snarl: open, all teeth
            for tx in range(jaw[0] - 5, jaw[0] + 5, 3):
                c.rect(tx, jaw[1] - 3, tx + 2, jaw[1] - 2, "W")
            fangs(jaw[1] + 2)
    elif mood == "worried":
        for ex, ey, r in eyes:
            c.ellipse(ex, ey, r, r, "W")
            c.rect(ex - 1, ey, ex + 1, ey + 2, "K")              # small pupils
            c.line(ex - r, ey - r, ex + r, ey - r - 2, "K", 1)   # brows up
        c.line(jaw[0] - 6, jaw[1] + 1, jaw[0] - 3, jaw[1] - 1, "K", 1)   # wobbly
        c.line(jaw[0] - 3, jaw[1] - 1, jaw[0], jaw[1] + 1, "K", 1)
        c.line(jaw[0], jaw[1] + 1, jaw[0] + 3, jaw[1] - 1, "K", 1)
        c.line(jaw[0] + 3, jaw[1] - 1, jaw[0] + 6, jaw[1] + 1, "K", 1)
    elif mood == "hurt":
        for ex, ey, r in eyes:                                   # > <
            c.ellipse(ex, ey, r, r, "K")
            c.line(ex - r + 1, ey - 2, ex + r - 1, ey, "W", 1)
            c.line(ex - r + 1, ey + 2, ex + r - 1, ey, "W", 1)
        c.ellipse(jaw[0], jaw[1], 4, 3, "K")                     # yelp
        fangs(jaw[1] + 2)
    elif mood == "happy":
        for ex, ey, r in eyes:                                   # a laugh: eyes shut ^ ^
            c.ellipse(ex, ey, r, r, "K")
            c.line(ex - r + 1, ey + 1, ex, ey - 2, "W", 2)
            c.line(ex, ey - 2, ex + r - 1, ey + 1, "W", 2)
        c.ellipse(jaw[0], jaw[1], 7, 4, "K")
        c.rect(jaw[0] - 3, jaw[1] + 1, jaw[0] + 3, jaw[1] + 4, "V")
        fangs(jaw[1] + 2)
    elif mood == "ko":
        for ex, ey, r in eyes:                                   # x x
            c.ellipse(ex, ey, r, r, "K")
            c.line(ex - 2, ey - 2, ex + 2, ey + 2, "W", 2)
            c.line(ex + 2, ey - 2, ex - 2, ey + 2, "W", 2)
        c.line(jaw[0] - 6, jaw[1], jaw[0] + 6, jaw[1], "K", 1)
        c.rect(jaw[0] - 1, jaw[1], jaw[0] + 3, jaw[1] + 3, "V")  # tongue out


def crown(c, x, y):
    # a small white crown worn crooked on the crown of the head, a violet jewel in it
    pts = [(x - 9, y + 5), (x + 7, y + 3), (x + 8, y - 5), (x + 4, y - 1), (x + 1, y - 7),
           (x - 2, y - 1), (x - 7, y - 4)]
    c.poly(pts, "W")
    c.rect(x - 1, y + 1, x + 2, y + 3, "V")
