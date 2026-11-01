# the Bulldog King, the run's last fight, and his royal pugs, in materials like the cat:
#   king   a big white bulldog in a gold crown and a purple robe trimmed with ermine, on his
#          velvet couch, his throne. idle: asleep on it, a Z and a string of drool; attack:
#          awake on it, jaws wide; hurt: knocked back on it, his crown askew; cross (his second
#          phase): awake and scowling, the crown crooked, arms folded; furious (his third): off
#          the couch, up on all fours, red-eyed and steaming; flop: in the air for a belly flop
#   pug    a royal pug with a tiny crown: idle, attack (yapping), hurt, happy (cheering the king)
# everyone faces left, towards the cat. x is the body's middle pixel, feet the row under it.

from canvas import Canvas, sticker
from beasts import inked
from garden_foes import KEY, OPEN, SHUT, two_eyes

FRAMES = {"king": ["idle", "attack", "hurt", "cross"], "king_furious": ["furious", "flop"],
          "pug": ["idle", "attack", "hurt", "happy"]}

SHOTS = {
    "king": [("bark", ["...W.", "W..W.", ".W..W", ".W..W", "W..W.", "...W."]),
             ("chomp", ["WWWWW", "W.W.W", ".....", "W.W.W", "WWWWW"]),
             ("zzz", ["WWWW", "..W.", ".W..", "WWWW"]),
             ("slobber", ["..L..", ".LLL.", "LLWLL", "LWLLL", ".LLL."])],
    "king_furious": [("impact", ["Y.Y.Y", ".YWY.", "YWWWY", ".YWY.", "Y.Y.Y"])],
    "pug": [("yap", ["..W..", ".W.W.", "W...W", ".....", "W.W.W"])],
}


def couch(c, x, feet, sag=0):
    # the throne: a velvet couch with a high rolled back, round arms, gold feet and tassels
    c.rect(x - 20, feet - 3, x - 17, feet, "gold")
    c.rect(x + 16, feet - 3, x + 19, feet, "gold")
    inked(c, x + 2, feet - 32, 15, 9, "velvet")                      # the high back
    c.ellipse(x - 2, feet - 36, 8, 3, "velvet_hi")
    for tx in (x - 10, x + 2, x + 13):
        c.set(tx, feet - 23, "gold")                                 # buttons in the back
    c.rect(x - 19, feet - 17, x + 20, feet - 3, "velvet")            # the seat
    c.rect(x - 19, feet - 17 + sag, x + 20, feet - 14 + sag, "cushion")
    inked(c, x - 19, feet - 15, 4, 7, "velvet")                      # the arms
    inked(c, x + 20, feet - 15, 4, 7, "velvet")
    c.ellipse(x - 20, feet - 18, 2.5, 2, "velvet_hi")
    for tx in (x - 14, x - 4, x + 6, x + 16):
        c.rect(tx, feet - 3, tx + 1, feet - 1, "gold")               # tassels along the front


def crown(c, cx, cy, tilt=0):
    pts = [(cx - 6, cy + 1 + tilt), (cx + 6, cy + 1 - tilt), (cx + 7, cy - 5 - tilt), (cx + 4, cy - 2 - tilt),
           (cx + 2, cy - 7), (cx, cy - 2), (cx - 2, cy - 7), (cx - 4, cy - 2 + tilt), (cx - 7, cy - 5 + tilt)]
    c.poly(pts, "gold")
    c.rect(cx - 6, cy - 1, cx + 6, cy + 1, "gold_hi")
    c.set(cx, cy - 1, "gem")
    c.set(cx - 4, cy - 1, "gem2")
    c.set(cx + 4, cy - 1, "gem2")


def dog_head(c, hx, hy, face, scale=1.0):
    # a broad bulldog head: heavy jowls, a squashed nose, little ears, an underbite
    s = scale
    for side in (-1, 1):
        c.poly([(hx + side * 6 * s, hy - 6 * s), (hx + side * 11 * s, hy - 9 * s), (hx + side * 9 * s, hy - 3 * s)], "dog_ear")
    inked(c, hx, hy, 10 * s, 9 * s, "dog")
    c.ellipse(hx - 3 * s, hy + 4 * s, 7 * s, 4.5 * s, "dog_jowl")      # the jowls
    c.ellipse(hx + 4 * s, hy + 4 * s, 5 * s, 4 * s, "dog_jowl")
    c.ellipse(hx - 2 * s, hy - 4 * s, 4 * s, 2 * s, "dog_hi")
    c.rect(hx - 5 * s, hy + 1 * s, hx - 1 * s, hy + 3 * s, "dog_nose")
    fx, fy = int(hx - 8 * s), int(hy - 4 * s)
    key = dict(KEY, R="red_eye", T="teeth", D="drool")
    if face == "asleep":
        c.stamp(fx, fy, ["....", "KKKK", ".KK."], key)
        c.stamp(fx + 9, fy, ["...", "KKK", ".K."], key)
        c.stamp(fx + 1, fy + 9, ["KKKKK", ".TKT."], key)
        c.stamp(fx + 2, fy + 11, ["D", "D", "D"], key)                 # a string of drool
    elif face == "chomp":
        c.stamp(fx, fy - 1, ["K...", "KKK.", "KWKK", ".KK."], key)
        c.stamp(fx + 9, fy - 1, ["..K", "KKK", "KWK"], key)
        c.stamp(fx - 1, fy + 7, ["KKKKKKKK", "KTTKTTKK", "KMMMMMMK", "KMMMMMMK", "KTKTTKTK", ".KKKKKK."], key)
    elif face == "hurt":
        two_eyes(c, fx, fy, SHUT[0], SHUT[1], 9)
        c.stamp(fx + 1, fy + 9, [".KKK.", "K...K"], key)
    elif face == "cross":
        c.stamp(fx - 1, fy - 2, ["KK...", ".KKK.", "..KKK", ".KWKK", ".KKK."], key)
        c.stamp(fx + 8, fy - 2, ["..KK", "KKK.", "KKK.", "KWK.", "KK.."], key)
        c.stamp(fx + 1, fy + 9, ["KKKKK", "TKTKT"], key)               # the underbite, sulking
    elif face == "furious":
        c.stamp(fx - 1, fy - 2, ["KK...", ".KKK.", "RRKKK", "RRRKK", ".RRK."], key)
        c.stamp(fx + 8, fy - 2, ["..KK", "KKK.", "KKRR", "KRRR", ".KR."], key)
        c.stamp(fx, fy + 8, ["KKKKKKK", "KTMTMTK", "KMMMMMK", ".KKKKK."], key)


def king(x, feet, frame="idle"):
    c = Canvas()
    if frame in ("furious", "flop"):
        return king_off(x, feet, frame)
    hurt = frame == "hurt"
    couch(c, x, feet, 1 if hurt else 0)
    # his big round body slumped on the cushion, the robe over his shoulders
    bx, by = x + 1, feet - 22
    inked(c, x - 13, feet - 21, 6, 4, "robe_k")                      # the robe over the arm
    inked(c, bx, by, 13, 11, "dog")
    c.ellipse(bx - 3, by + 3, 7, 6, "dog_belly")
    c.poly([(bx - 12, by - 9), (bx + 13, by - 9), (bx + 15, by + 6), (bx + 8, by + 9), (bx + 11, by - 2),
            (bx - 9, by - 2), (bx - 12, by + 8), (bx - 15, by + 5)], "robe_k")
    for ex in range(-11, 14, 3):
        c.set(bx + ex, by - 8 + (ex % 2), "ermine")
        c.set(bx + ex + 1, by - 9, "ermine_dot")
    # his paws: folded when he is cross, out on the cushion otherwise
    if frame == "cross":
        c.line(bx - 7, by + 2, bx + 6, by + 3, "dog", 3, 3)
        c.line(bx - 6, by + 5, bx + 7, by + 1, "dog_belly", 2, 2)
    else:
        c.ellipse(bx - 9, by + 9, 3.5, 2.5, "dog")
        c.ellipse(bx + 8, by + 9, 3.5, 2.5, "dog")
    # the head on top, the crown on his head
    hx, hy = x - 2 + (2 if hurt else 0), feet - 42 + (2 if hurt else 0)
    face = {"idle": "asleep", "attack": "chomp", "hurt": "hurt", "cross": "cross"}[frame]
    dog_head(c, hx, hy, face)
    tilt = {"hurt": 2, "cross": 1}.get(frame, 0)
    crown(c, hx + 1 + (5 if hurt else 0), hy - 10 - (2 if hurt else 0), tilt)
    if frame == "idle":
        c.stamp(hx + 9, hy - 20, ["WWW", "..W", ".W.", "WWW"], {"W": "zzz"})   # asleep
    sticker(c, "ink")
    return c


def king_off(x, feet, frame):
    # furious: off the couch on all fours, steam off him; flop: up in the air, belly first
    c = Canvas()
    flop = frame == "flop"
    lift = 8 if flop else 0
    if not flop:
        for lx in (x - 9, x - 3, x + 5, x + 10):
            c.rect(lx, feet - 8, lx + 3, feet - 1, "dog")
            c.rect(lx - 1, feet - 1, lx + 4, feet, "dog_belly")
    else:
        for lx, ly in ((x - 12, feet - 18), (x - 5, feet - 14), (x + 6, feet - 14), (x + 12, feet - 18)):
            c.line(lx, ly, lx + (1 if lx > x else -1) * 3, ly + 5, "dog", 3, 2)   # legs flung out
    bx, by = x + 1, feet - 15 - lift
    inked(c, bx, by, 13, 9, "dog")
    c.ellipse(bx - 2, by + 4, 9, 4, "dog_belly")
    c.poly([(bx - 6, by - 9), (bx + 14, by - 8), (bx + 16, by + 3), (bx + 9, by + 1)], "robe_k")   # the robe
    c.set(bx + 16, by + 4, "ermine")
    hx, hy = x - 12, feet - 22 - lift
    dog_head(c, hx, hy, "furious" if not flop else "chomp")
    crown(c, hx + 2, hy - 10, -1 if flop else 1)
    if not flop:
        for k in range(4):
            c.set(hx - 4 + k * 3, hy - 18 - (k % 2) * 2, "steam")
            c.set(hx - 3 + k * 3, hy - 20 - (k % 2) * 2, "steam")
    sticker(c, "ink")
    return c


def pug(x, feet, frame="idle"):
    c = Canvas()
    hurt = frame == "hurt"
    yap = frame == "attack"
    cheer = frame == "happy"
    # a stout little body, a curly tail
    c.ellipse(x + 8, feet - 12, 2.2, 2.5, "pug")
    c.set(x + 9, feet - 14, "pug")
    inked(c, x + 1, feet - 7, 7, 5.5, "pug")
    for lx in (x - 4, x + 4):
        c.rect(lx, feet - 3, lx + 2, feet, "pug")
    # the head, a black mask, a tiny crown
    hx, hy = x - 4, feet - 15 - (2 if cheer else 0)
    inked(c, hx, hy, 6.5, 6, "pug")
    c.ellipse(hx - 1, hy + 2, 4.5, 3.5, "pug_mask")
    for side in (-1, 1):
        c.poly([(hx + side * 4, hy - 4), (hx + side * 7, hy - 6), (hx + side * 6, hy - 1)], "pug_mask")
    c.poly([(hx - 3, hy - 6), (hx + 3, hy - 6), (hx + 3, hy - 9), (hx + 1, hy - 7.5), (hx, hy - 10),
            (hx - 1, hy - 7.5), (hx - 3, hy - 9)], "gold")
    key = dict(KEY, W="shine")
    if hurt:
        two_eyes(c, hx - 5, hy - 2, SHUT[0], SHUT[1], 6)
    elif cheer:
        two_eyes(c, hx - 5, hy - 2, ["....", ".KK.", "K..K"], ["...", ".K.", "K.K"], 6)
        c.stamp(hx - 3, hy + 2, ["KKK", "KMK"], key)
    else:
        two_eyes(c, hx - 5, hy - 3, [".KK.", "KWKK", "KKKK"], [".K.", "KWK", "KKK"], 6)
        if yap:
            c.stamp(hx - 3, hy + 2, ["KKK", "KMK", ".K."], key)
    if cheer:
        c.line(x - 1, feet - 10, x - 5, feet - 22, "pug", 1, 1)      # a paw up
    sticker(c, "ink")
    return c
