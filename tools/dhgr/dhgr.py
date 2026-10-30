# double hi-res, the hardware side: the 15 colours, a picture's 16 KB as main and aux page
# bytes, sprites cut out of a picture as masked byte tables, and the memory sums.
#
# the model (Tisple's apple2.hpp, video_render.cpp): each line is 560 dots; byte column c
# (0-39) shows its aux byte's 7 dots first, then its main byte's 7 (bit 0 leftmost, bit 7
# unused). Colour comes from 4-dot groups counted from the line's start: group g is dots
# 4g..4g+3, and the group's dots as a nibble (bit i = dot 4g+i) are the lo-res colour number.
# So the art is drawn at 140 x 192 colour pixels (one pixel = one 4-dot group), and 7 pixels
# fill exactly 4 bytes: aux c, main c, aux c+1, main c+1 for an even c. A sprite drawn at a
# pixel x that is a multiple of 7 lands on whole bytes with every colour kept; that is the
# only step the sprites here take sideways (20 places across the screen).
#
# grey 1 (5) and grey 2 (10) are the same grey, so there are 15 colours, in five brightness
# tiers (LUMA): black; magenta, dark blue, dark green, brown; purple, grey, orange, medium
# blue, green; light blue, pink, yellow, aqua; white.

W, H = 140, 192
DW = 560

BLACK, MAGENTA, DBLUE, PURPLE, DGREEN, GREY1, MBLUE, LBLUE = range(8)
BROWN, ORANGE, GREY2, PINK, GREEN, YELLOW, AQUA, WHITE = range(8, 16)
GREY = GREY1
NAMES = ["black", "magenta", "dark blue", "purple", "dark green", "grey", "medium blue",
         "light blue", "brown", "orange", "grey 2", "pink", "green", "yellow", "aqua", "white"]

# the emulator's flat colours (read from its flat look) and their luma, for the value check
RGB = [(0, 0, 0), (145, 22, 122), (32, 53, 209), (186, 56, 255), (11, 116, 15), (125, 125, 125),
       (30, 168, 219), (159, 174, 255), (96, 75, 0), (229, 85, 35), (125, 125, 125),
       (247, 131, 236), (66, 198, 0), (222, 204, 24), (95, 235, 134), (255, 255, 255)]
LUMA = [round(0.299 * r + 0.587 * g + 0.114 * b) for r, g, b in RGB]
TIER = [0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4]


def row_address(y):
    # offset of row y in a page ($2000-relative)
    return (y & 7) * 0x400 + ((y >> 3) & 7) * 0x80 + (y >> 6) * 0x28


def lit(c, d):
    # is dot d on, for colour c
    return (c >> (d & 3)) & 1


def row_bytes(px_row):
    # one line of 140 colour pixels (None is black) -> 80 bytes in screen order:
    # aux 0, main 0, aux 1, main 1, ...
    dots = []
    for v in px_row:
        v = v or 0
        dots += [lit(v, len(dots) + i) for i in range(4)]
    out = []
    for k in range(80):
        b = 0
        for i in range(7):
            b |= dots[k * 7 + i] << i
        out.append(b)
    return out


def dot_bytes(dots):
    # one line of 560 on/off dots -> 80 bytes in screen order
    return [sum(dots[k * 7 + i] << i for i in range(7)) for k in range(80)]


def to_pages(px, lines=None):
    # 192 rows of 140 colour pixels -> (main, aux), 8 KB each, $2000-relative; lines: rows
    # given as 560 dots instead (the 40-column text, fonts.text40)
    main = bytearray(0x2000)
    aux = bytearray(0x2000)
    for y in range(H):
        base = row_address(y)
        b = dot_bytes(lines[y]) if lines and y in lines else row_bytes(px[y])
        for col in range(40):
            aux[base + col] = b[col * 2]
            main[base + col] = b[col * 2 + 1]
    return bytes(main), bytes(aux)


def from_pages(main, aux):
    # back to colour pixels: the check that the pages hold what was drawn
    out = []
    for y in range(H):
        base = row_address(y)
        bits = []
        for col in range(40):
            for page in (aux, main):
                b = page[base + col]
                bits += [(b >> i) & 1 for i in range(7)]
        out.append([sum(bits[g * 4 + i] << i for i in range(4)) for g in range(W)])
    return out


# ---- sprites
#
# a sprite is a box of the picture cut on the 7-pixel grid: x0 a multiple of 7, width a
# multiple of 7 (so 4 bytes a step: aux, main, aux, main), any top row and height. Stored as
# rows of screen-order bytes (aux and main interleaved, as a line lists them) for the picture
# and the same for the mask (bit set: keep the screen's dot). The game splits each row's even
# bytes to aux and odd ones to main. Bit 7 is never used: masks keep it 0.
#
# a sprite whose every pixel is solid needs no mask (`solid`): it is a straight copy.

class Sprite:
    def __init__(self, name, x0, y0, w, h, pic, mask, solid):
        self.name, self.x0, self.y0, self.w, self.h = name, x0, y0, w, h
        self.pic, self.mask, self.solid = pic, mask, solid

    def bytes_wide(self):
        return self.w // 7 * 4

    def raw(self):
        return bytes(self.pic) + (b"" if self.solid else bytes(self.mask))


def cut(name, px, box, solid=False):
    # px: rows of 140 (None is clear); box: (x0, y0, x1, y1) in pixels, widened to the grid
    x0, y0, x1, y1 = box
    x0 = x0 // 7 * 7
    x1 = -(-x1 // 7) * 7
    w, h = x1 - x0, y1 - y0
    pic, mask = [], []
    for y in range(y0, y1):
        row = px[y][x0:x1]
        dots_pic, dots_mask = [], []
        for i, v in enumerate(row):
            d0 = (x0 + i) * 4
            for k in range(4):
                if v is None:
                    dots_pic.append(0)
                    dots_mask.append(1)
                else:
                    dots_pic.append(lit(v, d0 + k))
                    dots_mask.append(0)
        for k in range(len(dots_pic) // 7):
            pic.append(sum(dots_pic[k * 7 + i] << i for i in range(7)))
            mask.append(sum(dots_mask[k * 7 + i] << i for i in range(7)))
    if solid:
        mask = []
    return Sprite(name, x0, y0, w, h, pic, mask, solid)


def put(px, s, x0=None, y0=None):
    # draw a sprite back onto a 140-wide pixel picture, as the game's blit would (for checks)
    x0 = s.x0 if x0 is None else x0
    y0 = s.y0 if y0 is None else y0
    assert x0 % 7 == 0
    bw = s.bytes_wide()
    for j in range(s.h):
        y = y0 + j
        if not 0 <= y < H:
            continue
        cur = row_bytes(px[y])
        k0 = x0 // 7 * 4
        for k in range(bw):
            if 0 <= k0 + k < 80:
                m = 0 if s.solid else s.mask[j * bw + k]
                cur[k0 + k] = (cur[k0 + k] & m) | s.pic[j * bw + k]
        bits = []
        for b in cur:
            bits += [(b >> i) & 1 for i in range(7)]
        px[y] = [sum(bits[g * 4 + i] << i for i in range(4)) for g in range(W)]


# ---- packing, as a stand-in for the packer Tisple is adding

def packed(data):
    import zlib
    return len(zlib.compress(bytes(data), 9))
