# the woods' animals, in materials like the cat (light.py colours them for a zone):
#   squirrel  a plump orange squirrel sitting up, a huge curled tail behind it, an acorn in
#             its paws: idle (acorn at the chest), attack (the acorn up over its head, about to
#             throw it, cheeks puffed), hurt (squashed, eyes screwed shut, tail frazzled)
#   possum    a grey possum on all fours, a white pointed face with dark eye patches, round
#             pink ears, a bare pink tail: idle, attack (lunging, jaws wide), hurt (playing
#             dead: on its back, feet up, tongue out, X eyes); and when it gets up again (the
#             possum that faked it, figures.py borrows its block): up (on its hind legs with a
#             sly grin, a leaf stuck on its head) and up_attack (a cheap shot, a sideways swipe)
# everyone faces left, towards the cat. x is the body's middle pixel, feet the row under it.

from canvas import Canvas, sticker
from shade import lit_ellipse, shape_pixels, span_shade, puff

FRAMES = {"squirrel": ["idle", "attack", "hurt"],
          "possum": ["idle", "attack", "hurt", "up", "up_attack"]}

# their shows' sprites (game_sprites SHOW_KEY letters): an acorn thrown, a die snatched; teeth
# marks, a cheap shot's star
SHOTS = {
    "squirrel": [("acorn", ["..O..", ".OOO.", "OOOOO", "YYYYY", "YWYYY", ".YYY.", "..Y.."]),
                 ("die", ["WWWWW", "WPWWW", "WWWWW", "WWWPW", "WWWWW"])],
    "possum": [("bite", ["W.W.W", "WWWWW", ".....", "WWWWW", "W.W.W"]),
               ("smack", ["..Y..", "Y.Y.Y", ".YWY.", "YYWYY", ".YWY.", "Y.Y.Y", "..Y.."])],
}

SQ = ("sq_sh", "sq", "sq_hi")
TAIL = ("tail_sh", "tail", "tail_hi")
POS = ("pos_sh", "pos", "pos_hi")


def eye(c, x, y, kind):
    # a big round eye with a shine, as the cat's; shut ones are lines
    key = {"K": "eye", "W": "shine"}
    rows = {
        "open": [".KK.", "KWKK", "KKKK", "KKKK", ".KK."],
        "fierce": ["K...", "KKK.", "KWKK", "KKKK", ".KK."],
        "shut": ["....", "K..K", ".KK.", "K..K"],
        "sly": ["....", "KKKK", "KWKK", ".KK."],
        "x": ["K.K", ".K.", "K.K"],
    }[kind]
    c.stamp(x, y, rows, key)


def inked(c, cx, cy, rx, ry, mat, test=None):
    # an ellipse with its own black line round it: on the night's black the line is a gap,
    # so a part in front reads apart from the one behind
    c.ellipse(cx, cy, rx + 1, ry + 1.5, "ink", test=test)
    c.ellipse(cx, cy, rx, ry, mat, test=test)


def squirrel(x, feet, frame="idle"):
    # chibi: a head as big as the body, two eyes turned to the cat, a white face and belly,
    # flat orange, the tail a big curl behind with a white tip
    c = Canvas()
    squash = 0.86 if frame == "hurt" else 1.0
    lean = {"attack": 2, "hurt": 1}.get(frame, 0)

    def y(v):
        return feet - v * squash

    # the tail: an S up the back, over the head, its tip curling forward
    tail = [(x + 3, y(2)), (x + 10, y(4)), (x + 15, y(12)), (x + 16, y(24)), (x + 14, y(34)),
            (x + 9, y(42)), (x + 3, y(44)), (x - 1, y(41)), (x + 2, y(37)), (x + 7, y(35)),
            (x + 9, y(28)), (x + 8, y(18)), (x + 4, y(10))]
    c.poly(tail, "tail")
    # its fur lighter inside the curl: an inner band, the tip
    inner = [(x + 6, y(6)), (x + 11, y(11)), (x + 13, y(22)), (x + 12, y(32)), (x + 9, y(38)),
             (x + 7, y(34)), (x + 10, y(28)), (x + 10, y(18)), (x + 7, y(10))]
    c.poly(inner, "tail_hi")
    c.poly([(x + 9, y(40)), (x + 4, y(42.5)), (x + 0.5, y(41)), (x + 3, y(38.5)), (x + 7, y(36.5))], "tail_tip")
    if frame == "hurt":
        # the fur stands on end: spikes cut into the tail's edge
        for dx, dv in ((14, 14), (15, 24), (13, 33)):
            c.line(x + dx - 1, y(dv), x + dx + 1, y(dv + 2), "ink", 1, 1)
    # the body, sitting up: orange with a white belly, feet out in front
    by = y(9)
    inked(c, x + lean * 0.3, by, 5.8, 8.5 * squash, "sq")
    c.ellipse(x - 1.5 + lean * 0.3, by + 1, 3.4, 6.5 * squash, "belly")
    c.ellipse(x - 4.5, y(1.5), 2.8, 1.8, "sq")
    c.ellipse(x + 2.5, y(1.5), 2.6, 1.8, "sq")
    # the head
    hx, hy = x - 2 + lean, y(25)
    for side, ex in ((-1, hx - 4), (1, hx + 4)):
        c.poly([(ex - 3, hy - 6), (ex + 3, hy - 6), (ex + side * 1.5, hy - 16)], "sq")
        c.poly([(ex - 1.5, hy - 7), (ex + 1.5, hy - 7), (ex + side, hy - 13)], "ear_in")
        c.line(ex + side * 1.5, hy - 16, ex + side * 2.5, hy - 19, "tail_hi", 1, 1)  # the tufts
    inked(c, hx, hy, 7.4, 10 * squash, "sq")
    # the white cheeks and muzzle, from just under the eyes
    c.ellipse(hx - 1, hy + 4.5, 6.0, 5.0 * squash, "belly")
    c.rect(hx - 2, hy + 1, hx + 1, hy + 2, "nose")
    key = {"K": "eye", "W": "shine", "M": "mouth"}
    near = {"attack": ["K...", "KKK.", "KWKK", "KKKK", ".KK."],
            "hurt": ["....", "KK..", "..KK", "KK.."]}.get(frame, [".KK.", "KWKK", "KWKK", "KKKK", ".KK."])
    far = {"attack": ["..K", "KKK", "KWK", ".K."],
           "hurt": ["...", "..K", "KK.", "..K"]}.get(frame, [".K.", "KWK", "KKK", ".K."])
    c.stamp(hx - 5, hy - 5, near, key)
    c.stamp(hx + 2, hy - 5, far, key)
    if frame == "attack":
        c.stamp(hx - 2, hy + 3, ["KKKK", "KMMK", ".KK."], key)     # a war cry
    elif frame == "hurt":
        c.stamp(hx - 2, hy + 4, [".KK.", "K..K"], key)
    else:
        c.stamp(hx - 2, hy + 3, ["K..K", ".KK."], key)
    if frame != "hurt":
        c.rect(hx - 7, hy + 1, hx - 5, hy + 2, "blush")
        c.rect(hx + 3, hy + 1, hx + 5, hy + 2, "blush")
    # the paws and the acorn: hugged to the chest, up over the head to throw, or dropped
    if frame == "attack":
        # the arm up past the ear, the acorn held high behind the head, ready to throw
        ax, ay = hx + 3, hy - 20
        c.line(x - 1, by - 6, ax, ay + 5, "sq", 2, 1)
        acorn(c, ax, ay, 1.3)
        c.ellipse(ax, ay + 5, 1.8, 1.5, "sq")
    elif frame == "idle":
        acorn(c, x - 3, by - 2)
        c.ellipse(x - 5, by, 1.8, 1.5, "sq")
        c.ellipse(x - 1, by, 1.8, 1.5, "sq")
    else:
        c.ellipse(x - 4, by - 2, 1.8, 1.5, "sq")
    sticker(c, "ink")
    return c


def acorn(c, ax, ay, k=1.0):
    # a fat acorn: its cap on top, a stalk
    c.ellipse(ax, ay + 2.5 * k, 2.2 * k, 3.4 * k, "acorn")
    c.ellipse(ax - 0.6, ay + 2 * k, 0.8, 1.4 * k, "acorn_hi")
    c.ellipse(ax, ay, 2.6 * k, 2.0 * k, "cap")
    c.set(ax, ay - 2 * k, "cap")


def possum_head(c, hx, hy, frame):
    # the head, big and round: a grey crown, a white face and a short pointed snout towards
    # the cat with a pink nose, grey patches round the eyes, round ears lined pink
    for ex, ey in ((hx - 4, hy - 9), (hx + 5, hy - 8)):
        inked(c, ex, ey, 3.0, 4.2, "pos")
        c.ellipse(ex, ey + 0.5, 1.7, 2.6, "ear_in")
    inked(c, hx, hy, 7.6, 10, "pos_face")
    c.ellipse(hx + 1, hy - 6, 6.5, 4.5, "pos", test=lambda xx, yy: yy < hy - 4)   # the crown
    c.ellipse(hx - 8, hy + 3, 4.2, 2.8, "pos_face")        # the snout
    c.rect(hx - 13, hy + 1, hx - 10, hy + 4, "nose")
    for ex in (hx - 4, hx + 3):
        c.ellipse(ex + 0.5, hy, 2.6, 3.2, "mask")
    key = {"K": "eye", "W": "shine", "M": "mouth", "F": "fang", "T": "tongue"}
    if frame == "attack":
        c.stamp(hx - 6, hy - 3, ["K...", "KKK.", "KWKK", ".KK."], key)
        c.stamp(hx + 2, hy - 3, ["..K", "KKK", "KWK"], key)
        c.stamp(hx - 12, hy + 4, ["FKFKFK", "KMMMMK", "FKFKFK"], key)   # jaws wide
    elif frame == "up":
        c.stamp(hx - 6, hy - 1, ["KKKK", "KWKK", ".KK."], key)          # half shut: sly
        c.stamp(hx + 2, hy - 1, ["KKK", "KWK"], key)
        c.stamp(hx - 9, hy + 5, ["K....", ".KKKK", "...F."], key)       # a lopsided grin
    elif frame == "up_attack":
        c.stamp(hx - 6, hy - 2, ["K...", "KKKK", "KWKK", ".KK."], key)
        c.stamp(hx + 2, hy - 2, ["..K", "KKK", "KWK"], key)
        c.stamp(hx - 10, hy + 4, ["KKKKK", "KMMMK", ".KKK."], key)      # a cackle
    else:
        c.stamp(hx - 6, hy - 2, [".KK.", "KWKK", "KKKK", ".KK."], key)
        c.stamp(hx + 2, hy - 2, [".K.", "KWK", "KKK"], key)
        c.stamp(hx - 9, hy + 5, ["K.F.", ".KK."], key)
    if frame in ("idle", "up"):
        c.rect(hx - 1, hy + 4, hx + 1, hy + 5, "blush")
        c.rect(hx + 5, hy + 4, hx + 7, hy + 5, "blush")


def possum_tail(c, pts):
    for (ax, ay), (bx, by) in zip(pts, pts[1:]):
        c.line(ax, ay, bx, by, "ptail", 2, 2)


def possum(x, feet, frame="idle"):
    if frame == "hurt":
        return possum_dead(x, feet)
    if frame in ("up", "up_attack"):
        return possum_up(x, feet, frame)
    c = Canvas()
    lunge = frame == "attack"
    # the bare pink tail curling up behind
    possum_tail(c, [(x + 10, feet - 8), (x + 15, feet - 9), (x + 18, feet - 14), (x + 18, feet - 20),
                    (x + 15, feet - 23), (x + 13, feet - 20)])
    # four short legs, pink toes, then the plump body
    for lx in (x - 5, x - 1, x + 6, x + 9):
        c.rect(lx, feet - 7, lx + 2, feet - 1, "pos")
        c.rect(lx - 1, feet - 1, lx + 2, feet, "paw_p")
    inked(c, x + 3, feet - 11, 9.0, 8.0, "pos")
    c.ellipse(x + 1, feet - 7, 5.5, 3.5, "pos_hi")      # a paler belly
    for k in range(5):
        c.set(x - 1 + k * 3, feet - 19 + (k % 2), "pos_hi")   # shaggy fur along the back
    if lunge:
        possum_head(c, x - 10, feet - 13, frame)
    else:
        possum_head(c, x - 7, feet - 21, frame)
    sticker(c, "ink")
    return c


def possum_dead(x, feet):
    # playing dead: on its back, four feet in the air, tongue out, X eyes
    c = Canvas()
    for lx, lift in ((x - 4, 0), (x, 1), (x + 5, 0), (x + 8, 1)):
        c.rect(lx, feet - 16 - lift, lx + 2, feet - 9, "pos")
        c.rect(lx - 1, feet - 17 - lift, lx + 2, feet - 16 - lift, "paw_p")
    inked(c, x + 3, feet - 6, 10, 5.5, "pos")
    c.ellipse(x + 3, feet - 8, 6, 3, "pos_hi")
    possum_tail(c, [(x + 12, feet - 3), (x + 17, feet - 2), (x + 20, feet - 4)])
    hx, hy = x - 9, feet - 7
    inked(c, hx, hy, 6.5, 6, "pos_face")
    c.ellipse(hx + 2, hy + 4, 5, 2.5, "pos", test=lambda xx, yy: yy > hy + 3)   # crown, upside down
    c.poly([(hx - 5, hy - 3), (hx - 5, hy + 2), (hx - 11, hy), (hx - 11, hy - 1.5)], "pos_face")
    c.rect(hx - 12, hy - 2, hx - 9, hy + 1, "nose")
    eye(c, hx - 4, hy - 2, "x")
    eye(c, hx + 1, hy - 2, "x")
    c.stamp(hx - 8, hy + 1, ["TT", "TT", ".T"], {"T": "tongue"})   # the tongue lolling out
    sticker(c, "ink")
    return c


def possum_up(x, feet, frame):
    # up on its hind legs again, sly, a leaf stuck on its head from lying in the leaves;
    # up_attack swipes a paw sideways, claws first
    c = Canvas()
    swipe = frame == "up_attack"
    possum_tail(c, [(x + 6, feet - 3), (x + 10, feet - 4), (x + 12, feet - 8), (x + 10, feet - 12)])
    for lx in (x - 4, x + 3):
        c.rect(lx, feet - 5, lx + 2, feet - 1, "pos_sh")
        c.rect(lx - 1, feet - 1, lx + 3, feet, "paw_p")
    inked(c, x, feet - 12, 7.0, 9.0, "pos")
    c.ellipse(x - 1, feet - 10, 3.8, 6.0, "pos_hi")
    hx, hy = x - 2 - (2 if swipe else 0), feet - 28
    possum_head(c, hx, hy, frame)
    c.poly([(hx - 2, hy - 13), (hx + 4, hy - 16), (hx + 7, hy - 12), (hx + 2, hy - 10)], "leaf")
    c.line(hx + 2, hy - 12, hx + 6, hy - 14, "leaf_hi", 1, 1)
    key = {"F": "fang"}
    if swipe:
        # the paw out low at the cat, claws first, a swish behind it
        c.line(x - 4, feet - 14, x - 13, feet - 11, "pos", 2, 2)
        c.ellipse(x - 14, feet - 11, 2.0, 1.8, "paw_p")
        c.stamp(x - 18, feet - 14, ["F...", ".F..", "F...", ".F.."], key)
        for k in range(3):
            c.set(x - 10 + k * 2, feet - 7, "pos_hi")
    else:
        c.line(x - 5, feet - 16, x + 3, feet - 15, "pos", 2, 1)    # arms crossed, smug
        c.line(x - 4, feet - 14, x + 4, feet - 17, "pos_sh", 2, 1)
    sticker(c, "ink")
    return c
