# the Bulldog King, the run's last fight, and his royal pugs, in materials like the cat:
#   king   a big white bulldog in a gold crown and a purple robe trimmed with ermine, sat up on
#          his little gold throne. Three forms, each its own look so the player sees him get up
#          as a new one:
#            the king (first)    smug, heavy-lidded, the crown on straight, paws on his knees
#            cross (second)      scowling under his brows, a cross vein on his brow, the crown
#                                knocked crooked, his arms folded
#            furious (third)     off the throne, up on his hind legs, the robe gone, flushed
#                                red all over, red-eyed and steaming, the crown falling off
#          the first two share their bite (attack: jaws wide) and their knock (hurt: eyes shut,
#          rocked back); the third's attack is a belly flop, in the air
#   pug    a royal pug with a tiny crown: idle, attack (yapping), hurt, happy (cheering the king)
# everyone faces left, towards the cat. x is the body's middle pixel, feet the row under it.
# Memory: the king's frames are narrow (4 groups of 7 pixels, the vet's width) so the three
# forms and the pugs fit the fight's sprite room (art/dhgr/memory.txt)

from canvas import Canvas, sticker
from beasts import inked
from garden_foes import KEY, SHUT, two_eyes

FRAMES = {"king": ["idle", "cross", "attack", "hurt"], "king_furious": ["furious", "flop"],
          "pug": ["idle", "attack", "hurt", "happy"]}
SHOTS = {
    "king": [("chomp", ["WWWWW", "W.W.W", ".....", "W.W.W", "WWWWW"]),
             ("slobber", ["..L..", ".LLL.", "LLWLL", "LWLLL", ".LLL."])],
    "king_furious": [("impact", ["Y.Y.Y", ".YWY.", "YWWWY", ".YWY.", "Y.Y.Y"])],
    "pug": [("yap", ["..W..", ".W.W.", "W...W", ".....", "W.W.W"])],
}


def throne(c, x, feet):
    # a little gold throne behind and under him: a velvet back over his shoulders with a gold
    # rim and knobs, a cushion, gold legs
    c.rect(x - 12, feet - 45, x + 13, feet - 12, "velvet")
    c.rect(x - 12, feet - 46, x + 13, feet - 45, "gold")
    for kx in (x - 12, x + 12):
        c.rect(kx, feet - 46, kx + 1, feet - 12, "gold")
        c.rect(kx, feet - 48, kx + 1, feet - 46, "gold_hi")
    c.rect(x - 12, feet - 12, x + 13, feet - 7, "cushion")
    c.rect(x - 12, feet - 7, x + 13, feet - 5, "gold")
    for lx in (x - 12, x + 11):
        c.rect(lx, feet - 5, lx + 2, feet, "gold")


def crown(c, cx, cy, tilt=0):
    # three points and a band, cy the row under its band
    c.stamp(cx - 6, cy - 7, [
        "Y.....Y.....Y",
        "Y....YYY....Y",
        "YY..YYYYY..YY",
        "YYYYYYYYYYYYY",
    ], {"Y": "gold"})
    c.rect(cx - 6, cy - 3, cx + 7, cy, "gold_hi")
    c.set(cx, cy - 2, "gem")
    c.set(cx - 3, cy - 2, "gem2")
    c.set(cx + 3, cy - 2, "gem2")


def tilted_crown(c, cx, cy, tilt):
    # the crown on a slant: drawn upright on its own canvas, then each column lifted
    k = Canvas()
    crown(k, cx, cy, 0)
    for x in range(cx - 6, cx + 7):
        lift = round(tilt * (cx + 6 - x) / 12.0) if tilt > 0 else round(-tilt * (x - cx + 6) / 12.0)
        for y in range(cy - 8, cy + 1):
            v = k.get(x, y)
            if v is not None:
                c.set(x, y - lift, v)


def head(c, hx, hy, face, mat="dog"):
    # a broad bulldog head: ears folded down at the sides, a brown patch over the far eye, a
    # big black nose, heavy jowls split by the mouth, the underbite's two fangs
    for side in (-1, 1):
        c.poly([(hx + side * 6, hy - 7), (hx + side * 11, hy - 5), (hx + side * 10, hy - 1), (hx + side * 7, hy - 3)], "dog_ear")
    inked(c, hx, hy, 10, 8.5, mat)
    c.ellipse(hx + 5, hy - 5, 3.2, 2.6, "patch")
    inked(c, hx - 4, hy + 4, 5, 3.6, mat)            # the jowls, each its own lobe
    inked(c, hx + 4, hy + 4, 5, 3.6, mat)
    c.rect(hx - 4, hy + 1, hx + 4, hy + 2, "ink")
    c.rect(hx - 2, hy - 1, hx + 2, hy + 1, "dog_nose")
    ex, ey = hx - 7, hy - 4
    key = dict(KEY, R="fury_eye", T="teeth", B="brow", V="vein", P="mouth")
    if face == "smug":
        # heavy lids: the king, pleased with himself
        c.stamp(ex, ey - 1, ["BBBBB....BBBBB", ".KKKK....KKKK.", "..KWK.....KWK."], key)
        c.stamp(hx - 3, hy + 6, ["T....T"], key)
    elif face == "cross":
        # brows down in a V, a glare, the jowls turned down, a cross vein on his brow
        c.stamp(ex, ey - 2, ["BB........BB.", ".BBB....BBB..", "..BKK..KKB...", "..KWK..KWK...", "...K....K...."], key)
        c.stamp(hx - 3, hy + 5, ["TKKKKT"], key)
        c.stamp(hx - 6, hy - 8, ["V.V", ".V.", "V.V"], key)
    elif face == "chomp":
        c.stamp(ex, ey - 2, ["BB.......BB..", ".BB.....BB...", ".KKK....KKK..", ".KWK....KWK..", "..K......K..."], key)
        c.stamp(hx - 5, hy + 2, ["KKKKKKKKKKK", "KTKTKTKTKTK", "KPPPPPPPPPK", "KPPPPPPPPPK", "KTKTKTKTKTK", ".KKKKKKKKK."], key)
    elif face == "hurt":
        two_eyes(c, ex + 1, ey - 1, SHUT[0], SHUT[1], 9)
        c.stamp(hx - 2, hy + 3, [".KK.", "KPPK", "KPPK", ".KK."], key)
    elif face == "furious":
        # red eyes wide under hard brows, every tooth bared, the vein throbbing
        c.stamp(ex - 1, ey - 2, ["BB..........BB", ".BBB......BBB.", "..RRR....RRR..", "..RWR....RWR..", "..RRR....RRR.."], key)
        c.stamp(hx - 5, hy + 2, ["KKKKKKKKKKK", "KTTTTTTTTTK", "KPPPPPPPPPK", "KTTTTTTTTTK", ".KKKKKKKKK."], key)
        c.stamp(hx - 7, hy - 9, ["V.V", ".V.", "V.V"], key)
    elif face == "flop":
        c.stamp(ex, ey, ["BBB.....BBB.", "RRRR....RRRR", ".RR......RR."], key)
        c.stamp(hx - 4, hy + 2, ["KKKKKKKKK", "KPPPPPPPK", "KTTTTTTTK", ".KKKKKKK."], key)


def king(x, feet, frame="idle"):
    # sat up on his throne: idle (the king, smug), cross (his second form), attack (the bite),
    # hurt (rocked back); furious and flop are king_off
    if frame in ("furious", "flop"):
        return king_off(x, feet, frame)
    c = Canvas()
    hurt = frame == "hurt"
    bite = frame == "attack"
    cross = frame == "cross"
    throne(c, x, feet)
    lean = 1 if hurt else 0
    bx = x + lean
    # his body sat up, the pale chest, the robe over his shoulders open down the front
    inked(c, bx, feet - 20, 8.5, 11, "dog")
    c.ellipse(bx, feet - 20, 4.5, 7, "dog_belly")
    for side in (-1, 1):
        c.poly([(bx + side * 2, feet - 32), (bx + side * 11, feet - 31), (bx + side * 12, feet - 8),
                (bx + side * 7, feet - 8), (bx + side * 4, feet - 20)], "robe_k")
        c.line(bx + side * 3, feet - 31, bx + side * 6, feet - 9, "ermine", 1, 1)
    for ex in range(bx - 4, bx + 5, 4):
        c.set(ex, feet - 26 + abs(ex - bx) // 2, "gold")              # the chain of office
    c.rect(bx - 1, feet - 24, bx + 1, feet - 22, "gold")
    if cross:
        # the arms folded across his chest
        for y0, y1 in ((feet - 22, feet - 19), (feet - 18, feet - 21)):
            c.line(bx - 6, y0, bx + 6, y1, "ink", 3, 4)
        for y0, y1 in ((feet - 22, feet - 19), (feet - 18, feet - 21)):
            c.line(bx - 5, y0, bx + 5, y1, "dog", 2, 2)
    elif bite:
        # the front paws up, grabbing at her
        for px in (bx - 6, bx + 5):
            inked(c, px, feet - 25, 2.4, 2, "dog")
    for px in (bx - 5, bx + 5):
        inked(c, px, feet - 8, 2.4, 1.6, "dog")                       # the hind paws
        c.set(px, feet - 8, "ink")
    # the head on top and the crown on it
    hx, hy = x - 1 + 2 * lean, feet - 40 + (2 if hurt else 1 if bite else 0)
    face = {"idle": "smug", "cross": "cross", "attack": "chomp", "hurt": "hurt"}[frame]
    head(c, hx, hy, face)
    if hurt:
        tilted_crown(c, hx + 3, hy - 7, -3)
    elif cross:
        tilted_crown(c, hx + 2, hy - 7, 3)
    else:
        crown(c, hx, hy - 7)
    sticker(c, "ink")
    return c


def king_off(x, feet, frame):
    # furious: off the throne, up on his hind legs, the robe gone, flushed red all over,
    # steaming, his fists up; flop: up in the air for a belly flop, belly first at her
    c = Canvas()
    if frame == "furious":
        for lx in (x - 6, x + 3):
            c.rect(lx - 1, feet - 12, lx + 4, feet, "ink")
            c.rect(lx, feet - 12, lx + 3, feet - 1, "mad")
            c.rect(lx - 1, feet - 2, lx + 4, feet, "mad")
        bx = x
        inked(c, bx, feet - 22, 8.5, 11, "mad")
        c.ellipse(bx, feet - 22, 4.5, 7, "dog_belly")
        for ex in (bx - 6, bx - 4, bx + 3):
            c.rect(ex, feet - 34, ex + 2, feet - 32, "ermine")    # what is left of the collar
        for side in (-1, 1):
            ax = bx + side * 10
            c.line(bx + side * 6, feet - 28, ax, feet - 36, "ink", 3, 4)
            c.line(bx + side * 6, feet - 28, ax, feet - 36, "mad", 2, 2)
            inked(c, ax, feet - 38, 2.4, 2, "mad")
        hx, hy = x - 1, feet - 41
        head(c, hx, hy, "furious", "mad")
        tilted_crown(c, hx + 5, hy - 6, -3)
        for sx, sy in ((hx - 9, hy - 11), (hx - 3, hy - 13)):
            c.stamp(sx, sy, [".S.", "S.S", ".S."], {"S": "steam"})
    else:
        # in the air: belly out at her, the hind legs flung back, the head thrown forward
        lift = 6
        by = feet - 24 - lift
        for lx, ly in ((x + 5, by + 7), (x + 6, by - 1)):
            c.line(lx, ly, lx + 3, ly + 3, "ink", 3, 4)
            c.line(lx, ly, lx + 3, ly + 3, "mad", 2, 2)
        inked(c, x, by, 8.5, 11, "mad")
        c.ellipse(x - 2, by + 1, 5, 8, "dog_belly")
        for ax, ay in ((x - 8, by - 5), (x - 8, by + 6)):
            inked(c, ax, ay, 2.4, 2, "mad")
        hx, hy = x - 1, feet - 41 - lift
        head(c, hx, hy, "flop", "mad")
        tilted_crown(c, hx + 2, hy - 7, 2)
    sticker(c, "ink")
    return c


def pug(x, feet, frame="idle"):
    # a fawn pug, narrow enough for 3 groups of 7 pixels (the fight's sprite room): a black
    # mask, folded ears, a curl of a tail, a little gold crown
    c = Canvas()
    hurt = frame == "hurt"
    yap = frame == "attack"
    cheer = frame == "happy"
    c.ellipse(x + 6, feet - 12, 1.8, 2.2, "pug")
    c.set(x + 7, feet - 14, "pug")
    inked(c, x + 1, feet - 7, 5.5, 5.5, "pug")
    for lx in (x - 3, x + 3):
        c.rect(lx, feet - 3, lx + 2, feet, "pug")
    hx, hy = x - 3, feet - 15 - (2 if cheer else 0)
    inked(c, hx, hy, 5.5, 6, "pug")
    c.ellipse(hx - 1, hy + 2, 4, 3.5, "pug_mask")
    for side in (-1, 1):
        c.poly([(hx + side * 3, hy - 4), (hx + side * 6, hy - 5), (hx + side * 5, hy - 1)], "pug_mask")
    c.stamp(hx - 2, hy - 9, ["Y.Y.Y", "YYYYY", "YWYWY"], {"Y": "gold", "W": "gem2"})
    key = dict(KEY, W="shine")
    if hurt:
        two_eyes(c, hx - 4, hy - 2, SHUT[0], SHUT[1], 5)
    elif cheer:
        two_eyes(c, hx - 4, hy - 2, ["....", ".KK.", "K..K"], ["...", ".K.", "K.K"], 5)
        c.stamp(hx - 2, hy + 2, ["KKK", "KMK"], key)
    else:
        two_eyes(c, hx - 4, hy - 3, [".KK.", "KWKK", "KKKK"], [".K.", "KWK", "KKK"], 5)
        if yap:
            c.stamp(hx - 2, hy + 2, ["KKK", "KMK", ".K."], key)
    if cheer:
        c.line(x + 1, feet - 9, x + 4, feet - 19, "pug", 1, 1)      # a paw up
    sticker(c, "ink")
    return c
