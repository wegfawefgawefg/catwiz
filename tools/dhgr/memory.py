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


def run(art):
    out = []
    say = out.append
    say("Catwiz double hi-res art: memory per day fight (python3 tools/dhgr/make.py memory)")
    say("raw = bytes as the game uses them; packed = zlib -9 of those bytes (a stand-in packer)")
    say("")
    # ---- shared by every fight
    names = list(icons.ICONS)
    ic = Canvas()
    for i, n in enumerate(names):
        icons.draw(ic, (i % 10) * 14, (i // 10) * 16, n)
    for y in range(dhgr.H):
        for x in range(dhgr.W):
            if ic.px[y][x] == dhgr.WHITE or ic.px[y][x] is None:
                pass
    icon_blob = bytearray()
    for i, n in enumerate(names):
        one = Canvas()
        icons.draw(one, 0, 0, n)
        s = dhgr.cut(n, one.px, (0, 0, 14, icons.ICON_H))
        icon_blob += s.raw()
    export.write(art, "icons.bin", bytes(icon_blob))
    font = bytearray()
    for i in range(32, 127):
        for a, m in fonts.cell_bytes(chr(i)):
            font += bytes([a, m])
    export.write(art, "font40.bin", bytes(font))
    tray = Canvas(dhgr.BLACK)
    hud.tray(tray, hud.U_DAY, [("lint", "")] * 5, None)
    tray_raw = stage_bytes(tray.px, range(hud.TRAY_TOP, hud.TEXT_TOP))
    say("shared by all fights")
    say("  " + export.report_line("12 card pictures (pic+mask)", icon_blob))
    say("  " + export.report_line("40-column font (95 glyphs)", font, "inverse is the same XOR $7F"))
    say("  " + export.report_line("tray picture, rows 124-159", tray_raw, "card blanks, buttons; icons go on top"))
    shared_raw = len(icon_blob) + len(font) + len(tray_raw)
    shared_packed = dhgr.packed(bytes(icon_blob) + bytes(font) + tray_raw)
    say("  %-34s %7d raw %7d packed" % ("shared total", shared_raw, shared_packed))
    say("")
    # ---- the fights
    base = None
    sprite_cache = {}
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
        say("  " + export.report_line("screen, stage rows 0-123", stage))
        screen_pk = dhgr.packed(stage)
        if base is None:
            base = bd
        else:
            boxes = export.patches(base.px, bd.px)
            pb = export.patch_bytes(bd.px, boxes)
            export.write(art, "patches/%s.bin" % name, pb)
            say("  " + export.report_line("  or as patches over fight 1", pb, "%d boxes" % len(boxes)))
            screen_pk = min(screen_pk, dhgr.packed(pb))
        spr = bytearray()
        mats = bytearray()
        trimmed = 0
        for kind in ["cat"] + F["foes"]:
            idle = None
            for fr in frames(kind):
                key = (kind, fr, zone)
                d = screen.figure(kind, fr)
                lit = light.lit(d, zone)
                if key not in sprite_cache:
                    s_ = dhgr.cut("%s_%s" % (kind, fr), lit.px, lit.bbox())
                    raw = export.sprite_bytes(s_)
                    export.write(art, "sprites/%s/%s_%s.bin" % (zone, kind, fr), raw)
                    mb, used = export.material_bytes(d, d.bbox())
                    export.write(art, "materials/%s_%s.bin" % (kind, fr), mb)
                    spans = span_bytes(lit, lit.bbox())
                    if idle is None:
                        idle = lit
                        how = spans
                    else:
                        how = min(spans, best_patch(idle, lit)[0])
                    sprite_cache[key] = (raw, mb, how)
                else:
                    idle = idle or lit
                raw, mb, how = sprite_cache[key]
                spr += raw
                mats += mb
                trimmed += how
        say("  " + export.report_line("fighters, lit, pic+mask", spr, "every frame whole"))
        say("  %-34s %7d raw          rows trimmed to their bytes; a frame that is idle moved"
            % ("  trimmed, frames over idle", trimmed))
        say("  %-34s %7s              plus a patch (the hop, a new face) stored as that" % ("", ""))
        say("  " + export.report_line("  stored unlit (materials)", mats, "one copy for every zone"))
        tot_raw = len(stage) + len(spr)
        tot_pk = screen_pk + dhgr.packed(bytes(mats))
        say("  %-34s %7d raw %7d packed  (stage + lit sprites raw; best screen + materials packed)"
            % ("fight total", tot_raw, tot_pk))
        say("")
    # the night and dusk backdrops of the lighting proof, for the next rounds
    for zone, bd in (("dusk", night.dusk()), ("night", night.night())):
        main, aux = dhgr.to_pages(bd.px)
        export.write(art, "screens/proof_%s.bin" % zone, main + aux)
    say("in memory while a fight runs (not stored): two 16 KB pages to flip, and a clean copy of")
    say("the stage (rows 0-123: 9,920 bytes, half main half aux) to restore under moving sprites.")
    text = "\n".join(out) + "\n"
    with open(os.path.join(art, "memory.txt"), "w") as f:
        f.write(text)
    print(text)
