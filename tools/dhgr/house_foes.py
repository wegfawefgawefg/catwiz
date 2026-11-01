# the house's enemies, in materials like the cat (light.py colours them for a zone):
#   dustbunny  a fluffy ball of grey dust with bunny ears and specks of lint: idle, attack (a
#              big sneeze, eyes screwed shut, dust flying), hurt (squashed flat)
#   roomba     a round robot vacuum, low on the floor, two little screen eyes on its lid and a
#              light on top: idle, attack (full speed, tipped up, speed lines), hurt (spinning
#              round, sparks), happy (beeping, its light on, eyes happy)
#   hoover     Hoover Jr., an upright vacuum cleaner, its bag a face, a hose curled round it:
#              idle, attack (the bag puffed, the nozzle out, sucking), hurt (the bag gone limp),
#              happy (honking its hose: calling the dust bunnies)
#   vet        the vet, a door's elite: a tall vet in a white coat, a head mirror, a stethoscope:
#              idle, attack (a needle up, a gleeful grin), hurt, happy (snapping on a glove)
#   bath       the big bath, the other door's elite: a clawfoot tub brimming with suds, its taps
#              eyes, its rim a grin: idle, attack (water sloshing over its rim), hurt (cracked,
#              water spilling out)
#   gremlin    the drain gremlin, what the bath becomes: a slimy little gremlin with a plug on
#              its chain: idle, attack (lunging, mouth wide), hurt, happy (gurgling, bubbles)
# everyone faces left, towards the cat. x is the body's middle pixel, feet the row under it.

import math
import random

from canvas import Canvas, sticker, fill_holes
from beasts import inked
from garden_foes import KEY, OPEN, FIERCE, SHUT, two_eyes

FRAMES = {"dustbunny": ["idle", "attack", "hurt"],
          "roomba": ["idle", "attack", "hurt", "happy"],
          "hoover": ["idle", "attack", "hurt", "happy"],
          "vet": ["idle", "attack", "hurt", "happy"],
          "bath": ["idle", "attack", "hurt"],
          "gremlin": ["idle", "attack", "hurt", "happy"]}

SHOTS = {
    "dustbunny": [("sneeze", [".W.W.", "W.W.W", ".WWW.", "W.W.W", ".W.W."]),
                  ("hairball", [".OOO.", "OOYOO", "OYOOO", "OOOYO", ".OOO."])],
    "roomba": [("beep", ["..Y..", ".YWY.", "YWWWY", ".YWY.", "..Y.."]),
               ("bump", ["W...W", ".W.W.", "..W..", ".W.W.", "W...W"])],
    "hoover": [("suck", ["L.L.L", ".L.L.", "..W..", ".L.L.", "L.L.L"]),
               ("honk", ["...Y", "..YY", "YYYY", "..YY", "...Y"])],
    "vet": [("needle", [".W..", ".W..", "LWL.", "LWL.", "LWL.", "LWL.", ".R..", ".R.."]),
            ("thermo", ["..W", ".WR", "W.R", "..R", "..R"])],
    "bath": [("splash", ["..L..", ".L.L.", "L.W.L", ".LWL.", "LLWLL", ".LLL."]),
             ("hairball", [".OOO.", "OOYOO", "OYOOO", "OOOYO", ".OOO."])],
    "gremlin": [("bubbles", [".A..A", "A.A..", ".A..A", "..A.A", "A..A."])],
}


def fluff(c, cx, cy, rx, ry, mat, seed, n=26):
    # a fuzzy ball: an ellipse with tufts poking out round its edge
    c.ellipse(cx, cy, rx, ry, mat)
    rnd = random.Random(seed)
    for k in range(n):
        t = k / n * 2 * math.pi + rnd.uniform(-0.1, 0.1)
        r = rnd.uniform(1.0, 1.25)
        c.set(cx + math.cos(t) * rx * r, cy + math.sin(t) * ry * r, mat)


# ---- the dust bunny

def dustbunny(x, feet, frame="idle"):
    c = Canvas()
    hurt = frame == "hurt"
    sneeze = frame == "attack"
    ry = 6.0 if hurt else 9.0
    cy = feet - ry - 1
    # the ears, long and floppy, one bent
    for side, lean, h in ((-1, -2, 13), (1, 3, 11)):
        ex = x + side * 3
        c.poly([(ex - 2, cy - ry + 3), (ex + 2, cy - ry + 3), (ex + lean + 1, cy - ry - h), (ex + lean - 1, cy - ry - h)], "dust_b")
        c.poly([(ex - 0.8, cy - ry + 2), (ex + 0.8, cy - ry + 2), (ex + lean, cy - ry - h + 3)], "ear_in")
    if hurt:
        cy += 1
    fluff(c, x, cy, 8.5 * (1.15 if hurt else 1.0), ry, "dust_b", 3)
    c.ellipse(x + 4, cy - ry * 0.55, 2.5, ry * 0.25, "dust_hi")
    # specks of lint stuck in it
    for dx, dy, m in ((4, -3, "lint"), (-5, 3, "lint2"), (3, 4, "lint"), (6, 1, "lint2")):
        c.set(x + dx, cy + dy, m)
    fx, fy = x - 6, cy - 3
    c.ellipse(x - 2, cy + 1, 6.0, ry * 0.55, "dust_face")              # a paler face
    if sneeze:
        two_eyes(c, fx, fy, ["....", "KK..", "..KK"], ["...", "..K", "KK."], 5)
        c.stamp(fx + 1, fy + 4, ["KKK", "KMK", "KKK"], KEY)
        for k, (dx, dy) in enumerate(((-4, 1), (-7, -1), (-6, 3), (-9, 2), (-10, -2))):
            c.set(fx + dx, fy + dy, "dust_hi" if k % 2 else "dust_b")
    elif hurt:
        two_eyes(c, fx, fy, SHUT[0], SHUT[1], 5)
        c.stamp(fx + 1, fy + 5, [".K.", "K.K"], KEY)
    else:
        two_eyes(c, fx, fy, OPEN[0], OPEN[1], 5)
        c.stamp(fx + 1, fy + 5, ["K.K", ".K."], KEY)
        c.rect(fx - 1, fy + 4, fx + 1, fy + 5, "blush")
        c.rect(fx + 8, fy + 4, fx + 10, fy + 5, "blush")
    sticker(c, "ink")
    return c


# ---- the roomba

def roomba(x, feet, frame="idle"):
    c = Canvas()
    zoom = frame == "attack"
    hurt = frame == "hurt"
    lift = 3 if zoom else 0
    # the drum: a low round side band (its face on it), the lid on top, a light on the lid
    top = feet - 15 - lift
    c.ellipse(x, feet - 5 - lift // 2, 15, 5, "ink")
    c.ellipse(x, feet - 5 - lift // 2, 14, 4.5, "rmb_sh")
    c.rect(x - 14, top + 4, x + 15, feet - 5 - lift // 2, "rmb_side")
    c.ellipse(x, top + 4, 15, 4.5, "ink")
    c.ellipse(x, top + 4, 14, 4, "rmb")
    c.ellipse(x + 3, top + 3, 7, 1.6, "rmb_hi")
    light = "led_on" if frame in ("happy", "attack") else "led"
    c.ellipse(x + 6, top + 1, 1.8, 1.4, light)
    if frame == "happy":
        for k in (-3, 0, 3):
            c.set(x + 6 + k, top - 3 - abs(k) // 3, "led_on")       # its light shining
    c.rect(x - 14, top + 9, x - 4, top + 11, "bumper")               # the bumper's front
    # the face: two screen eyes on the side band, towards the cat
    fx, fy = x - 10, top + 6
    key = {"K": "eye", "S": "screen", "W": "shine", "M": "mouth"}
    if hurt:
        c.stamp(fx, fy, ["S.S", ".S.", "S.S"], key)
        c.stamp(fx + 6, fy, ["S.S", ".S.", "S.S"], key)
        for dx, dy in ((-3, -4), (6, -6), (13, -3)):
            c.set(x + dx, top + dy, "spark")                         # sparks off it
            c.set(x + dx + 1, top + dy + 1, "spark")
    elif frame == "happy":
        c.stamp(fx, fy, [".SS.", "S..S"], key)
        c.stamp(fx + 6, fy, [".SS.", "S..S"], key)
    elif zoom:
        c.stamp(fx, fy, ["SSSS", "SSKK", "SSKK"], key)
        c.stamp(fx + 6, fy, ["SSSS", "SSKK", "SSKK"], key)
        for k in range(3):
            c.rect(x + 16, top + 4 + k * 3, x + 23 - k * 2, top + 5 + k * 3, "speed")    # speed lines
    else:
        c.stamp(fx, fy, ["SSSS", "SKKS", "SKWS", "SSSS"], key)
        c.stamp(fx + 6, fy, ["SSSS", "SKKS", "SKWS", "SSSS"], key)
    sticker(c, "ink")
    return c


# ---- Hoover Jr.

def hoover(x, feet, frame="idle"):
    c = Canvas()
    suck = frame == "attack"
    hurt = frame == "hurt"
    # the base with its brush, two little wheels
    c.rect(x - 10, feet - 6, x + 9, feet - 1, "hv_base")
    c.rect(x - 11, feet - 2, x + 10, feet - 1, "hv_brush")
    for wx in (x - 7, x + 6):
        c.ellipse(wx, feet - 1, 2.0, 1.8, "wheel")
    # the handle up behind, its grip
    c.line(x + 4, feet - 30, x + 7, feet - 52, "handle", 1, 2)
    c.rect(x + 4, feet - 55, x + 11, feet - 52, "grip")
    # the bag: a big soft sack with a face, puffed when it sucks, limp when hurt
    rx, ry = (11, 15) if suck else (8, 12) if hurt else (9.5, 14)
    by = feet - 6 - ry
    inked(c, x, by, rx, ry, "hv_bag")
    c.ellipse(x - rx * 0.45, by - ry * 0.6, rx * 0.25, ry * 0.2, "hv_bag_hi")
    for k in range(3):
        c.rect(x - rx + 2, by - 6 + k * 6, x - rx + 4, by - 5 + k * 6, "hv_stripe")
    if hurt:
        for dy in (-4, 2):
            c.line(x - 5, by + dy, x + 5, by + dy + 1, "hv_bag_sh", 1, 1)     # creases
    # the hose: from the base round the front, its nozzle out at the cat when it sucks
    if suck:
        c.line(x - 8, feet - 5, x - 18, feet - 12, "hose", 2, 2)
        c.rect(x - 23, feet - 15, x - 18, feet - 9, "nozzle")
        for k in range(3):
            c.set(x - 25 - k * 2, feet - 13 + k, "hv_air")
    elif frame == "happy":
        c.line(x - 8, feet - 5, x - 13, feet - 20, "hose", 2, 2)
        c.rect(x - 16, feet - 26, x - 11, feet - 20, "nozzle")       # held up like a trumpet
    else:
        c.line(x - 8, feet - 5, x - 12, feet - 14, "hose", 2, 2)
        c.line(x - 12, feet - 14, x - 9, feet - 22, "hose", 2, 2)
        c.rect(x - 11, feet - 26, x - 7, feet - 22, "nozzle")
    # the face on the bag
    fx, fy = x - 6, by - 3
    if hurt:
        two_eyes(c, fx, fy, SHUT[0], SHUT[1], 7)
        c.stamp(fx + 2, fy + 6, [".KK.", "K..K"], KEY)
    elif suck:
        two_eyes(c, fx, fy, FIERCE[0], FIERCE[1], 7)
        c.stamp(fx + 2, fy + 6, [".KK.", "KMMK", "KMMK", ".KK."], KEY)    # sucking in
    elif frame == "happy":
        two_eyes(c, fx, fy, ["....", ".KK.", "K..K"], ["...", ".K.", "K.K"], 7)
        c.stamp(fx + 2, fy + 6, ["KKKK", "KMMK", ".KK."], KEY)
    else:
        two_eyes(c, fx, fy, OPEN[0], OPEN[1], 7)
        c.stamp(fx + 2, fy + 6, ["K..K", ".KK."], KEY)
        c.rect(fx - 1, fy + 5, fx + 1, fy + 6, "blush")
        c.rect(fx + 10, fy + 5, fx + 12, fy + 6, "blush")
    sticker(c, "ink")
    return c


# ---- the vet

def vet(x, feet, frame="idle"):
    c = Canvas()
    jab = frame == "attack"
    hurt = frame == "hurt"
    # shoes, legs, the long white coat
    for lx in (x - 4, x + 2):
        c.rect(lx, feet - 8, lx + 3, feet - 2, "trousers_v")
        c.rect(lx - 1, feet - 2, lx + 4, feet, "shoe")
    coat = [(x - 9, feet - 8), (x - 8, feet - 40), (x + 8, feet - 40), (x + 10, feet - 8)]
    c.poly([(px + (1 if px > x else -1), py) for px, py in coat], "ink")
    c.poly(coat, "coat_v")
    c.poly([(x - 2, feet - 40), (x + 2, feet - 40), (x, feet - 30)], "scrubs")
    c.line(x, feet - 30, x, feet - 9, "coat_v_sh", 1, 1)
    c.rect(x + 3, feet - 26, x + 7, feet - 23, "pocket")
    c.set(x + 5, feet - 27, "pen")
    # the stethoscope round the neck
    c.line(x - 5, feet - 40, x - 4, feet - 30, "steth", 1, 1)
    c.line(x + 5, feet - 40, x + 3, feet - 31, "steth", 1, 1)
    c.ellipse(x - 0.5, feet - 29, 1.6, 1.4, "steth_hi")
    # the head: a round face, glasses, a head mirror on a band, a tuft of hair
    hx, hy = x - 1, feet - 48 + (2 if hurt else 0)
    inked(c, hx, hy, 6.5, 7.5, "skin_v")
    c.ellipse(hx + 2, hy - 6, 5.5, 2.5, "hair_v")
    c.rect(hx - 6, hy - 5, hx + 7, hy - 4, "band_v")
    c.ellipse(hx + 1, hy - 8, 2.6, 2.6, "mirror")
    c.set(hx + 0, hy - 9, "shine")
    key = dict(KEY, G="glasses")
    if hurt:
        c.stamp(hx - 7, hy - 3, [".GG...GG.", "G..G.G..G", "GKKG.GKKG", ".GG...GG."], key)
        c.stamp(hx - 3, hy + 3, [".KK.", "K..K"], KEY)
        c.ellipse(hx + 6, hy - 10, 2.0, 1.6, "mirror")             # the mirror knocked askew
    else:
        eye = "GKWG" if not jab else "GWKG"
        c.stamp(hx - 7, hy - 3, [".GG...GG.", eye + "." + eye, "GKKG.GKKG", ".GG...GG."], key)
        if jab:
            c.stamp(hx - 4, hy + 3, ["KKKKK", "KWWWK", ".KKK."], dict(KEY, W="teeth"))   # a gleeful grin
        elif frame == "happy":
            c.stamp(hx - 3, hy + 3, ["K...K", ".KKK."], KEY)
        else:
            c.stamp(hx - 3, hy + 3, [".KKK."], KEY)
        c.rect(hx + 3, hy + 2, hx + 5, hy + 3, "blush")
    # the arms: a needle up, or snapping on a glove, or at the sides
    if jab:
        c.line(x - 8, feet - 36, x - 12, feet - 52, "coat_v", 2, 2)
        c.rect(x - 14, feet - 60, x - 11, feet - 52, "syringe")
        c.rect(x - 13, feet - 64, x - 12, feet - 60, "needle_v")
        c.rect(x - 15, feet - 52, x - 10, feet - 51, "syringe")
    elif frame == "happy":
        c.line(x - 8, feet - 36, x - 12, feet - 30, "coat_v", 2, 2)
        c.rect(x - 15, feet - 34, x - 11, feet - 28, "glove")
        c.rect(x - 18, feet - 30, x - 15, feet - 29, "glove")        # the cuff stretched
        for k in range(3):
            c.set(x - 20 + k * 2, feet - 37 + (k % 2), "snap")
    else:
        c.line(x - 8, feet - 36, x - 10, feet - 22, "coat_v", 2, 2)
        c.rect(x - 12, feet - 22, x - 8, feet - 18, "glove")
        c.rect(x - 14, feet - 30, x - 10, feet - 24, "clipboard")
    sticker(c, "ink")
    return c


# ---- the big bath

def bath(x, feet, frame="idle"):
    c = Canvas()
    slosh = frame == "attack"
    hurt = frame == "hurt"
    # four clawed feet
    for fx in (x - 14, x - 6, x + 6, x + 14):
        c.ellipse(fx, feet - 2, 2.2, 2.0, "claw")
        c.set(fx - 2, feet - 1, "claw")
    # the tub: a deep rounded bowl, its rolled rim
    tub = [(x - 18, feet - 26), (x + 18, feet - 26), (x + 17, feet - 14), (x + 12, feet - 5),
           (x - 12, feet - 5), (x - 17, feet - 14)]
    c.poly([(px + (1 if px > x else -1), py + 1) for px, py in tub], "ink")
    c.poly(tub, "tub")
    c.poly([(x - 16, feet - 24), (x - 9, feet - 24), (x - 10, feet - 9), (x - 13, feet - 10)], "tub_hi")
    c.rect(x - 19, feet - 28, x + 20, feet - 25, "rim")
    # the suds piled over the rim, bubbles
    for bx, by, r in ((-12, -30, 4), (-5, -32, 5), (3, -31, 4.5), (11, -30, 4), (17, -28, 2.5)):
        inked(c, x + bx, feet + by, r * 0.8, r, "suds")
    for bx, by in ((-8, -38), (6, -39), (14, -35)):
        c.ellipse(x + bx, feet + by, 1.4, 1.8, "bubble")
    # the taps at the back: its eyes on stalks
    for tx in (x + 4, x + 12):
        c.rect(tx, feet - 36, tx + 2, feet - 28, "tap")
        c.ellipse(tx + 1, feet - 38, 2.6, 2.6, "tap_eye")
    key = {"K": "eye", "W": "shine"}
    if hurt:
        for tx in (x + 4, x + 12):
            c.stamp(tx, feet - 39, ["K.K", ".K.", "K.K"], key)
        c.line(x - 4, feet - 24, x + 2, feet - 10, "ink", 1, 1)       # a crack down its side
        c.line(x + 2, feet - 10, x - 1, feet - 6, "ink", 1, 1)
        for k in range(4):
            c.set(x - 18 - k, feet - 8 + k * 2, "water")             # water spilling out
    else:
        for tx in (x + 4, x + 12):
            c.stamp(tx, feet - 39, ["KK", "WK"] if not slosh else ["K.", "KK"], key)
    # the face on its front: a wide toothy grin under the rim
    gx, gy = x - 15, feet - 21
    if slosh:
        c.stamp(gx, gy, ["KKKKKKKKKKKKKK", "KTTKTTKTTKTTKK", "KMMMMMMMMMMMMK", "KMMMMMMMMMMMMK", ".KTTKTTKTTKTK.", "..KKKKKKKKKK.."], dict(KEY, T="teeth"))
        for k, (dx, dy) in enumerate(((-22, -32), (-24, -27), (-21, -24), (-26, -30))):
            c.set(x + dx, feet + dy, "water" if k % 2 else "water_hi")   # water sloshing over
            c.set(x + dx + 1, feet + dy + 1, "water")
    elif not hurt:
        c.stamp(gx + 1, gy, ["KK.........KK", ".KKKKKKKKKKK.", ".KTTKTTKTTKK.", "..KKKKKKKKK.."], dict(KEY, T="teeth"))
    sticker(c, "ink")
    return c


# ---- the drain gremlin

def gremlin(x, feet, frame="idle"):
    c = Canvas()
    lunge = frame == "attack"
    hurt = frame == "hurt"
    sq = 0.8 if hurt else 1.0
    # the plug on its chain, trailing behind
    for k in range(5):
        c.set(x + 8 + k * 2, feet - 3 - (k % 2), "chain")
    c.ellipse(x + 18, feet - 3, 2.4, 2.2, "plug")
    # the body: a slimy squat blob, drips off it
    inked(c, x, feet - 9 * sq, 8.0, 9.0 * sq, "slime")
    c.ellipse(x + 3, feet - 4 * sq, 3.0, 2.0 * sq, "slime_hi")
    for dx in (-6, 2, 6):
        c.rect(x + dx, feet - 3, x + dx + 1, feet + 0, "slime")
    # big ears, frills like a gremlin's
    for side in (-1, 1):
        ex = x + side * 7
        c.poly([(ex, feet - 14 * sq), (ex + side * 7, feet - 21 * sq), (ex + side * 2, feet - 10 * sq)], "slime")
        c.poly([(ex + side, feet - 14 * sq), (ex + side * 5, feet - 19 * sq), (ex + side * 2, feet - 12 * sq)], "ear_in")
    fx, fy = x - 6, feet - 14 * sq
    key = dict(KEY, Y="gr_eye")
    if hurt:
        two_eyes(c, fx, fy, SHUT[0], SHUT[1], 7)
        c.stamp(fx + 2, fy + 6, [".KK.", "K..K"], KEY)
    elif lunge:
        c.stamp(fx, fy - 1, ["YYY.", "YKKY", "YKYY"], key)
        c.stamp(fx + 7, fy - 1, [".YYY", "YKKY", "YYKY"], key)
        c.stamp(fx + 1, fy + 4, ["FKKKKF", "KMMMMK", "FKKKKF"], key)
    elif frame == "happy":
        c.stamp(fx, fy, ["YYY.", "YKKY"], key)
        c.stamp(fx + 7, fy, [".YYY", "YKKY"], key)
        c.stamp(fx + 2, fy + 5, ["K..K", ".KK."], key)
        for k, (dx, dy) in enumerate(((-2, -12), (3, -15), (8, -13))):
            c.ellipse(x + dx, fy + dy, 1.2, 1.6, "bubble")
    else:
        c.stamp(fx, fy, ["YYY.", "YKKY", "YYYY"], key)
        c.stamp(fx + 7, fy, [".YYY", "YKKY", "YYYY"], key)
        c.stamp(fx + 2, fy + 5, ["KFFK"], key)
    sticker(c, "ink")
    return c
