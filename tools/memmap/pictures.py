# the pictures: docs/memory-map.png (every space and both disks) and docs/memory-map-low.png
# ($0000-$1FFF byte by byte). One column 1100 pixels wide with big text, so a phone shows it at
# its width and scrolls down.

from PIL import Image, ImageDraw, ImageFont

from layout import COLOUR, KINDS, SPACES, USABLE, ZONES, composition, hexa, name_run, nbytes, span

W = 1100
BG = (24, 26, 31)
TEXT = (236, 236, 236)
DIM = (165, 169, 177)
TICK = (255, 60, 60)
INK = (20, 20, 20)

FONT_DIR = "/usr/share/fonts/truetype/dejavu/"


def font(size, mono=False, bold=False):
    name = "DejaVuSansMono" if mono else "DejaVuSans"
    if bold:
        name += "-Bold"
    return ImageFont.truetype(FONT_DIR + name + ".ttf", size)


F_TITLE = font(46, bold=True)
F_HEAD = font(34, bold=True)
F_LABEL = font(26)
F_ADDR = font(22, mono=True)
F_SMALL = font(22)
F_MIX = font(19, mono=True)
F_TINY = font(17, mono=True)
F_CELL = font(15, mono=True)

BAR_X = 120     # a memory bar's left edge (its addresses left of it)
LABEL_X = 330   # its labels' left edge
LABEL_H = 82    # a label's three lines


def hatch(d, box, colour):
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=colour)
    for k in range(int(x0 - (y1 - y0)), int(x1), 8):
        a = (max(x0, k), y0 + max(0, x0 - k))
        b = (min(x1, k + (y1 - y0)), y1 - max(0, k + (y1 - y0) - x1))
        d.line([a, b], fill=(150, 150, 150), width=2)


def fit(d, text, f, width):
    if d.textlength(text, font=f) <= width:
        return text
    while text and d.textlength(text + "...", font=f) > width:
        text = text[:-1]
    return text + "..."


def bar_height(lo, hi, scale):
    return (hi - lo) / scale


def draw_bar(d, m, space, lo, hi, x, y, w, scale, absorb=0, min_label=None, label_x=LABEL_X):
    # one space from lo to hi as a column at x, y, scale bytes a pixel, its labels at label_x;
    # min_label None draws no labels. Returns the bar's foot.
    base = SPACES[space][1]
    h = bar_height(lo, hi, scale)
    d.rectangle([x - 1, y - 1, x + w + 1, y + h + 1], outline=DIM)
    # every pixel row the kind most of its bytes are
    for py in range(int(h + 0.999)):
        a0 = lo + int(py * scale)
        a1 = min(hi, lo + int((py + 1) * scale))
        counts = {}
        for a in range(a0, max(a1, a0 + 1)):
            it = m.owner[space][a - base]
            k = it.kind if it else "free"
            counts[k] = counts.get(k, 0) + 1
        k = max(counts, key=lambda c: (counts[c], c == "free"))
        colour = COLOUR[k] if k != "unused" or py % 4 else (150, 150, 150)
        d.line([(x, y + py), (x + w, y + py)], fill=colour)
    # every free hole at least 2 pixels, with a red tick beside it, so fragments show
    for a, b in m.holes(space, max(lo, USABLE[space][0]), min(hi, USABLE[space][1])):
        y0 = y + (a - lo) / scale
        y1 = max(y + (b - lo) / scale, y0 + 2)
        d.rectangle([x, y0, x + w, y1], fill=COLOUR["free"])
        d.rectangle([x + w + 3, y0, x + w + 11, y1], fill=TICK)
    step = 0x1000 if hi - lo > 0x4000 else 0x400 if hi - lo > 0x800 else 0x100
    for a in range(lo - lo % step, hi + 1, step):
        if a < lo:
            continue
        ty = y + (a - lo) / scale
        d.line([(x - 8, ty), (x, ty)], fill=DIM)
        d.text((x - 11, ty), hexa(a), font=F_TINY, fill=DIM, anchor="rm")
    if min_label is None:
        return y + h
    labels = []
    cuts = sorted({c for c in ZONES.get(space, {}) if lo < c < hi} | {lo, hi})
    for z0, z1 in zip(cuts, cuts[1:]):
        for a, b, key, its in m.runs(space, z0, z1, absorb):
            if b - a < min_label and not (key[0] == "free" and b - a >= min_label // 4):
                continue
            zone = ZONES.get(space, {}).get(a) if (a, b) == (z0, z1) else None
            y0 = y + (a - lo) / scale
            y1 = max(y + (b - lo) / scale, y0 + 3)
            # a bracket beside the bar: what the label below names
            bx = x + w + 16 + 6 * (len(labels) % 2)
            d.line([(bx, y0), (bx, y1)], fill=COLOUR[key[0]], width=4)
            labels.append([(y0 + y1) / 2, a, b, key[0],
                           name_run(m, space, a, b, key[0], its, zone),
                           composition(m, space, a, b), bx + 2])
    return max(y + h, place_labels(d, labels, label_x, W - label_x - 20, y))


def place_labels(d, labels, x, w, top):
    # each label as near its run as the ones above it allow; a leader line from its bracket
    labels.sort(key=lambda l: l[0])
    cur = top
    foot = top
    for cy, a, b, kind, name, mix, edge_x in labels:
        yy = max(cy - 16, cur)
        cur = yy + LABEL_H
        d.line([(edge_x, cy), (x - 20, yy + 16), (x - 4, yy + 16)], fill=(110, 114, 122), width=1)
        d.rectangle([x, yy + 7, x + 14, yy + 23], fill=COLOUR[kind])
        d.text((x + 22, yy), fit(d, name, F_LABEL, w - 24), font=F_LABEL,
               fill=COLOUR["free"] if kind == "free" else TEXT)
        d.text((x + 22, yy + 31), "%s  %s" % (span(a, b), nbytes(b - a)), font=F_ADDR, fill=DIM)
        if mix:
            d.text((x + 22, yy + 57), fit(d, mix, F_MIX, w - 24), font=F_MIX, fill=DIM)
        foot = yy + LABEL_H
    return foot


def legend(d, x, y):
    for i, (k, name, c) in enumerate(KINDS):
        cy = y + i * 36
        box = [x, cy + 3, x + 36, cy + 29]
        if k == "unused":
            hatch(d, box, c)
        else:
            d.rectangle(box, fill=c)
        d.text((x + 50, cy), name, font=F_LABEL, fill=TEXT)
    cy = y + len(KINDS) * 36
    d.rectangle([x + 10, cy + 3, x + 18, cy + 29], fill=TICK)
    d.text((x + 50, cy), "beside the bar: a free hole, however small", font=F_LABEL, fill=TEXT)
    return cy + 50


def heading(d, y, title, sub):
    d.text((40, y), title, font=F_HEAD, fill=TEXT)
    for i, line in enumerate(sub):
        d.text((40, y + 46 + i * 30), line, font=F_SMALL, fill=DIM)
    return y + 46 + len(sub) * 30 + 30


def space_summary(m, spaces):
    t = {k: 0 for k in COLOUR}
    holes = []
    for s in spaces:
        for k, v in m.totals(s).items():
            t[k] += v
        holes += m.holes(s)
    used = sum(v for k, v in t.items() if k not in ("free", "hw"))
    free = sum(b - a for a, b in holes)
    big = max((b - a for a, b in holes), default=0)
    return "used %s, free %s in %d holes (the biggest %s)" % (nbytes(used), nbytes(free),
                                                              len(holes), nbytes(big))


# ---- disks

def draw_disk(d, cells, x, y, cw=27, ch=15):
    for tr in range(35):
        for s in range(16):
            k = cells[(tr, s)]
            box = [x + tr * cw, y + s * ch, x + tr * cw + cw - 2, y + s * ch + ch - 2]
            if k == "unused":
                hatch(d, box, COLOUR["unused"])
            else:
                d.rectangle(box, fill=COLOUR[k])
        if tr % 2 == 0:
            d.text((x + tr * cw + cw / 2, y + 16 * ch + 4), str(tr), font=F_CELL, fill=DIM,
                   anchor="mt")
    return y + 16 * ch + 30


def text_lines(d, lines, x, y, f=F_SMALL, step=30):
    for i, line in enumerate(lines):
        d.text((x, y + i * step), line, font=f, fill=TEXT)
    return y + len(lines) * step + 10


def disk1_lines(spans):
    return ["T%s  %s" % (str(a) if a == b else "%d-%d" % (a, b), name) for a, b, name in spans]


def disk2_lines(b):
    groups = {}
    for t in b.tables:
        if t[0] != 2:
            continue
        key = t[3] if "overlay group" in t[3] else t[3].split(".")[0]
        if key.startswith("art/screen_fight"):
            key = "art/screen_fight1-11"
        g = groups.setdefault(key, [t[1], t[2], 0, 0])
        g[1] = t[2]
        g[2] += t[4]
        g[3] += t[5]
    return ["T%d-%d  %s: %s, %d sectors" % (g[0], g[1], k, nbytes(g[2]), g[3])
            for k, g in groups.items()]


# ---- the overview

def overview(m, b, fights, cells1, spans1, cells2):
    img = Image.new("RGB", (W, 16000), BG)
    d = ImageDraw.Draw(img)
    d.text((40, 30), "Catwiz memory map", font=F_TITLE, fill=TEXT)
    y = text_lines(d, ["main, as built by tools/memmap/memmap.py; the audit is",
                       "docs/memory-map.md, low memory byte by byte in",
                       "docs/memory-map-low.png"], 40, 96, f=F_SMALL)
    y = legend(d, 40, y + 10) + 20
    # main and aux memory, 24 bytes a pixel
    for space, title in (("main", "Main memory, 64 KB"), ("aux", "Aux memory, 64 KB")):
        y = heading(d, y, title, [space_summary(m, [space]) + ", below $C000"])
        y = draw_bar(d, m, space, 0x0000, 0x10000, BAR_X, y, 150, 24, 160, 160) + 70
    # the language cards, 8 bytes a pixel: bank 1 beside bank 2 and $E000-$FFFF
    for spaces, title, what in ((("lc", "lc1"), "Language card, 16 KB", "code"),
                                (("alc", "alc1"), "Aux language card, 16 KB", "sprites")):
        y = heading(d, y, title, [space_summary(m, spaces),
                                  "left bank 1 (%s), right bank 2 then $E000-$FFFF" % what])
        t1 = m.totals(spaces[1])
        draw_bar(d, m, spaces[1], 0xD000, 0xE000, 80, y, 50, 8)
        d.text((60, y + 530), "bank 1", font=F_SMALL, fill=TEXT)
        d.text((60, y + 560), "free", font=F_SMALL, fill=DIM)
        d.text((60, y + 590), "{:,}".format(t1["free"]), font=F_SMALL, fill=COLOUR["free"])
        foot = draw_bar(d, m, spaces[0], 0xD000, 0x10000, 230, y, 110, 8, 40, 40, label_x=400)
        d.line([(222, y + 512), (346, y + 512)], fill=TEXT, width=3)
        y = foot + 60
    if fights:
        y = fight_chart(d, fights, y)
    # the disks
    y = heading(d, y, "Disk 1, the boot disk", ["35 tracks across, 16 sectors down; each segment",
                                                "starts a track; hatched: rounding, or zeros it loads"])
    y = draw_disk(d, cells1, 70, y)
    y = text_lines(d, disk1_lines(spans1), 40, y) + 40
    y = heading(d, y, "Disk 2", ["its tables in declaration order, a slot a sector"])
    y = draw_disk(d, cells2, 70, y)
    y = text_lines(d, disk2_lines(b), 40, y)
    return img.crop((0, 0, W, y + 40))


def fight_chart(d, fights, y):
    f0 = fights[0]
    y = heading(d, y, "Each fight's sprites", ["art/dhgr/memory.txt: what the hero's and the fight's",
                                              "blocks take of the aux card and sprite_aux"])
    rooms = (("bank 2 + $E000", f0["bank2_room"]), ("bank 1", f0["bank1_room"]),
             ("sprite_aux", f0["aux_room"]))
    for j, (name, room) in enumerate(rooms):
        d.text((150 + j * 240, y), "%s" % name, font=F_TINY, fill=DIM)
        d.text((150 + j * 240, y + 22), "{:,}".format(room), font=F_TINY, fill=DIM)
    d.text((880, y + 22), "spare", font=F_TINY, fill=DIM)
    y += 56
    for f in fights:
        d.text((40, y), "fight %d" % f["fight"], font=F_SMALL, fill=TEXT)
        for j, (u, r) in enumerate(((f["bank2"], f["bank2_room"]), (f["bank1"], f["bank1_room"]),
                                    (f["aux"], f["aux_room"]))):
            x0 = 150 + j * 240
            d.rectangle([x0, y + 4, x0 + 210, y + 26], fill=COLOUR["free"])
            d.rectangle([x0, y + 4, x0 + 210 * u / r, y + 26], fill=COLOUR["art"])
        d.text((880, y), "{:,}".format(f["spare"]), font=F_SMALL, fill=TEXT)
        y += 36
    return y + 50


# ---- low memory

def grid(d, m, space, base, x, y, cell=62):
    # a page a byte a cell, its address and a short name in each
    for i in range(256):
        a = base + i
        it = m.at(space, a)
        k = it.kind if it else "free"
        cx, cy = x + 44 + (i % 16) * cell, y + 26 + (i // 16) * cell
        box = [cx, cy, cx + cell - 3, cy + cell - 3]
        if k == "unused":
            hatch(d, box, COLOUR[k])
        else:
            d.rectangle(box, fill=COLOUR[k])
        if k == "free":
            d.rectangle(box, outline=TICK, width=4)
        name = it.name if (it and k != "free") else ""
        short = name.split(":")[-1].strip().split(",")[0].split(".")[-1].split(" ")[0][:6]
        d.text((cx + 4, cy + 4), "%02X" % (a & 0xFF), font=F_CELL, fill=INK)
        d.text((cx + 4, cy + 30), short, font=F_CELL, fill=INK)
    for c in range(16):
        d.text((x + 44 + c * cell + cell / 2, y + 4), "%X" % c, font=F_TINY, fill=DIM, anchor="mt")
    for r in range(16):
        d.text((x + 38, y + 26 + r * cell + cell / 2), "%X0" % r, font=F_TINY, fill=DIM,
               anchor="rm")
    return y + 26 + 16 * cell + 40


def low_memory(m, b):
    img = Image.new("RGB", (W, 12000), BG)
    d = ImageDraw.Draw(img)
    d.text((40, 30), "Catwiz low memory", font=F_TITLE, fill=TEXT)
    y = text_lines(d, ["$0000-$1FFF of main and aux memory: zero page and the",
                       "stack page a byte a cell, then 4 bytes a pixel"], 40, 96)
    y = legend(d, 40, y + 10) + 20
    zp_free = sum(1 for a in range(256) if m.at("main", a) is None or m.at("main", a).kind == "free")
    y = heading(d, y, "Zero page", ["the build counts %d of 256 used (frames %d);" % (
        b.zp_used, b.zp_frames), "%d bytes no let and no listing line names" % zp_free])
    y = grid(d, m, "main", 0x0000, 20, y)
    stack = [it for it in m.items if it.name == "6502 stack"][0]
    y = heading(d, y, "Stack page", ["scratch lets at fixed addresses, then the stack",
                                     "from %s" % hexa(stack.start)])
    y = grid(d, m, "main", 0x0100, 20, y)
    for space, title in (("main", "Main $0000-$1FFF"), ("aux", "Aux $0000-$1FFF")):
        holes = m.holes(space, 0x0000, 0x2000)
        y = heading(d, y, title, ["free %s in %d holes" % (nbytes(sum(b2 - a for a, b2 in holes)),
                                                            len(holes))])
        y = draw_bar(d, m, space, 0x0000, 0x2000, BAR_X, y, 150, 4, 24, 40) + 70
    return img.crop((0, 0, W, y))
