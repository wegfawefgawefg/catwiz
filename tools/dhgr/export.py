# the art as the game's byte tables, written to art/dhgr/, and what each fight needs in memory.
#
# formats (all little endian, every byte of a picture or mask uses bits 0-6; bit 7 is 0):
#   screens/NAME.bin   a whole double hi-res screen: the 8 KB main page then the 8 KB aux
#                      page, both $2000-relative (main to $2000, aux to aux $2000)
#   patches/NAME.bin   a variant's changes over its base screen: a count, then per patch
#                      x0 (pixels, a multiple of 7), top row, width (pixels), rows, and the
#                      rows' bytes in screen order (aux, main, aux, main, ...): a straight copy
#   sprites/NAME.bin   one figure frame, lit for a zone, in screen format: x0, top, width,
#                      rows (one byte each), then rows of picture bytes, then rows of mask
#                      bytes (bit set: keep the screen); a row's bytes alternate aux, main
#   materials/NAME.bin the same frame unlit, as the game would store it once for every zone:
#                      x0, top, width, rows, bits a pixel, the entry count, then each entry's
#                      colour in the day, dusk and night (3 bytes), then the pixels as a bit
#                      stream, high bits first (all ones: clear). The loader turns it into a
#                      zone's sprite and adds the zone's rims (light.py)
#   icons.bin          the twelve card pictures, 14 x 15 pixels each (two 7-pixel steps), in
#                      icons.ICONS order: picture rows then mask rows
#   font40.bin         95 glyphs ' ' to '~', 8 rows of (aux byte, main byte); then the same
#                      in inverse
# x0 is the sprite's left edge on the 7-pixel grid (4 bytes a step), so it lands on whole
# bytes with its colours; the game may draw it at any other multiple of 7.

import os

import dhgr

def screen_bytes(px, lines=None):
    main, aux = dhgr.to_pages(px, lines)
    return main + aux


def sprite_bytes(s):
    head = bytes([s.x0, s.y0, s.w, s.h])
    return head + bytes(s.pic) + bytes(s.mask)


def material_bytes(c, box):
    # a material drawing's box on the 7 grid as a bit stream of entries into the frame's own
    # table; materials that every zone colours alike share an entry (ink, fur and the hat are
    # one black). The table lists, per entry, its colour in each zone (day, dusk, night).
    import math
    import light
    zones = ("day", "dusk", "night")
    x0, y0, x1, y1 = box
    x0 = x0 // 7 * 7
    x1 = -(-x1 // 7) * 7
    looks = []
    index = {}
    for y in range(y0, y1):
        for x in range(x0, x1):
            v = c.px[y][x]
            if v is not None:
                look = tuple(light.ZONES[z][v] for z in zones)
                if look not in index:
                    index[look] = len(looks)
                    looks.append(look)
    bits = max(1, math.ceil(math.log2(len(looks) + 1)))
    clear = (1 << bits) - 1
    acc = n = 0
    body = bytearray()
    for y in range(y0, y1):
        for x in range(x0, x1):
            v = c.px[y][x]
            acc = (acc << bits) | (clear if v is None else index[tuple(light.ZONES[z][v] for z in zones)])
            n += bits
            while n >= 8:
                n -= 8
                body.append((acc >> n) & 0xFF)
    if n:
        body.append((acc << (8 - n)) & 0xFF)
    head = bytes([x0, y0, x1 - x0, y1 - y0, bits, len(looks)]) + bytes(v for look in looks for v in look)
    return head + bytes(body), looks


def patches(base_px, px, step=7):
    # the boxes where px differs from base_px: per run of changed rows, the changed columns
    # widened to the 7 grid; touching runs are merged
    rows = []
    for y in range(dhgr.H):
        xs = [x for x in range(dhgr.W) if (base_px[y][x] or 0) != (px[y][x] or 0)]
        rows.append((min(xs), max(xs) + 1) if xs else None)
    out = []
    y = 0
    while y < dhgr.H:
        if rows[y] is None:
            y += 1
            continue
        y0 = y
        a, b = rows[y]
        while y < dhgr.H and rows[y] is not None:
            a, b = min(a, rows[y][0]), max(b, rows[y][1])
            y += 1
        out.append((a // step * step, y0, -(-b // step) * step, y))
    return out


def patch_bytes(px, boxes):
    out = bytearray([len(boxes)])
    for x0, y0, x1, y1 in boxes:
        out += bytes([x0, y0, x1 - x0, y1 - y0])
        for y in range(y0, y1):
            b = dhgr.row_bytes(px[y])
            out += bytes(b[x0 // 7 * 4:x1 // 7 * 4])
    return bytes(out)


def write(root, rel, data):
    path = os.path.join(root, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(data)
    return path


def report_line(name, raw, note=""):
    return "%-34s %7d raw %7d packed  %s" % (name, len(raw), dhgr.packed(raw), note)
