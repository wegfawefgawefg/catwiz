# the garden's enemies, in materials like the cat (light.py colours them for a zone):
#   sprinkler  a round green sprinkler on a spike, a brass arm with a nozzle at each end on top:
#              idle, attack (spinning, water spraying off both nozzles), hurt (dented, the arm
#              bent), happy (watering: a fountain up off its nozzles)
#   mower      a push lawnmower with a face on its hood (headlight eyes, a grille of teeth),
#              big wheels, the handle up behind: idle, attack (rearing up, blades whirring, grass
#              flying), hurt (sputtering, a wheel off)
#   cucumber   a cucumber standing on its end, bumpy, very pleased with itself: idle, attack
#              (rolling over on its side at the cat), hurt (a slice off its top)
#   gnome      a garden gnome with a tall hat, a white beard and a fishing rod: idle, attack
#              (the rod jabbed forward), hurt (its hat squashed down over its eyes)
#   mailman    the mailman, the garden's elite: a big round man in a cap and a uniform with a
#              mailbag full of parcels: idle, attack (a parcel up over his head), hurt, and
#              cross (red in the face, steam off his cap: his grumpier moves)
# everyone faces left, towards the cat. x is the body's middle pixel, feet the row under it.

from canvas import Canvas, sticker
from shade import lit_ellipse
from beasts import inked

FRAMES = {"sprinkler": ["idle", "attack", "hurt", "happy"],
          "mower": ["idle", "attack", "hurt"],
          "cucumber": ["idle", "attack", "hurt"],
          "gnome": ["idle", "attack", "hurt"],
          "mailman": ["idle", "attack", "hurt", "cross"]}

# their shows' sprites (game_sprites SHOW_KEY letters)
SHOTS = {
    "sprinkler": [("spray", ["L...L", ".L.L.", "LWLWL", ".L.L.", "L.L.L"]),
                  ("fountain", ["..L..", ".LWL.", "L.L.L", "..L..", ".L.L."])],
    "mower": [("clippings", ["A.A..", ".A.A.", "A.A.A", ".A.A.", "..A.A"]),
              ("smoke", [".WW..", "WWWW.", ".WWWW", "..WW."])],
    "cucumber": [("fright", ["Y.Y.Y", ".YWY.", "YWWWY", ".YWY.", "Y.Y.Y"]),
                 ("bump", ["..W..", ".W.W.", "W...W", ".W.W.", "..W.."])],
    "gnome": [("hook", [".W..", "W.W.", "...W", "..W.", ".WW."]),
              ("guard", ["AAAAA", "AWWWA", "AWAWA", ".AWA.", "..A.."])],
    "mailman": [("parcel", ["YYYYY", "YOYOY", "OOOOO", "YOYOY", "YYYYY"]),
                ("heavy", ["YYYYY", "YYOYY", "YYOYY", "OOOOO", "YYOYY", "YYOYY", "YYYYY"]),
                ("stamp", ["MMMMM", "MWWWM", "MWMWM", "MWWWM", "MMMMM"]),
                ("steam", [".W.W.", "W.W..", ".W.W.", "..W.W"])],
}

KEY = {"K": "eye", "W": "shine", "M": "mouth", "F": "fang"}


def two_eyes(c, x, y, near, far, gap=6):
    c.stamp(x, y, near, KEY)
    c.stamp(x + gap, y, far, KEY)


OPEN = ([".KK.", "KWKK", "KWKK", "KKKK", ".KK."], [".K.", "KWK", "KKK", ".K."])
FIERCE = (["K...", "KKK.", "KWKK", "KKKK", ".KK."], ["..K", "KKK", "KWK", ".K."])
SHUT = (["....", "KK..", "..KK", "KK.."], ["...", "..K", "KK.", "..K"])
SMUG = (["KKKK", "KWKK", ".KK."], ["KKK", "KWK"])


# ---- the sprinkler

def sprinkler(x, feet, frame="idle"):
    c = Canvas()
    hurt = frame == "hurt"
    # the spike into the ground
    c.poly([(x - 1, feet - 7), (x + 2, feet - 7), (x + 0.5, feet)], "spike")
    # the dome: a squat green bell, darker round its foot, a face on its front
    by = feet - 14
    inked(c, x, by, 9.0, 8.0, "spr")
    c.ellipse(x - 2, by - 3, 4.5, 3.0, "spr_hi")
    c.rect(x - 8, by + 5, x + 9, by + 7, "spr_sh")
    if hurt:
        c.ellipse(x + 5, by - 4, 2.0, 2.0, "ink")       # a dent
    # the stem up to the arm, the arm across, a nozzle each end
    c.rect(x, by - 13, x + 2, by - 6, "brass")
    tilt = {"attack": 2, "hurt": -3}.get(frame, 0)
    ax0, ay0, ax1, ay1 = x - 9, by - 13 + tilt, x + 11, by - 13 - tilt
    if hurt:
        ax1, ay1 = x + 9, by - 6                       # bent down
    c.line(ax0, ay0, ax1, ay1, "brass", 2, 2)
    for nx, ny in ((ax0, ay0), (ax1, ay1)):
        c.ellipse(nx, ny, 1.8, 2.2, "brass_hi")
    c.ellipse(x + 1, by - 13, 2.0, 2.4, "brass_hi")
    if frame == "attack":
        # water off both nozzles, in arcs of drops
        for k in range(1, 5):
            c.set(ax0 - k * 2, ay0 - 3 + k * k // 3, "water")
            c.set(ax0 - k * 2 - 1, ay0 - 1 + k * k // 3, "water_hi")
            c.set(ax1 + k * 2, ay1 - 3 + k * k // 3, "water")
    if frame == "happy":
        for k in range(1, 6):
            c.set(ax0 + (k % 2), ay0 - k * 2, "water")
            c.set(ax1 - (k % 2), ay1 - k * 2, "water_hi")
    # the face
    fx, fy = x - 5, by - 2
    eyes = {"attack": FIERCE, "hurt": SHUT, "happy": (["....", ".KK.", "K..K"], ["...", ".K.", "K.K"])}.get(frame, OPEN)
    two_eyes(c, fx, fy, eyes[0], eyes[1])
    mouth = {"attack": ["KKKK", "KMMK", ".KK."], "hurt": [".KK.", "K..K"]}.get(frame, ["K..K", ".KK."])
    c.stamp(fx + 2, fy + 5, mouth, KEY)
    if not hurt:
        c.rect(fx - 1, fy + 4, fx + 1, fy + 5, "blush")
        c.rect(fx + 9, fy + 4, fx + 11, fy + 5, "blush")
    sticker(c, "ink")
    return c


# ---- the lawnmower

def mower(x, feet, frame="idle"):
    c = Canvas()
    rear = frame == "attack"
    hurt = frame == "hurt"
    lift = 4 if rear else 0
    # the handle: up and back from the deck, a grip across the top
    c.line(x + 8, feet - 12, x + 16, feet - 34, "handle", 1, 2)
    c.line(x + 10, feet - 12, x + 18, feet - 33, "handle", 1, 2)
    c.rect(x + 14, feet - 36, x + 20, feet - 34, "grip")
    # the back wheel, the deck, the front wheel (raised when it rears)
    inked(c, x + 9, feet - 5, 3.8, 5.0, "wheel")
    c.ellipse(x + 9, feet - 5, 1.4, 1.8, "hub")
    deck = [(x - 13, feet - 6 - lift), (x - 12, feet - 18 - lift), (x - 6, feet - 24 - lift),
            (x + 6, feet - 24), (x + 12, feet - 18), (x + 13, feet - 6), (x + 2, feet - 4)]
    c.poly([(px - 1, py - 1) for px, py in deck], "ink")
    c.poly(deck, "mow")
    c.poly([(x - 11, feet - 18 - lift), (x - 6, feet - 22 - lift), (x + 5, feet - 22), (x + 4, feet - 19),
            (x - 9, feet - 16 - lift)], "mow_hi")
    c.rect(x - 13, feet - 8 - lift, x + 13, feet - 6, "mow_sh")         # the skirt over the blades
    if not hurt:
        inked(c, x - 8, feet - 5 - lift, 3.8, 5.0, "wheel")
        c.ellipse(x - 8, feet - 5 - lift, 1.4, 1.8, "hub")
    else:
        c.ellipse(x - 13, feet - 2, 3.0, 2.0, "wheel")               # the wheel rolled off
    # the face on the hood: headlight eyes, a grille of teeth
    fx, fy = x - 9, feet - 19 - lift
    key = {"K": "eye", "Y": "eyewhite", "W": "shine", "T": "teeth", "M": "mouth"}
    if hurt:
        c.stamp(fx, fy, ["....", "YY..", "..YY", "YY.."], key)
        c.stamp(fx + 7, fy, ["...", "..Y", "YY.", "..Y"], key)
        c.stamp(fx + 2, fy + 6, ["T.T.T", ".T.T."], key)
        for k in range(3):
            c.set(x - 2 + k * 3, feet - 27 - k * 2, "smoke")       # sputtering
    elif rear:
        c.stamp(fx, fy - 1, ["KK..", ".KKK", "YKKY", "YKWY", ".YY."], key)
        c.stamp(fx + 7, fy - 1, ["..K", "KK.", "YKY", "YKY", ".Y."], key)
        c.stamp(fx + 1, fy + 5, ["KKKKKK", "TTTTTT", "MMMMMM", "TTTTTT"], key)
    else:
        c.stamp(fx - 1, fy - 1, [".YYY.", "YYKKY", "YYKWY", "YYKKY", ".YYY."], key)
        c.stamp(fx + 6, fy - 1, [".YY.", "YKKY", "YKWY", "YKKY", ".YY."], key)
        c.stamp(fx + 1, fy + 5, ["KKKKKK", "TKTKTK", "KKKKKK"], key)
    if rear:
        # blades whirring underneath, clippings flying out of the front
        c.rect(x - 12, feet - 5, x + 6, feet - 4, "blade")
        for k, (gx, gy) in enumerate(((x - 16, feet - 4), (x - 18, feet - 9), (x - 15, feet - 12),
                                      (x - 20, feet - 6), (x - 17, feet - 15))):
            c.set(gx, gy, "grass" if k % 2 else "grass_hi")
            c.set(gx + 1, gy - 1, "grass")
    sticker(c, "ink")
    return c


# ---- the cucumber

def cucumber(x, feet, frame="idle"):
    c = Canvas()
    if frame == "attack":
        # rolled over on its side, coming at the cat
        inked(c, x, feet - 6, 14.0, 5.5, "cuc")
        c.ellipse(x - 2, feet - 8, 10, 2.0, "cuc_hi")
        for bx in range(-11, 12, 4):
            c.set(x + bx, feet - 3 + (bx // 4) % 2, "cuc_bump")
        c.rect(x + 12, feet - 8, x + 15, feet - 4, "cuc_end")
        fx, fy = x - 9, feet - 10
        two_eyes(c, fx, fy, FIERCE[0], FIERCE[1], 5)
        c.stamp(fx + 1, fy + 5, ["KKK", "KMK"], KEY)
        for k in range(3):
            c.set(x + 15 + k * 2, feet - 1 - k, "dust")              # dust off behind it
        sticker(c, "ink")
        return c
    hurt = frame == "hurt"
    top = feet - (30 if hurt else 36)
    # standing on its end: a long rounded body, lit down its left side, bumps
    inked(c, x, (top + feet) / 2, 6.5, (feet - top) / 2, "cuc")
    c.ellipse(x - 2.5, (top + feet) / 2 - 2, 2.0, (feet - top) / 2 - 5, "cuc_hi")
    for k, by in enumerate(range(top + 6, feet - 3, 5)):
        c.set(x + 3 - (k % 2) * 5, by, "cuc_bump")
        c.set(x + 4 - (k % 2) * 5, by + 1, "cuc_bump")
    if hurt:
        c.ellipse(x, top + 1, 5.5, 2.0, "cuc_slice")                 # the slice off its top
        c.ellipse(x, top + 1, 3.0, 1.0, "cuc_seed")
        c.ellipse(x - 9, top - 4, 4.0, 1.8, "cuc_slice")             # flying off
    else:
        c.rect(x - 1, top - 2, x + 2, top + 1, "cuc_end")            # the stalk end
    fx, fy = x - 5, top + 9
    eyes = {"hurt": SHUT}.get(frame, SMUG)
    two_eyes(c, fx, fy, eyes[0], eyes[1], 6)
    if hurt:
        c.stamp(fx + 2, fy + 5, [".KK.", "K..K"], KEY)
    else:
        c.stamp(fx + 1, fy + 5, ["K....", ".KKKK"], KEY)              # a smug little smirk
        c.rect(fx - 1, fy + 3, fx + 1, fy + 4, "blush")
    sticker(c, "ink")
    return c


# ---- the garden gnome

def gnome(x, feet, frame="idle"):
    c = Canvas()
    jab = frame == "attack"
    hurt = frame == "hurt"
    # boots, a round blue coat, a black belt with a gold buckle
    c.ellipse(x - 4, feet - 2, 3.0, 2.2, "boot")
    c.ellipse(x + 3, feet - 2, 3.0, 2.2, "boot")
    inked(c, x, feet - 10, 7.0, 8.0, "coat")
    c.ellipse(x - 2, feet - 12, 3.0, 4.0, "coat_hi")
    c.rect(x - 7, feet - 11, x + 8, feet - 9, "belt")
    c.rect(x - 1, feet - 12, x + 2, feet - 8, "buckle")
    # the head: a round face, a big nose, a beard down over the coat
    hx, hy = x - 1, feet - 23 + (2 if hurt else 0)
    inked(c, hx, hy, 6.5, 7.0, "skin")
    c.poly([(hx - 6, hy + 3), (hx + 6, hy + 3), (hx + 4, hy + 11), (hx, hy + 15), (hx - 4, hy + 11)], "beard")
    c.line(hx - 2, hy + 6, hx - 1, hy + 12, "beard_sh", 1, 1)
    c.ellipse(hx - 2, hy + 3, 1.8, 1.8, "gnose")
    # the hat: a tall cone, its tip flopped over (squashed flat when hurt)
    if hurt:
        c.poly([(hx - 7, hy - 1), (hx + 7, hy - 1), (hx + 9, hy - 6), (hx - 9, hy - 6)], "hat_g")
        c.poly([(hx - 6, hy - 6), (hx + 6, hy - 6), (hx + 2, hy - 10)], "hat_g")
    else:
        c.poly([(hx - 7, hy - 5), (hx + 7, hy - 5), (hx + 3, hy - 18), (hx - 1, hy - 23), (hx - 6, hy - 21),
                (hx - 2, hy - 17)], "hat_g")
        c.poly([(hx - 7, hy - 5), (hx - 2, hy - 5), (hx - 3, hy - 14)], "hat_hi")
    if hurt:
        c.stamp(hx - 6, hy - 2, ["KKKKKKKKKKK"], KEY)                     # eyes under the brim
    else:
        eyes = FIERCE if jab else OPEN
        c.stamp(hx - 6, hy - 4, eyes[0], KEY)
        c.stamp(hx + 1, hy - 4, eyes[1], KEY)
        c.rect(hx + 3, hy + 1, hx + 5, hy + 2, "blush")
    # the rod: held up beside it, or jabbed forward at the cat, the line and its hook
    if jab:
        c.line(x - 4, feet - 12, x - 22, feet - 18, "rod", 1, 1)
        c.ellipse(x - 5, feet - 12, 1.8, 1.6, "skin")
        c.set(x - 23, feet - 17, "hook")
        c.set(x - 23, feet - 16, "hook")
    else:
        # the rod over its shoulder, the line down from its tip, a bobber on it
        c.line(x - 7, feet - 11, x - 14, feet - 38, "rod", 1, 1)
        c.ellipse(x - 7, feet - 11, 1.8, 1.6, "skin")
        for k in range(10):
            c.set(x - 15 - (k > 5), feet - 37 + k * 2, "line")
        c.ellipse(x - 16, feet - 16, 1.2, 1.6, "bobber")
        c.set(x - 16, feet - 13, "hook")
    sticker(c, "ink")
    return c


# ---- the mailman

def mailman(x, feet, frame="idle"):
    c = Canvas()
    throw = frame == "attack"
    hurt = frame == "hurt"
    cross = frame == "cross"
    sq = 2 if hurt else 0
    # legs, shoes
    for lx in (x - 6, x + 3):
        c.rect(lx, feet - 12, lx + 4, feet - 2, "trousers")
        c.rect(lx - 1, feet - 2, lx + 5, feet, "shoe")
    # the mailbag on its strap, fat with parcels, behind him on the right
    inked(c, x + 11, feet - 21, 6.5, 8.0, "bag")
    c.rect(x + 7, feet - 31, x + 15, feet - 27, "parcel")
    c.rect(x + 10, feet - 32, x + 12, feet - 27, "string")
    c.ellipse(x + 10, feet - 22, 3, 3, "bag_hi")
    # the round body in a uniform, a white shirt front, buttons
    inked(c, x, feet - 24 + sq, 11.0, 13.0 - sq, "uniform")
    c.ellipse(x - 4, feet - 27 + sq, 4.0, 7.0, "uniform_hi")
    c.poly([(x - 4, feet - 36 + sq), (x + 2, feet - 36 + sq), (x - 1, feet - 29 + sq)], "shirt")
    for by in (feet - 27, feet - 21, feet - 15):
        c.set(x - 1, by + sq, "button")
    c.line(x - 9, feet - 35, x + 11, feet - 19, "strap", 1, 2)          # the bag's strap
    # the head: round and red-cheeked, a big moustache, a cap with a badge
    hx, hy = x - 2, feet - 46 + sq * 2
    inked(c, hx, hy, 8.0, 9.0, "skin_cross" if cross else "skin_m")
    c.poly([(hx - 9, hy - 5), (hx + 9, hy - 5), (hx + 8, hy - 12), (hx - 6, hy - 13)], "cap")
    c.rect(hx - 13, hy - 6, hx + 2, hy - 4, "cap")                     # the peak, towards the cat
    c.rect(hx - 2, hy - 11, hx + 1, hy - 8, "badge")
    c.ellipse(hx - 3, hy + 4.5, 5.0, 2.0, "stache")
    c.ellipse(hx + 2, hy + 4.5, 3.0, 1.6, "stache")
    c.ellipse(hx - 7, hy + 2, 2.2, 2.0, "nose_m")
    if hurt:
        c.stamp(hx - 6, hy - 2, ["KK...", "..KK.", "KK..."], KEY)
        c.stamp(hx + 2, hy - 2, ["..KK", "KK..", "..KK"], KEY)
        c.ellipse(hx - 12, hy - 15, 3, 2, "cap")                      # the cap knocked off
        c.stamp(hx - 3, hy + 7, [".KK.", "K..K"], KEY)
    elif cross or throw:
        c.stamp(hx - 7, hy - 4, ["KKK..", "..KKK", ".KKWK", ".KKKK"], KEY)
        c.stamp(hx + 2, hy - 4, ["..KK", "KK..", "KKWK", "KKKK"], KEY)
        c.stamp(hx - 5, hy + 6, ["KKKKK", "KMMMK"], KEY)
    else:
        c.stamp(hx - 6, hy - 3, [".KK.", "KWKK", "KKKK"], KEY)
        c.stamp(hx + 2, hy - 3, [".KK", "KWK", "KKK"], KEY)
        c.rect(hx + 5, hy + 1, hx + 7, hy + 2, "blush")
    if cross:
        for k in range(4):
            c.set(hx - 4 + k * 3, hy - 16 - (k % 2) * 2, "steam")     # steam off his cap
            c.set(hx - 3 + k * 3, hy - 18 - (k % 2) * 2, "steam")
            c.set(hx - 4 + k * 3, hy - 20 - (k % 2) * 2, "steam")
    # the arms: one up with a parcel to throw, or at his side
    if throw:
        c.line(x - 8, feet - 33, x - 12, feet - 54, "uniform", 2, 2)
        c.rect(x - 18, feet - 61, x - 7, feet - 53, "parcel")
        c.rect(x - 13, feet - 61, x - 12, feet - 53, "string")
        c.rect(x - 18, feet - 58, x - 7, feet - 57, "string")
    else:
        c.line(x - 10, feet - 31, x - 12, feet - 18, "uniform", 2, 2)
        c.ellipse(x - 12, feet - 17, 2.2, 2.0, "skin_m")
        if cross:
            c.stamp(x - 15, feet - 22, ["MMMMM", "MWWWM", "MWMWM", "MWWWM", "MMMMM"], {"M": "stamp_ink", "W": "shine"})
    sticker(c, "ink")
    return c
