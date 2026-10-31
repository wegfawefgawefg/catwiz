# one whole fight screen as the game would show it: a backdrop, the fighters lit for the
# zone with their shadows and badges, the tray and four lines of 40-column text. For the
# previews and the lighting proof; the game draws the same parts itself.

from canvas import Canvas
import cat
import foes
import fonts
import hud
import light
from dhgr import BLACK

# where everyone stands (sprites sit on 7-pixel steps: these are their drawing origins)
CAT = (30, 108)
# the enemies far enough apart, and from the cat's widest frame (her wand out reaches column
# 18), that no two boxes meet: a sprite drawn again then never draws its neighbour again too
SLOTS = {"puffcap": (91, 108), "sporelet": (124, 106), "nightflap": (115, 44)}

HAND = [("wand", "3"), ("tuna", "2"), ("fluff", "3"), ("star", "1"), ("times2", "X2")]
TEXT = [("GOLD WAND  3 damage to one enemy.", ((0, 9),)),
        ("Target PUFFCAP: 9 hp, hits you for 4.", ()),
        ("Sporelet cheers. Puffcap hits +1.", ()),
        ("1-5 pick  R re-roll (2)  E end turn", ())]


def figure(kind, frame="idle"):
    if kind == "cat":
        return cat.cat(*CAT, frame)
    x, y = SLOTS[kind]
    return {"puffcap": foes.puffcap, "sporelet": foes.sporelet, "nightflap": foes.nightflap}[kind](x, y, frame)


def build(backdrop, zone, foes_here, shadow, frames=None, U=None, lights=None, target=0,
          picked=0, hp=None, intents=None, text=TEXT):
    # backdrop: a Canvas; shadow(c, cx, y, rx) puts a shadow down; lights(c, figs) adds the
    # zone's light on the ground (night). Returns (canvas, lines of text dots).
    frames = frames or {}
    U = U or hud.U_DAY
    c = backdrop.copy()
    kinds = ["cat"] + list(foes_here)
    figs = [figure(k, frames.get(k, "idle")) for k in kinds]
    boxes = [f.bbox() for f in figs]
    for k, (x0, y0, x1, y1) in zip(kinds, boxes):
        if k == "nightflap":
            shadow(c, (x0 + x1) / 2, 106, 6)
        else:
            shadow(c, (x0 + x1) / 2 + 1, y1 - 1, (x1 - x0) * 0.36)
    lit = [light.lit(f, zone) for f in figs]
    if lights:
        lights(c, lit)
    for f in lit:
        c.paste(f)
    hp = hp or {"cat": "30", "puffcap": "9", "sporelet": "6", "nightflap": "8"}
    intents = intents or {"puffcap": "4", "sporelet": "2", "nightflap": "3"}
    for k, (x0, y0, x1, y1) in zip(kinds, boxes):
        mid = CAT[0] if k == "cat" else SLOTS[k][0]
        foot = 112 if k != "nightflap" else y1 + 2
        hud.badge(c, U, mid, foot, hud.HEART, U["heart"], hp[k])
        if k != "cat":
            hud.badge(c, U, mid, y0 - 12, hud.SWORD, U["sword"], intents[k])
    if target is not None and foes_here:
        k = foes_here[target]
        x0, y0, x1, y1 = boxes[target + 1]
        hud.marker(c, U, SLOTS[k][0], y0 - 21)
    hud.tray(c, U, HAND, picked)
    lines = {}
    for r, (s, inv) in enumerate(text):
        fonts.text40(lines, 20 + r, s, inv)
    return c, lines
