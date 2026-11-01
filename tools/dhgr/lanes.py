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
#               front shoots it instead (place.tsp hand_y: from 14 rows over its head); the
#               cards' shows (content/shows.tsp): ARC sprites no bigger than the bolt, ON ones
#               inside the idle frame of whoever they are for (no lane of their own)
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
# The map of the run (battle/map.tsp, MAP) is drawn at the top of the stage when a fight starts:
# its box is kept black like a lane, so the scenery stays out of it.
#
# Between fights battle/kit.tsp draws her six slots where the enemies stood (pixels 77-139,
# rows 62-109), not a look: the next fight's picture covers them, so they need no lane.
#
# Boxes are in byte columns (0-39, 3.5 pixels each; always even here, so 7-pixel groups) and
# rows: (col, top, cols, rows).

import os

import dhgr
import figures
import game_hud
import game_sprites as gs

HERO_COL = 4                     # content/encounters.tsp HERO :col
# each fight's spots (screens.py, from content/encounters.tsp FIGHTS): by the fight's number
# (its row + 1), [(byte column, [the figures that can stand there])]
MAP = (22, 0, 8, 12)             # battle/map.tsp: the map of the run, pixels 77-104, rows 0-11
HOP_MOST = 6                     # act.tsp HOP
LIFT_MOST = 6
ARC = [0, 7, 11, 13, 14, 13, 11, 7, 0]
FLOAT_RISE = 20                  # hit.tsp FLOAT_FRAMES 26: up a row while time > 12, then every other
HP_TOP = 112
BADGE_ROWS = 9
BADGE_MOST = 8
INTENT_MOST = 3


class Kind:
    # a fighter kind's frames as the game's tables see them (game.py): its role frames, placed
    # from its block's first frame
    def __init__(self, kind):
        K = figures.KINDS[kind]
        sprites = gs.block_sprites(K.block)
        names = figures.frame_names(figures.BLOCKS[K.block])
        base = sprites[0]
        mine = [sprites[names.index(f)] for r, f in K.roles.items() if not r.startswith("shot")]
        mine.append(sprites[names.index(K.roles["idle"])])
        self.kind = kind
        self.top = base.top
        self.feet = base.top + base.rows
        self.cols = base.cols
        self.flyer = figures.is_flyer(kind)
        self.frames = [(s.col - base.col, s.top - base.top, s.cols, s.rows) for s in mine]
        self.reach = max(s.col + s.cols for s in mine) - base.col
        self.left = base.col - min(s.col for s in mine)
        self.shots = [sprites[names.index(f)] for r, f in K.roles.items() if r.startswith("shot")]


_KINDS = {}


def kind(name):
    if name not in _KINDS:
        _KINDS[name] = Kind(name)
    return _KINDS[name]


_SPOTS = None


def spots(n):
    global _SPOTS
    if _SPOTS is None:
        import screens
        _SPOTS = {F["n"]: F["spots"] for F in screens.fights()}
    return _SPOTS[n]


def fight_numbers():
    spots(1)
    return sorted(_SPOTS)


def misc_sizes():
    out = {}
    for s in gs.misc():
        out[s.name] = (s.cols, s.rows)
    return out


# the glyphs a badge can hold (by hand, from content/statuses.tsp GLYPH and SHOW, the moves'
# icons in content/moves.tsp and content/foes.tsp intent_icon): the heart, digits, statuses
# shown, the moves' glyphs
BADGE_GLYPHS = "*0123456789#,%@<;&+>!^)\"(-./:=?[\\]_`abcd"


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
    out = [MAP + ("map",)]
    misc = misc_sizes()
    hero = kind("cat")
    # every figure at every spot it can stand at
    cast = [(HERO_COL, "cat")] + [(col, k) for col, ks in spots(n) for k in ks]

    def middle(K, home):
        return home + (K.cols >> 1)

    def centre_x(K, home):
        return ((home * 2 + K.cols) * 7) >> 2

    for i, (home, name) in enumerate(cast):
        K = kind(name)
        if i == 0:
            far = max(reach(home, K, h, kind(e)) for h, e in cast[1:])
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
            for pname in ("poof0", "poof1"):
                w, h = misc[pname]
                pcol = (middle(K, home) - (w >> 1)) & 0xFE
                for lift in range(0, LIFT_MOST + 1):
                    for bob in bobs:
                        top = K.top - lift - bob
                        out.append((pcol, top + ((K.feet - K.top) >> 2), w, h, "poof"))
        # the marker over its head (look.tsp marker), bobbing 0 or 2
        w, h = misc["marker"]
        mtop = 8 if i == 0 else K.top - 25
        for bob in (0, 2):
            out.append(((middle(K, home) - 2) & 0xFE, mtop + bob, w, h, "marker"))
        # the floating numbers (hit.tsp float_number), one or two digits, the whole rise
        w, h = misc["digit_0"]
        if i == 0:
            starts = [((home + K.cols) & 0xFE, 44)]
        else:
            col = (middle(K, home) - 1) & 0xFE
            top = K.top - 34 if K.top > 54 else 20
            starts = [(col, top), (col - 2, top)]
        for col, top in starts:
            # the second digit 2 columns on (draw/scene.tsp box_of)
            out.append((col, top - FLOAT_RISE, w + 2, h + FLOAT_RISE, "number"))
        # the badges (hud.tsp pill, intent)
        ptop = HP_TOP if K.feet >= 100 else K.feet + 2
        out.append(badge_box(centre_x(K, home), ptop, BADGE_MOST) + ("badge",))
        if i > 0:
            out.append(badge_box(centre_x(K, home), K.top - 12, INTENT_MOST) + ("badge",))

    # the bolt (act.tsp throw_step) from the hero's front to each enemy's middle
    w, h = misc["bolt"]
    x0 = HERO_COL + hero.reach
    y0 = hero.top + ((hero.feet - hero.top) >> 1) - 6
    for home, e in cast[1:]:
        sx = sy = 0
        tx = middle(kind(e), home)
        ty = kind(e).top + 8
        for k in range(len(ARC)):
            col = x0 + (sx >> 3)
            top = y0 + (sy >> 3)
            sx += tx - x0
            sy += ty - y0
            out.append((col & 0xFE, top - ARC[k], w, h, "bolt"))
    # each enemy's shot at the hero (act.tsp, a lunge with someone in the way, or a move's
    # thrown show): from in front of it, 14 rows over its head, to the hero's middle; its own
    # shots no bigger than the bolt (checked)
    tx = middle(hero, HERO_COL)
    ty = hero.top + 8
    for home, e in cast[1:]:
        K = kind(e)
        for s in K.shots:
            if s.cols > w or s.rows > h:
                raise SystemExit("lanes.py: %s's shot %s is %d x %d, more than the bolt's %d x %d"
                                 % (e, s.name, s.cols, s.rows, w, h))
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


TINT = {"map": (255, 255, 255), "fighter": (255, 60, 60), "poof": (255, 160, 40), "marker": (80, 220, 80),
        "number": (60, 200, 255), "badge": (230, 230, 60), "bolt": (220, 80, 255)}


def debug_image(n, px, path):
    # the backdrop (flat colours) with each lane tinted by what it is for, 4x wide, 2x tall
    from PIL import Image
    im = Image.new("RGB", (dhgr.W, dhgr.H))
    for y in range(dhgr.H):
        for x in range(dhgr.W):
            im.putpixel((x, y), dhgr.RGB[px[y][x] or 0])
    over = im.copy()
    order = ["map", "fighter", "poof", "bolt", "number", "marker", "badge"]
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
