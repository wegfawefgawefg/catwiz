# the lanes: every box of the stage a battle look can ever cover, for a fight's enemies. The
# fighters' frames are drawn solid (the figure flattened onto black over its whole box), so
# the backdrop must be black (colour 0) in every lane: a pose drawn over a lane then erases
# the last one in the same copy, with no restore and no mask. The scenery (night.py) goes
# only outside the lanes, and night.picture paints the lanes black last to make sure.
#
# The numbers are the game's, mirrored here from game/battle/*.tsp and draw/badge.tsp (keep
# them in step when those change):
#   look.tsp    show_actor (knockback 2 columns, lift, bob 0-2 for flyers, DCOL/DTOP per
#               frame), marker (8 for the hero, else top - 25; bob 0 or 2), the poofs
#   act.tsp     reach (lunges in 2-column steps), HOP (lift 2-6), lunge lift 4, throw_step's
#               bolt (front to the target's middle, ARC over it); an enemy with another in
#               front shoots it instead (place.tsp hand_y: from 14 rows over its head)
#   hit.tsp     float_number (where a number starts, and its rise: 20 rows over 26 frames)
#   hud.tsp     the badges (HP_TOP 112, or the feet + 2 for a flyer; intents 12 over the top)
#   badge.tsp   9 rows; a badge's box is the 7-pixel groups its pill covers
# Conservative where tracing it exactly is not worth it, by hand:
#   - every frame of a kind (and its flash) at every place it can stand, any lift 0-6: a
#     hurt face mid-lunge, a hop while knocked back
#   - an enemy at every step of its lunge, each also knocked back 2 where that stays on the
#     screen (look.tsp keeps it there otherwise)
#   - the hit point badges as wide as BADGE_MOST of the widest glyph; intents 3 glyphs
#
# Between fights battle/kit.tsp draws her six slots where the enemies stood (pixels 77-139,
# rows 62-109), not a look: the next fight's picture covers them, so they need no lane.
#
# Boxes are in byte columns (0-39, 3.5 pixels each; always even here, so 7-pixel groups) and
# rows: (col, top, cols, rows).

import os

import dhgr
import game_hud
import game_sprites as gs

HERO_COL = 4                     # content/encounters.tsp HERO :col
SPOTS = {                        # content/encounters.tsp FIGHTS, by the fight's number
    1: [("puffcap", 20), ("sporelet", 32)],
    2: [("puffcap", 20), ("sporelet", 32), ("nightflap", 26)],
}
HOP_MOST = 6                     # act.tsp HOP
LIFT_MOST = 6
ARC = [0, 7, 11, 13, 14, 13, 11, 7, 0]
FLOAT_RISE = 20                  # hit.tsp FLOAT_FRAMES 26: up a row while time > 12, then every other
HP_TOP = 112
BADGE_ROWS = 9
BADGE_MOST = 8
INTENT_MOST = 3


class Kind:
    # a fighter kind's frames as the game's tables see them
    def __init__(self, kind):
        sprites = [gs.fighter(kind, f, "night") for f in gs.frames(kind)]
        base = sprites[0]
        self.kind = kind
        self.top = base.top
        self.feet = base.top + base.rows
        self.cols = base.cols
        self.flyer = kind == "nightflap"
        self.frames = [(s.col - base.col, s.top - base.top, s.cols, s.rows) for s in sprites]
        self.reach = max(s.col + s.cols for s in sprites) - base.col
        self.left = base.col - min(s.col for s in sprites)


def misc_sizes():
    out = {}
    for s in gs.misc():
        out[s.name] = (s.cols, s.rows)
    return out


# the glyphs a badge can hold (by hand, from content/statuses.tsp GLYPH and SHOW, the moves'
# icons in content/moves.tsp and content/foes.tsp intent_icon): the heart, digits, statuses
# shown, the moves' glyphs
BADGE_GLYPHS = "*0123456789#,%@<;&+>!^)\"(-./:=?[\\]_"


def glyph_widest():
    font = game_hud.hud_font()
    return max(font[(ord(ch) - 32) * 8] for ch in BADGE_GLYPHS)


def badge_box(cx, top, glyphs):
    # badge.tsp / hud.tsp finish: the pill w pixels wide centred on cx, its groups
    w = glyphs * (glyph_widest() + 1) - 1 + 4
    half = w >> 1
    x0 = cx - half if cx > half else 0
    if x0 + w > 140:
        x0 = 140 - w
    g0, g1 = x0 // 7, (x0 + w - 1) // 7
    return (g0 * 2, top, (g1 - g0 + 1) * 2, BADGE_ROWS)


def reach(by_home, by_kind, t_home, t_kind):
    # act.tsp reach
    gap = 0
    if by_home < t_home:
        edge = by_home + by_kind.cols
        if t_home > edge:
            gap = t_home - edge
    else:
        edge = t_home + t_kind.cols
        if by_home > edge:
            gap = by_home - edge
    gap = min(gap, 10)
    if gap >= 4:
        gap -= 2
    gap = max(gap, 2)
    return gap & 0xFE


def boxes(n):
    # every lane box of fight n, each with what it is for: [(col, top, cols, rows, why)]
    out = []
    misc = misc_sizes()
    cast = [("cat", HERO_COL)] + SPOTS[n]
    kinds = {k: Kind(k) for k, _ in cast}
    hero = kinds["cat"]

    def middle(k, home):
        return home + (kinds[k].cols >> 1)

    def centre_x(k, home):
        return ((home * 2 + kinds[k].cols) * 7) >> 2

    # the fighters: each frame at every column it can stand at, every lift
    for i, (k, home) in enumerate(cast):
        K = kinds[k]
        if i == 0:
            far = max(reach(home, K, h, kinds[e]) for e, h in SPOTS[n])
            cols = range(home, home + far + 1, 2)
        else:
            # its lunge's steps, each maybe knocked back 2 (only if that stays on the screen)
            far = reach(home, K, HERO_COL, hero)
            steps = list(range(home - far, home + 1, 2))
            cols = sorted(set(steps + [c + 2 for c in steps if c + 2 + K.cols <= 40]))
        bobs = range(0, 3) if K.flyer else (0,)
        for col in cols:
            for lift in range(0, LIFT_MOST + 1):
                for bob in bobs:
                    top = K.top - lift - bob
                    for dc, dt, w, h in K.frames:
                        out.append((col + dc, top + dt, w, h, "fighter"))
        # the poofs (look.tsp show_actor): at its middle, a quarter down from its top
        if i > 0:
            for name in ("poof0", "poof1"):
                w, h = misc[name]
                pcol = (middle(k, home) - (w >> 1)) & 0xFE
                for lift in range(0, LIFT_MOST + 1):
                    for bob in bobs:
                        top = K.top - lift - bob
                        out.append((pcol, top + ((K.feet - K.top) >> 2), w, h, "poof"))
        # the marker over its head (look.tsp marker), bobbing 0 or 2
        w, h = misc["marker"]
        mtop = 8 if i == 0 else K.top - 25
        for bob in (0, 2):
            out.append(((middle(k, home) - 2) & 0xFE, mtop + bob, w, h, "marker"))
        # the floating numbers (hit.tsp float_number), one or two digits, the whole rise
        w, h = misc["digit_0"]
        if i == 0:
            starts = [((home + K.cols) & 0xFE, 44)]
        else:
            col = (middle(k, home) - 1) & 0xFE
            top = K.top - 34 if K.top > 54 else 20
            starts = [(col, top), (col - 2, top)]
        for col, top in starts:
            # the second digit 2 columns on (draw/scene.tsp box_of)
            out.append((col, top - FLOAT_RISE, w + 2, h + FLOAT_RISE, "number"))
        # the badges (hud.tsp pill, intent)
        ptop = HP_TOP if K.feet >= 100 else K.feet + 2
        out.append(badge_box(centre_x(k, home), ptop, BADGE_MOST) + ("badge",))
        if i > 0:
            out.append(badge_box(centre_x(k, home), K.top - 12, INTENT_MOST) + ("badge",))

    # the bolt (act.tsp throw_step) from the hero's front to each enemy's middle
    w, h = misc["bolt"]
    x0 = HERO_COL + hero.reach
    y0 = hero.top + ((hero.feet - hero.top) >> 1) - 6
    for e, home in SPOTS[n]:
        sx = sy = 0
        tx = middle(e, home)
        ty = kinds[e].top + 8
        for k in range(len(ARC)):
            col = x0 + (sx >> 3)
            top = y0 + (sy >> 3)
            sx += tx - x0
            sy += ty - y0
            out.append((col & 0xFE, top - ARC[k], w, h, "bolt"))
    # each enemy's shot at the hero (act.tsp, a lunge with someone in the way): from in front
    # of it, 14 rows over its head, to the hero's middle
    tx = middle("cat", HERO_COL)
    ty = hero.top + 8
    for e, home in SPOTS[n]:
        K = kinds[e]
        x0 = home - K.left - 2
        y0 = K.top - 14
        sx = sy = 0
        for k in range(len(ARC)):
            col = x0 + (sx >> 3)
            top = y0 + (sy >> 3)
            sx += tx - x0
            sy += ty - y0
            out.append((col & 0xFE, top - ARC[k], w, h, "bolt"))
    return out


def mask(n):
    # the lanes as a 140 x 192 grid of pixels: True inside a lane
    m = [[False] * dhgr.W for _ in range(dhgr.H)]
    for col, top, cols, rows, _ in boxes(n):
        x0, x1 = col * 7 // 2, (col + cols) * 7 // 2
        for y in range(max(0, top), min(dhgr.H, top + rows)):
            for x in range(max(0, x0), min(dhgr.W, x1)):
                m[y][x] = True
    return m


TINT = {"fighter": (255, 60, 60), "poof": (255, 160, 40), "marker": (80, 220, 80),
        "number": (60, 200, 255), "badge": (230, 230, 60), "bolt": (220, 80, 255)}


def debug_image(n, px, path):
    # the backdrop (flat colours) with each lane tinted by what it is for, 4x wide, 2x tall
    from PIL import Image
    im = Image.new("RGB", (dhgr.W, dhgr.H))
    for y in range(dhgr.H):
        for x in range(dhgr.W):
            im.putpixel((x, y), dhgr.RGB[px[y][x] or 0])
    over = im.copy()
    order = ["fighter", "poof", "bolt", "number", "marker", "badge"]
    bxs = sorted(boxes(n), key=lambda b: order.index(b[4]))
    for col, top, cols, rows, why in bxs:
        x0, x1 = col * 7 // 2, (col + cols) * 7 // 2
        for y in range(max(0, top), min(dhgr.H, top + rows)):
            for x in range(max(0, x0), min(dhgr.W, x1)):
                over.putpixel((x, y), TINT[why])
    out = Image.blend(im, over, 0.45)
    out = out.resize((dhgr.W * 4, dhgr.H * 2), Image.NEAREST)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    out.save(path)
    return path


def check(n, px):
    # pixels of the backdrop inside a lane that are not black: should be none
    m = mask(n)
    return sum(1 for y in range(dhgr.H) for x in range(dhgr.W) if m[y][x] and (px[y][x] or 0) != dhgr.BLACK)
