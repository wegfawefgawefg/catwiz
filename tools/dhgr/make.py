# the double hi-res art round: every picture through Tisple's emulator (headless), the byte
# tables in art/dhgr/, the previews in shots/dhgr/, and the memory each fight needs.
#
# run: python3 tools/dhgr/make.py            (everything)
#      python3 tools/dhgr/make.py fights     (or: cast, icons, font, light, palettes, lanes,
#                                            memory, game: the game's tables in game/art/)
#
# TISPLE=path picks the emulator (default: the Tisple build next to this repo's siblings).

import os
import sys

sys.dont_write_bytecode = True
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import cat  # noqa: E402
import dhgr  # noqa: E402
import emu  # noqa: E402
import export  # noqa: E402
import fonts  # noqa: E402
import foes  # noqa: E402
import forest  # noqa: E402
import hud  # noqa: E402
import icons  # noqa: E402
import light  # noqa: E402
import night  # noqa: E402
import palettes  # noqa: E402
import screen  # noqa: E402
from canvas import Canvas  # noqa: E402

ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
SHOTS = os.path.join(ROOT, "shots", "dhgr")
ART = os.path.join(ROOT, "art", "dhgr")


def day_shadow(P):
    def shadow(c, cx, y, rx):
        c.ellipse(cx, y, rx, 2.2, P["shadow"])
    return shadow


def fights():
    # each fight screen's backdrop with everyone at their spots in their idle frames, both
    # looks (the game's own screenshots show the rest), one contact sheet
    import figures
    import game_sprites as gs
    import screens
    cells = []
    for F in screens.fights():
        c = night.picture_for(F).copy()
        cast = [("cat", 4)] + [(f, col) for _, f, col in F["cast"]]
        for name, col in cast:
            K = figures.KINDS[name]
            fig = light.lit(figures.BLOCKS[K.block].draw(K.roles["idle"]), "night")
            base = gs.block_sprites(K.block)[0]
            c.paste(fig, col * 7 // 2 - base.col * 7 // 2, 0)
        name = "screen_fight%d" % F["n"]
        p = emu.show(c.px, SHOTS, name)
        cells += [("fight %d %s - NTSC" % (F["n"], F["zone"]), p["ntsc"]),
                  ("fight %d %s - colour" % (F["n"], F["zone"]), p["color"])]
    print(emu.sheet(cells, 2, os.path.join(SHOTS, "fights.png")))


def lane_pictures():
    # each fight's backdrop with its lanes tinted by what they are for (lanes.py), and a check
    # that every lane is black
    import lanes
    import screens
    for F in screens.fights():
        bd = night.picture_for(F)
        bad = lanes.check(F["n"], bd.px)
        print(lanes.debug_image(F["n"], bd.px, os.path.join(SHOTS, "lanes_screen_fight%d.png" % F["n"])),
              "pixels not black in a lane: %d" % bad)
        if bad:
            raise SystemExit("make.py: fight %d has scenery in a lane" % F["n"])


def cast():
    # every frame of every figure, lit by night, enlarged
    from PIL import Image
    import figures
    tiles = []
    for name, b in figures.BLOCKS.items():
        for f in b.frames:
            c = light.lit(b.draw(f), "night")
            x0, y0, x1, y1 = c.bbox()
            w, h = 64, 112
            ox, oy = (x0 + x1) // 2 - w // 2, y1 - (h - 6)
            im = Image.new("RGB", (w, h), dhgr.RGB[dhgr.BLACK])
            for y in range(h):
                for x in range(w):
                    v = c.get(x + ox, y + oy)
                    if v is not None:
                        im.putpixel((x, y), dhgr.RGB[v])
            tiles.append(im.resize((w * 4, h * 2), Image.NEAREST))
    cols = 6
    w, h = tiles[0].size
    sheet = Image.new("RGB", (cols * (w + 6) + 6, ((len(tiles) + cols - 1) // cols) * (h + 6) + 6), (30, 30, 34))
    for i, t in enumerate(tiles):
        sheet.paste(t, (6 + (i % cols) * (w + 6), 6 + (i // cols) * (h + 6)))
    path = os.path.join(SHOTS, "cast_night.png")
    sheet.save(path)
    print(path)


def icon_sheet():
    # the items' pictures, then the charms' (charm_icons.py)
    import charm_icons
    c = Canvas(dhgr.BLACK)
    names = list(icons.ICONS) + list(charm_icons.CHARMS)
    for i, n in enumerate(names):
        x, y = 3 + (i % 9) * 15, 6 + (i // 9) * 26
        c.rect(x - 1, y - 2, x + 12, y + 18, dhgr.WHITE)
        if n in icons.ICONS:
            icons.draw(c, x, y, n)
        else:
            c.stamp(x, y, charm_icons.CHARMS[n], icons.KEY)
    p = emu.show(c.px, SHOTS, "icons")
    print(p["ntsc"])


def font_sheet():
    # the 40-column font (dots) and the 35-column one (whole colour pixels), both looks
    chars = [chr(i) for i in range(32, 127)]
    say = ["The cat casts GOLD WAND: 3 damage.", "Puffcap hits you for 4. Fluff +3.",
           "TUNA heals 2. Hiss: -1 to its hit.", "1-5 pick  R re-roll (2)  E end"]
    lines = {}
    text = ["".join(chars[i:i + 40]) for i in range(0, len(chars), 40)] + [""] + say
    for r, s in enumerate(text):
        fonts.text40(lines, 2 + r, s, ((4, 8),) if r == 4 else ())
    px = [[0] * dhgr.W for _ in range(dhgr.H)]
    c = Canvas(dhgr.BLACK)
    text = ["".join(chars[i:i + 35]) for i in range(0, len(chars), 35)] + [""] + say
    for r, s in enumerate(text):
        fonts.text35(c, 13 + r, s, dhgr.WHITE, ((4, 8),) if r == 4 else ())
    for y in range(104, dhgr.H):
        px[y] = c.px[y][:]
    p = emu.show(px, SHOTS, "fonts", lines={y: v for y, v in lines.items() if y < 104})
    print(p["ntsc"])
    # one fight with the 35-column text in place of the 40
    P = palettes.DAY
    c, lines = screen.build(forest.picture(P), "day", ["puffcap", "sporelet"], day_shadow(P), text=[])
    for r, (s, inv) in enumerate(screen.TEXT):
        fonts.text35(c, 20 + r, s[:35], dhgr.WHITE, inv)
    p = emu.show(c.px, SHOTS, "fight1_clearing_35col")
    print(p["color"])


def lighting():
    # the proof: the same cat and puffcap sprites under the three zones' lighting
    cells = []
    P = palettes.DAY
    for zone in ("day", "dusk", "night"):
        if zone == "day":
            bd, sh, li = forest.picture(P), day_shadow(P), None
        elif zone == "dusk":
            bd, sh, li = night.dusk(), night.dusk_shadow, None
        else:
            bd, sh, li = night.picture("clearing"), night.no_shadow, None
        c, lines = screen.build(bd, zone, ["puffcap"], sh, lights=li,
                                U=hud.U_NIGHT if zone == "night" else None)
        p = emu.show(c.px, SHOTS, "light_" + zone, lines=lines)
        cells += [(zone + " - NTSC", p["ntsc"]), (zone + " - colour", p["color"])]
    print(emu.sheet(cells, 2, os.path.join(SHOTS, "lighting.png")))


def palette_sheet():
    # each fight's colours on the stage (rows 0-123), widest first: the backdrop's and the
    # fighters', with how much of the stage each covers, and their brightness tier
    from PIL import Image, ImageDraw, ImageFont
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 13)
        bold = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
    except OSError:
        font = bold = ImageFont.load_default()
    rows = []
    for F in palettes.FIGHTS:
        P = F["P"]
        if F["zone"] == "night":
            bd = night.picture(F["variant"], F["n"])
            c, _ = screen.build(bd, "night", F["foes"], night.no_shadow, U=hud.U_NIGHT)
        else:
            bd = forest.picture(P, F["variant"])
            c, _ = screen.build(bd, F["zone"], F["foes"], day_shadow(P))
        n = {}
        back = set()
        for y in range(forest.STAGE):
            for x in range(dhgr.W):
                n[c.px[y][x]] = n.get(c.px[y][x], 0) + 1
                back.add(bd.px[y][x])
        rows.append(("fight %d %s" % (F["n"], F["variant"]), n, back))
    sw, pad = 74, 8
    im = Image.new("RGB", (230 + 15 * (sw + 4), len(rows) * 96 + pad), (24, 24, 28))
    d = ImageDraw.Draw(im)
    for r, (label, n, back) in enumerate(rows):
        y = pad + r * 96
        d.text((pad, y + 20), label, fill=(235, 235, 235), font=bold)
        d.text((pad, y + 42), "%d colours, %d in the backdrop" % (len(n), len(back)), fill=(180, 180, 180), font=font)
        total = sum(n.values())
        for k, (col, cnt) in enumerate(sorted(n.items(), key=lambda kv: -kv[1])):
            x = 230 + k * (sw + 4)
            d.rectangle([x, y, x + sw, y + 44], fill=dhgr.RGB[col])
            d.rectangle([x, y + 46, x + sw, y + 52], fill=(dhgr.LUMA[col],) * 3)
            d.text((x, y + 56), dhgr.NAMES[col], fill=(230, 230, 230), font=font)
            tag = "%.1f%%%s" % (100.0 * cnt / total, "" if col in back else " fig")
            d.text((x, y + 72), tag, fill=(170, 170, 170), font=font)
    path = os.path.join(SHOTS, "palettes.png")
    im.save(path, optimize=True)
    print(path)


def main():
    # font, light and palettes are the old plan's day previews (their tray's icons are gone
    # since the items round): by name only
    what = sys.argv[1:] or ["fights", "cast", "icons", "lanes", "memory", "game"]
    os.makedirs(SHOTS, exist_ok=True)
    for w in what:
        if w == "fights":
            fights()
        elif w == "cast":
            cast()
        elif w == "icons":
            icon_sheet()
        elif w == "font":
            font_sheet()
        elif w == "light":
            lighting()
        elif w == "palettes":
            palette_sheet()
        elif w == "lanes":
            lane_pictures()
        elif w == "memory":
            import memory
            memory.run(ART)
        elif w == "game":
            import game
            game.main()
        else:
            raise SystemExit("make.py: no step " + w)


if __name__ == "__main__":
    main()
