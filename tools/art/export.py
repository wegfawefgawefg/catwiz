# turn the drawings in actors.py, icons.py and scenes.py into Tisple data modules for the game:
#   game/art/sprites.tsp   the tables that say which sprite is which (bodies, mood patches,
#                          tiles, digits, effects) and the hud font
#   game/art/sprite_data.tsp  the sprites' bytes
#   game/art/backdrop.tsp  the forest screen, 8 KB in aux memory
#   game/art/title_N.tsp   the title in four glow steps, 8 KB each in aux memory
# and preview pictures into shots/art/.
#
# run: tools/.venv/bin/python tools/art/export.py
#
# a sprite is cut on the byte grid from a left column that is even, so it keeps its colours
# wherever the game puts it on an even column. A sprite w bytes wide and h rows tall is stored
# as h rows of w picture bytes, h rows of w mask bytes, then for each row the first byte with
# something in it and how many from there (its span): h firsts, then h counts. The screen gets
# (screen & mask) | picture: mask bits 1 keep the screen. A byte with any sprite pixel in it
# takes the sprite's palette (mask bit 7 clear). Every row the same stride keeps the game's
# per-row work small: the row costs more there than its bytes do.

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, HERE)

from hgr import Canvas, FONT, PALETTE_1, COLOURED, to_hgr, render  # noqa: E402
import actors  # noqa: E402
import boss  # noqa: E402
import hero  # noqa: E402
import icons  # noqa: E402
import scenes  # noqa: E402

GAME_ART = os.path.join(ROOT, "game", "art")
SHOTS = os.path.join(ROOT, "shots", "art")
GROUND = scenes.GROUND

# the engine's Mood enum, in order
MOODS = ["idle", "angry", "worried", "hurt", "bark", "happy", "ko"]


def outlined(draw):
    # a transparent canvas with the drawing and its 1-px black sticker outline
    c = Canvas(".")
    draw(c)
    c.outline("K", inside=lambda col, x, y: col != ".", t=1)
    return c


def bbox(c, test=lambda col: col != "."):
    xs, ys = [], []
    for y in range(192):
        for x in range(280):
            if test(c.px[y][x]):
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def byte_box(box, even=True):
    # pixel box to (first column, columns, top, rows); the first column even when asked
    x0, y0, x1, y1 = box
    col0 = x0 // 7
    if even and col0 % 2 == 1:
        col0 -= 1
    col1 = (x1 + 6) // 7
    return col0, col1 - col0, y0, y1 - y0


def cell_bytes(c, col, y):
    # the picture and mask byte of one byte cell
    cells = [c.px[y][col * 7 + b] if col * 7 + b < 280 else "." for b in range(7)]
    opaque = [ch for ch in cells if ch != "."]
    if not opaque:
        return 0, 0xFF
    coloured = [ch for ch in opaque if ch in COLOURED]
    high = sum(ch in PALETTE_1 for ch in coloured) * 2 > len(coloured)
    pic = 0x80 if high else 0
    mask = 0
    for b, ch in enumerate(cells):
        x = col * 7 + b
        if ch == ".":
            mask |= 1 << b
            continue
        lit = ch == "W" or (ch in ("V", "B") and x % 2 == 0) or (ch in ("G", "O") and x % 2 == 1)
        if lit:
            pic |= 1 << b
    return pic, mask


def cut(c, col0, cols, top, rows):
    # the sprite's pictures, masks and spans (firsts then counts), in the format above
    pics, masks, firsts, counts = [], [], [], []
    for y in range(top, top + rows):
        cells = [cell_bytes(c, col0 + i, y) for i in range(cols)]
        pics += [p for p, m in cells]
        masks += [m for p, m in cells]
        used = [i for i, (pic, mask) in enumerate(cells) if mask != 0xFF]
        if not used:
            firsts.append(0)
            counts.append(0)
            continue
        firsts.append(used[0])
        counts.append(used[-1] + 1 - used[0])
    return pics, masks, firsts + counts


class Sheet:
    # every sprite, in order: its name, width in bytes, rows, and where its pictures, masks
    # and spans start in one shared blob. The blit reads each of the three through its own
    # offset, so a block that is already in the blob (the all-clear masks of opaque tiles,
    # faces that look the same, the spans of moods with one outline) is not stored again
    def __init__(self):
        self.sprites = []
        self.data = bytearray()
        self.added = []   # the bytes each sprite added to the blob

    def place(self, block):
        # where block is in the blob: an earlier copy, else appended, overlapping the blob's
        # end as far as they agree
        block = bytes(block)
        at = self.data.find(block)
        if at >= 0:
            return at
        for k in range(min(len(block) - 1, len(self.data)), 0, -1):
            if self.data.endswith(block[:k]):
                at = len(self.data) - k
                self.data += block[k:]
                return at
        at = len(self.data)
        self.data += block
        return at

    def add(self, name, c, col0, cols, top, rows):
        pics, masks, spans = cut(c, col0, cols, top, rows)
        before = len(self.data)
        offsets = (self.place(pics), self.place(masks), self.place(spans))
        self.sprites.append((name, cols, rows, offsets))
        self.added.append(len(self.data) - before)
        return len(self.sprites) - 1

    def add_box(self, name, c):
        col0, cols, top, rows = byte_box(bbox(c))
        return self.add(name, c, col0, cols, top, rows)


def inside_idle(idle, mood):
    # whether every pixel where mood differs from idle is drawn in both: the same silhouette
    for y in range(192):
        for x in range(280):
            if idle.px[y][x] != mood.px[y][x] and (idle.px[y][x] == "." or mood.px[y][x] == "."):
                return False
    return True


def silhouette(c):
    # which pixels a drawing covers, as one string
    return "".join("".join("1" if ch != "." else "0" for ch in row) for row in c.px)


def diff_box(a, b):
    xs, ys = [], []
    for y in range(192):
        for x in range(280):
            if a.px[y][x] != b.px[y][x]:
                xs.append(x)
                ys.append(y)
    if not xs:
        return None
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


# the actor kinds: name, how to draw a mood (and flap), shadow width; drawn where the mockup
# put them. A mood that is not here falls back to the drawing named in FALLBACK
KINDS = [
    ("CAT", lambda c, mood, flap: hero.cat(c, 70, GROUND + 2, mood), 14, {"angry": "bark"}),
    ("CAP_BIG", lambda c, mood, flap: actors.cap(c, 158, GROUND, 1.15, mood), 12,
     {"bark": "angry", "happy": "idle", "ko": "stunned"}),
    ("CAP_SMALL", lambda c, mood, flap: actors.cap(c, 193, GROUND - 2, 0.85, mood), 9,
     {"bark": "angry", "happy": "idle", "ko": "stunned"}),
    ("BAT", lambda c, mood, flap: actors.bat(c, 232, 66, mood, flap), 11,
     {"idle": "angry", "bark": "angry", "happy": "angry", "ko": "hurt"}),
    ("BOSS_DOG", lambda c, mood, flap: boss.boss_dog(c, 196, GROUND, mood), 24, {"bark": "angry", "happy": "idle"}),
]
FLAPS = {"BAT"}


def export_kinds(sheet):
    rows = []
    for name, draw, shadow_rx, fallback in KINDS:
        drawn = {}
        for mood in MOODS:
            real = fallback.get(mood, mood)
            drawn[mood] = outlined(lambda c, real=real: draw(c, real, 0))
        idle = drawn["idle"]
        boxes = [bbox(d) for d in drawn.values()]
        flap_c = None
        if name in FLAPS:
            flap_c = outlined(lambda c: draw(c, fallback.get("idle", "idle"), 1))
            boxes.append(bbox(flap_c))
        box = (min(b[0] for b in boxes), min(b[1] for b in boxes),
               max(b[2] for b in boxes), max(b[3] for b in boxes))
        col0, cols, top, nrows = byte_box(box)
        body = sheet.add(name, idle, col0, cols, top, nrows)
        flap = 255
        if flap_c is not None:
            flap = sheet.add(name + "_FLAP", flap_c, col0, cols, top, nrows)
        # faces whose changes all lie inside the idle silhouette share one patch box, idle's
        # own face included, so the game can swap one for another by drawing it over the
        # other (the look stays the same outside the face). The rest (stars round the head)
        # get a box of their own and redraw the whole actor
        inside = [m for m in MOODS if inside_idle(idle, drawn[m])]
        shared = None
        for m in inside:
            d = diff_box(idle, drawn[m])
            if d is not None:
                shared = d if shared is None else (min(shared[0], d[0]), min(shared[1], d[1]),
                                                   max(shared[2], d[2]), max(shared[3], d[3]))
        # the rest only add to the outline (ears up, stars): drawn over the body, after it.
        # Moods with the same outline share one box, so their masks and spans are stored once
        outside = {}
        for m in MOODS:
            d = diff_box(idle, drawn[m])
            if m in inside or d is None:
                continue
            key = silhouette(drawn[m])
            b = outside.get(key)
            outside[key] = d if b is None else (min(b[0], d[0]), min(b[1], d[1]),
                                                max(b[2], d[2]), max(b[3], d[3]))
        patches = []
        for mood in MOODS:
            d = shared if mood in inside else diff_box(idle, drawn[mood])
            if d is None:
                patches.append((255, 0, 0, 0))
                continue
            if mood not in inside:
                d = outside[silhouette(drawn[mood])]
            pc0, pcols, ptop, prows = byte_box(d, even=False)
            pc0 = max(pc0, col0)
            pid = sheet.add(name + "_" + mood.upper(), drawn[mood], pc0, pcols, ptop, prows)
            patches.append((pid, pc0 - col0, ptop - top, 1 if mood in inside else 0))
        # the shadow sits on the ground under the actor's middle
        rows.append(dict(name=name, body=body, flap=flap, foot=GROUND - top, cols=cols,
                         patches=patches, shadow_rx=shadow_rx, centre=(box[0] + box[2]) // 2,
                         col0=col0))
    return rows


def export_shadows(sheet, kinds):
    # drawn under the actor's middle, where the actor was drawn, so the offset is plain
    for k in kinds:
        c = Canvas(".")
        actors.shadow(c, k["centre"], GROUND + 1, k["shadow_rx"])
        col0, cols, top, rows = byte_box(bbox(c))
        k["shadow"] = sheet.add(k["name"] + "_SHADOW", c, col0, cols, top, rows)
        k["shadow_dx"] = col0 - k["col0"]
        k["shadow_dy"] = top - GROUND


def export_effects(sheet):
    ids = {}
    for step in (0, 1):
        ids["POOF%d" % step] = sheet.add_box("POOF%d" % step, outlined(lambda c: actors.poof(c, 70, 60, step)))
    ids["BOLT"] = sheet.add_box("BOLT", outlined(lambda c: actors.bolt(c, 74, 60)))
    ids["MARKER"] = sheet.add_box("MARKER", outlined(lambda c: actors.marker(c, 75, 60)))
    return ids


def big_glyph(c, ch):
    for gy, row in enumerate(FONT[ch]):
        for gx, bit in enumerate(row):
            if bit == "#":
                c.rect(1 + gx * 2, 1 + gy * 2, 3 + gx * 2, 3 + gy * 2, "W")


def export_digits(sheet):
    # the floating numbers: 2-px-thick white glyphs with a black outline, 2 bytes wide
    first = None
    for ch in "0123456789+":
        c = outlined(lambda c: big_glyph(c, ch))
        n = sheet.add("BIG_" + ("PLUS" if ch == "+" else ch), c, 0, 2, 0, 16)
        first = n if first is None else first
    return first


def export_tiles(sheet):
    first = None
    for name, draw in icons.TILES + icons.OLD_TILES:
        c = Canvas("K")
        draw(c, 28, scenes.DIE_TOP)
        n = sheet.add("TILE_" + name, c, 4, 3, scenes.DIE_TOP, icons.TILE_H)
        first = n if first is None else first
    return first


def font_rows():
    # the hud font, ' ' to 'Z': 7 rows a glyph, bit 0 the leftmost dot
    out = []
    for code in range(32, 91):
        ch = chr(code)
        glyph = icons.GLYPHS.get(ch) or FONT.get(ch) or FONT["?"]
        for row in glyph:
            out.append(sum(1 << i for i, bit in enumerate(row) if bit == "#"))
    return out


def table(name, type_, values, per_line=16):
    lines = []
    for i in range(0, len(values), per_line):
        lines.append("    " + " ".join(str(v) for v in values[i:i + per_line]))
    return "(const %s (array %s %d)\n    (make (array %s %d)\n%s))\n" % (
        name, type_, len(values), type_, len(values), "\n".join("    " + l for l in lines))


def let_bytes(name, values, options=""):
    lines = []
    for i in range(0, len(values), 24):
        lines.append("        " + " ".join(str(v) for v in values[i:i + 24]))
    opt = (" " + options) if options else ""
    return "(let %s (array u8 %d)\n    (make (array u8 %d)\n%s)%s)\n" % (
        name, len(values), len(values), "\n".join(lines), opt)


HEADER = "; generated by tools/art/export.py from tools/art/*.py: do not edit, run it again\n"


def write_sprites(sheet, kinds, effects, digit0, tile0):
    data = list(sheet.data)
    n = len(sheet.sprites)
    out = [HEADER, "; sprites: %d, %d bytes\n\n" % (n, len(data))]
    out.append("(const SPRITE_COUNT u8 %d)\n" % n)
    out.append("(const NONE u8 255) ; no sprite\n\n")
    for i, (name, cols, rows, at) in enumerate(sheet.sprites):
        out.append("(const %s u8 %d) ; %d x %d\n" % (name, i, cols, rows))
    out.append("(const DIGIT_0 u8 %d) ; then 1 to 9 and PLUS\n" % digit0)
    out.append("(const TILE_FIRST u8 %d)\n\n" % tile0)
    out.append("; width in bytes, rows, and where its pictures, masks and spans start in sprite_data (sprites\n")
    out.append("; share blocks that are the same)\n")
    out.append(table("SPRITE_W", "u8", [s[1] for s in sheet.sprites]))
    out.append(table("SPRITE_H", "u8", [s[2] for s in sheet.sprites]))
    out.append(table("SPRITE_AT", "u16", [s[3][0] for s in sheet.sprites], 12))
    out.append(table("SPRITE_MASK_AT", "u16", [s[3][1] for s in sheet.sprites], 12))
    out.append(table("SPRITE_SPAN_AT", "u16", [s[3][2] for s in sheet.sprites], 12))
    out.append("\n; the actor kinds: body, wing frame, rows from the top to the ground, width\n")
    for i, k in enumerate(kinds):
        out.append("(const KIND_%s u8 %d)\n" % (k["name"], i))
    out.append("(const KIND_COUNT u8 %d)\n" % len(kinds))
    out.append("(const MOOD_COUNT u8 %d) ; %s\n" % (len(MOODS), " ".join(MOODS)))
    out.append(table("KIND_BODY", "u8", [k["body"] for k in kinds]))
    out.append(table("KIND_FLAP", "u8", [k["flap"] for k in kinds]))
    out.append(table("KIND_FOOT", "u8", [k["foot"] for k in kinds]))
    out.append(table("KIND_COLS", "u8", [k["cols"] for k in kinds]))
    out.append(table("KIND_SHADOW", "u8", [k["shadow"] for k in kinds]))
    out.append(table("KIND_SHADOW_DX", "i8", [k["shadow_dx"] for k in kinds]))
    out.append(table("KIND_SHADOW_DY", "i8", [k["shadow_dy"] for k in kinds]))
    out.append("; by kind * MOOD_COUNT + mood: the face patch, NONE for the body's own face\n")
    out.append(table("KIND_PATCH", "u8", [p[0] for k in kinds for p in k["patches"]], 7))
    out.append(table("KIND_PATCH_DX", "u8", [p[1] for k in kinds for p in k["patches"]], 7))
    out.append(table("KIND_PATCH_DY", "u8", [p[2] for k in kinds for p in k["patches"]], 7))
    out.append("; 1 when the patch is one of the kind's faces that share a box: drawn over another\n")
    out.append(table("KIND_PATCH_SWAPS", "u8", [p[3] for k in kinds for p in k["patches"]], 7))
    out.append("\n; the hud font from ' ' to 'Z', 7 rows a glyph, bit 0 the leftmost dot. Icons: * heart,\n")
    out.append("; # shield, ! sword, % flame, @ ghost, + mend, $ diamond, & spark, \" hit all, < buff,\n")
    out.append("; = summon, > dive, ; ward pip, ' mana pip, , fleas\n")
    out.append(table("FONT", "u8", font_rows(), 14))
    open(os.path.join(GAME_ART, "sprites.tsp"), "w").write("".join(out))
    open(os.path.join(GAME_ART, "sprite_data.tsp"), "w").write(
        HEADER + "; every sprite's bytes, at the offsets in sprites.tsp\n\n" + let_bytes("bytes", data))
    return len(data)


def preview(sheet_canvases):
    for name, c, high in sheet_canvases:
        render(c, os.path.join(SHOTS, name + "_ntsc.png"), "ntsc", high)
        render(c, os.path.join(SHOTS, name + "_color.png"), "color", high)


def main():
    os.makedirs(GAME_ART, exist_ok=True)
    os.makedirs(SHOTS, exist_ok=True)
    sheet = Sheet()
    kinds = export_kinds(sheet)
    export_shadows(sheet, kinds)
    effects = export_effects(sheet)
    digit0 = export_digits(sheet)
    tile0 = export_tiles(sheet)
    size = write_sprites(sheet, kinds, effects, digit0, tile0)
    print("sprites: %d, %d bytes" % (len(sheet.sprites), size))
    if "--sizes" in sys.argv:
        for (name, cols, rows, at), added in zip(sheet.sprites, sheet.added):
            print("  %-18s %2d x %3d  %5d alone, %5d added" % (name, cols, rows, 2 * cols * rows + 2 * rows, added))

    forest = scenes.forest()
    open(os.path.join(GAME_ART, "backdrop.tsp"), "w").write(
        HEADER + "; the forest battle screen, as hi-res page bytes, in aux memory\n\n"
        + let_bytes("backdrop", list(to_hgr(forest)), ":in aux"))
    titles = []
    for step in range(4):
        t = scenes.title(step)
        titles.append(("title_%d" % step, t, True))
        open(os.path.join(GAME_ART, "title_%d.tsp" % step), "w").write(
            HEADER + "; the title screen, glow step %d of 0 to 3 (faint to full), as hi-res page bytes\n\n" % step
            + let_bytes("picture", list(to_hgr(t, True)), ":in aux"))
    preview([("forest", forest, False)] + titles)
    print("ok")


main()
