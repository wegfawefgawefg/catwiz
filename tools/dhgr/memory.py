# the byte tables (export.py's formats) written to art/dhgr/, and the memory each day fight
# needs, raw and packed (zlib -9: a stand-in for the packer Tisple is adding). Written to
# art/dhgr/memory.txt and printed.

import os

import dhgr
import export
import fonts
import forest
import hud
import icons
import light
import night
import palettes
import screen
import cat
import foes
from canvas import Canvas

STAGE_ROWS = forest.STAGE


def stage_bytes(px, rows=range(0, STAGE_ROWS)):
    # the rows a backdrop really needs, in screen order: the tray and text are drawn by code
    out = bytearray()
    for y in rows:
        out += bytes(dhgr.row_bytes(px[y]))
    return bytes(out)


def frames(kind):
    return cat.FRAMES if kind == "cat" else foes.FRAMES[kind]


def span_bytes(c, box):
    # a sprite stored by rows: per row its first 4-byte step and how many, then only those
    # bytes, picture and mask (rows that are empty cost their two bytes)
    x0, y0, x1, y1 = box
    out = 0
    for y in range(y0, y1):
        xs = [x for x in range(x0, x1) if c.px[y][x] is not None]
        out += 2
        if xs:
            out += (max(xs) // 7 - min(xs) // 7 + 1) * 4 * 2
    return out


def best_patch(idle, frame):
    # the frame as idle drawn dy rows lower plus a patch box where they still differ: the
    # hop, a blink, a new mouth. Returns (bytes, dy) of the smallest, or None.
    best = None
    for dy in range(-8, 9):
        moved = idle.shifted(0, dy)
        xs, ys = [], []
        for y in range(dhgr.H):
            a, b = moved.px[y], frame.px[y]
            for x in range(dhgr.W):
                if a[x] != b[x]:
                    xs.append(x)
                    ys.append(y)
        if not xs:
            size = 4
        else:
            g0, g1 = min(xs) // 7, max(xs) // 7 + 1
            size = 4 + (g1 - g0) * 4 * 2 * (max(ys) + 1 - min(ys))
        if best is None or size < best[0]:
            best = (size, dy)
    return best


class Kind:
    # one fighter's frames for one zone: written to art/dhgr/, and their sizes
    def __init__(self, art, kind, zone):
        self.lit, self.mats = bytearray(), bytearray()
        self.trimmed = 0
        idle = None
        for fr in frames(kind):
            d = screen.figure(kind, fr)
            lit = light.lit(d, zone)
            s = dhgr.cut("%s_%s" % (kind, fr), lit.px, lit.bbox())
            raw = export.sprite_bytes(s)
            export.write(art, "sprites/%s/%s_%s.bin" % (zone, kind, fr), raw)
            mb, _ = export.material_bytes(d, d.bbox())
            export.write(art, "materials/%s_%s.bin" % (kind, fr), mb)
            self.lit += raw
            self.mats += mb
            spans = span_bytes(lit, lit.bbox())
            if idle is None:
                idle = lit
                self.trimmed += spans
            else:
                self.trimmed += min(spans, best_patch(idle, lit)[0])

    def packed(self):
        return dhgr.packed(bytes(self.mats))


def run(art):
    out = []
    say = out.append
    say("Catwiz double hi-res art: memory for the day fights (python3 tools/dhgr/make.py memory)")
    say("raw: bytes as the game uses them. packed: zlib -9 (a stand-in for Tisple's packer).")
    say("lit sprites: picture + mask, every frame whole; trimmed: each row only its bytes, and a")
    say("frame that is idle moved plus a patch (the hop, a new face) stored as that.")
    say("materials: a frame unlit at 3-5 bits a pixel, one copy for every zone (light.py).")
    say("")
    # ---- shared by every fight
    icon_blob = bytearray()
    for n in icons.ICONS:
        one = Canvas()
        icons.draw(one, 0, 0, n)
        icon_blob += dhgr.cut(n, one.px, (0, 0, 14, icons.ICON_H)).raw()
    export.write(art, "icons.bin", bytes(icon_blob))
    font = bytearray()
    for i in range(32, 127):
        for a, m in fonts.cell_bytes(chr(i)):
            font += bytes([a, m])
    export.write(art, "font40.bin", bytes(font))
    font35 = bytearray()
    for i in range(32, 127):
        g = fonts.F35.get(chr(i), [])
        rows = [(r + "...")[:3] for r in g] + ["..."] * (8 - len(g))
        font35 += bytes(sum((ch == "#") << k for k, ch in enumerate(r)) for r in rows[:8])
    export.write(art, "font35.bin", bytes(font35))
    tray = Canvas(dhgr.BLACK)
    hud.tray(tray, hud.U_DAY, [("lint", "")] * 5, None)
    tray_raw = stage_bytes(tray.px, range(hud.TRAY_TOP, hud.TEXT_TOP))
    kinds = {}
    for k in ["cat", "puffcap", "sporelet", "nightflap"]:
        kinds[k] = Kind(art, k, "day")
    cat_ = kinds["cat"]
    say("shared by every fight")
    say("  " + export.report_line("12 card pictures (pic+mask)", icon_blob))
    say("  " + export.report_line("40-column font (95 glyphs)", font, "inverse: each byte XOR $7F"))
    say("  " + export.report_line("  or the 35-column font", font35, "3 pixels a row, shifted into place"))
    say("  " + export.report_line("tray picture, rows 124-159", tray_raw, "card blanks, buttons; icons go on top"))
    say("  " + export.report_line("the cat, %d frames, lit" % len(cat.FRAMES), cat_.lit, "trimmed: %d" % cat_.trimmed))
    say("  " + export.report_line("  the cat as materials", cat_.mats))
    shared_pk = dhgr.packed(bytes(icon_blob) + bytes(font) + tray_raw) + cat_.packed()
    say("  %-34s %7s     %7d packed  (cards, 40-column font, tray, the cat as materials)" % ("stored", "", shared_pk))
    say("")
    run_pk = shared_pk
    seen = set()
    base = None
    for F in palettes.FIGHTS:
        P = F["P"]
        n, variant, zone = F["n"], F["variant"], F["zone"]
        bd = forest.picture(P, variant)
        name = "fight%d_%s" % (n, variant)
        main, aux = dhgr.to_pages(bd.px)
        export.write(art, "screens/%s.bin" % name, main + aux)
        stage = stage_bytes(bd.px)
        say("fight %d (%s, %s light): %s" % (n, variant, zone, ", ".join(["cat"] + F["foes"])))
        say("  " + export.report_line("screen, whole 16 KB page", main + aux))
        say("  " + export.report_line("screen, the stage (rows 0-%d)" % (STAGE_ROWS - 1), stage))
        screen_pk = dhgr.packed(stage)
        if base is None:
            base = bd
        else:
            boxes = export.patches(base.px, bd.px)
            pb = export.patch_bytes(bd.px, boxes)
            export.write(art, "patches/%s.bin" % name, pb)
            say("  " + export.report_line("  or patches over fight 1", pb, "%d boxes" % len(boxes)))
            screen_pk = min(screen_pk, dhgr.packed(pb))
        foes_lit = sum(len(kinds[k].lit) for k in F["foes"])
        foes_trim = sum(kinds[k].trimmed for k in F["foes"])
        foes_pk = sum(kinds[k].packed() for k in F["foes"])
        new_pk = sum(kinds[k].packed() for k in F["foes"] if k not in seen)
        seen |= set(F["foes"])
        say("  %-34s %7d raw %7d packed  as materials; trimmed lit %d" % ("enemies, every frame", foes_lit, foes_pk, foes_trim))
        ram = len(stage) + cat_.trimmed + foes_trim
        say("  %-34s %7d       while the fight runs: the stage's clean copy, the cat and" % ("in memory (beyond the pages)", ram))
        say("  %-34s %7s       the enemies lit and trimmed" % ("", ""))
        say("  %-34s %7s     %7d packed  (the screen as stored, enemies not stored before)" % ("stored, new for this fight", "", screen_pk + new_pk))
        run_pk += screen_pk + new_pk
        say("")
    say("the four day fights stored, everything above packed: %d bytes" % run_pk)
    say("")
    # the night and dusk backdrops of the lighting proof, for the next rounds
    for zone, bd in (("dusk", night.dusk()), ("night", night.night())):
        main, aux = dhgr.to_pages(bd.px)
        export.write(art, "screens/proof_%s.bin" % zone, main + aux)
    say("not counted: the two 16 KB pages the screen flips between (main and aux $2000-$5FFF).")
    text = "\n".join(out) + "\n"
    with open(os.path.join(art, "memory.txt"), "w") as f:
        f.write(text)
    print(text)
