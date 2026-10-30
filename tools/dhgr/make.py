# the double hi-res art round: every picture through Tisple's emulator (headless), the byte
# tables in art/dhgr/, the previews in shots/dhgr/, and the memory each fight needs.
#
# run: python3 tools/dhgr/make.py            (everything)
#      python3 tools/dhgr/make.py fights     (or: cast, icons, font, light, palettes, memory,
#                                            game: the game's tables in game/art/, game.py)
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
    # the four day fights, each in both looks, a luma check, and one contact sheet
    cells = []
    for F in palettes.FIGHTS:
        P = F["P"]
        bd = forest.picture(P, F["variant"])
        c, lines = screen.build(bd, F["zone"], F["foes"], day_shadow(P))
        name = "fight%d_%s" % (F["n"], F["variant"])
        p = emu.show(c.px, SHOTS, name, lines=lines)
        emu.grey_of(p["color"], os.path.join(SHOTS, name + "_grey.png"))
        cells += [("fight %d %s - NTSC" % (F["n"], F["variant"]), p["ntsc"]),
                  ("fight %d %s - colour" % (F["n"], F["variant"]), p["color"])]
    print(emu.sheet(cells, 2, os.path.join(SHOTS, "day_fights.png")))


def frames_of(kind):
    return cat.FRAMES if kind == "cat" else foes.FRAMES[kind]


def drawing(kind, frame):
    return screen.figure(kind, frame)


def cast():
    # every frame of everyone, lit by day, dusk and night, in the flat look and enlarged
    from PIL import Image
    kinds = ["cat", "puffcap", "sporelet", "nightflap"]
    bgs = {"day": dhgr.AQUA, "dusk": dhgr.PURPLE, "night": dhgr.BLACK}
    for zone in ("day", "dusk", "night"):
        tiles = []
        for k in kinds:
            for f in frames_of(k):
                c = light.lit(drawing(k, f), zone)
                x0, y0, x1, y1 = c.bbox()
                ox, oy = (x0 + x1) // 2 - 28, y1 - 98
                im = Image.new("RGB", (56, 104), dhgr.RGB[bgs[zone]])
                for y in range(104):
                    for x in range(56):
                        v = c.get(x + ox, y + oy)
                        if v is not None:
                            im.putpixel((x, y), dhgr.RGB[v])
                tiles.append(im.resize((56 * 4, 104 * 2), Image.NEAREST))
        cols = 5
        w, h = tiles[0].size
        sheet = Image.new("RGB", (cols * (w + 6) + 6, ((len(tiles) + cols - 1) // cols) * (h + 6) + 6), (30, 30, 34))
        for i, t in enumerate(tiles):
            sheet.paste(t, (6 + (i % cols) * (w + 6), 6 + (i // cols) * (h + 6)))
        path = os.path.join(SHOTS, "cast_%s.png" % zone)
        sheet.save(path)
        print(path)


def icon_sheet():
    c = Canvas(dhgr.BLACK)
    names = list(icons.ICONS)
    for i, n in enumerate(names):
        x, y = 7 + (i % 6) * 21, 8 + (i // 6) * 32
        c.rect(x - 2, y - 2, x + 13, y + 18, dhgr.WHITE)
        icons.draw(c, x, y, n)
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
            bd, sh, li = night.night(), night.no_shadow, night.night_lights(["cat", "puffcap"])
        c, lines = screen.build(bd, zone, ["puffcap"], sh, lights=li)
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
    what = sys.argv[1:] or ["fights", "cast", "icons", "font", "light", "palettes", "memory", "game"]
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
