# dice face pictures and the small 5x7 hud glyphs.
#
# a face picture is an opaque tile 3 bytes (21 px) wide and 20 rows tall, drawn into the black
# middle of a die in the tray; one colour family a tile, since a byte holds one palette.
# the hud glyphs are 5x7 dots the game draws 2 px wide, so every stroke is white.

TILE_W, TILE_H = 21, 20

# glyphs added to the font, by the character they replace (the font only goes to 'Z')
GLYPHS = {
    "*": [".#.#.", "#####", "#####", "#####", ".###.", "..#..", "....."],   # heart
    "#": ["#####", "#...#", "#.#.#", "#.#.#", ".#.#.", "..#..", "....."],   # shield
    "!": ["....#", "...##", "..##.", "###..", ".#...", "#.#..", "....."],   # sword
    "%": ["..#..", ".##..", ".###.", "#####", "##.##", "#####", ".###."],   # flame
    "@": [".###.", "#####", "#.#.#", "#####", "#####", "#####", "#.#.#"],   # ghost
    "+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],   # mend
    "$": [".....", "..#..", ".###.", "#####", ".###.", "..#..", "....."],   # diamond
    "&": ["...#.", "..#..", ".#...", "#####", "...#.", "..#..", ".#..."],   # spark
    # the intents an enemy shows over its head (! hit and # shield above), and the pips
    '"': ["#...#", ".#.#.", "..#..", ".#.#.", "##.##", "#...#", "....."],   # hit all: crossed swords
    "<": ["..#..", ".###.", "#####", "..#..", "..#..", "..#..", "....."],   # buff: up arrow
    "=": [".###.", "#.#.#", "#####", "#.#.#", ".###.", ".....", "....."],   # summon: a ringed plus
    ">": ["#....", ".#...", "..#.#", "...##", "..###", ".....", "....."],   # dive: swooping arrow
    ";": ["#####", "#####", "#####", ".###.", "..#..", ".....", "....."],   # ward pip: a solid shield
    "'": ["..#..", "..#..", "#####", ".###.", ".#.#.", ".....", "....."],   # mana pip: a star
    ",": ["#...#", ".#.#.", ".###.", "#####", ".###.", "#.#.#", "....."],   # fleas: a little bug
}


def wand(c, x, y):
    # a white star on a short orange stick
    c.line(x + 2, y + 18, x + 11, y + 9, "O", 3)                 # the stick
    star(c, x + 14, y + 6, 6.5, 2.8, "W")


def star(c, cx, cy, ro, ri, col):
    import math
    pts = []
    for i in range(10):
        r = ro if i % 2 == 0 else ri
        a = -math.pi / 2 + i * math.pi / 5
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    c.poly(pts, col)


def bone(c, x, y):
    # a fat dog bone across the face, knobs at both ends
    c.line(x + 5, y + 14, x + 15, y + 5, "W", 4)
    for kx, ky in ((x + 3, y + 13), (x + 6, y + 17), (x + 14, y + 2), (x + 18, y + 6)):
        c.ellipse(kx, ky, 3, 3, "W")


def kibble(c, x, y):
    # a pet bowl, flared at the foot, heaped with kibble: a white dome flecked with gaps
    c.ellipse(x + 10.5, y + 11, 8, 7, "W")
    for kx, ky in ((x + 7, y + 7), (x + 12, y + 6), (x + 9, y + 9), (x + 14, y + 9), (x + 5, y + 10),
                   (x + 11, y + 5)):
        c.rect(kx, ky, kx + 2, ky + 1, "K")
    c.rect(x + 1, y + 11, x + 20, y + 13, "W")                   # the rim
    c.poly([(x + 3, y + 13), (x + 18, y + 13), (x + 21, y + 20), (x, y + 20)], "V")


def gem(c, x, y):
    # a cut gem: blue, white facets on top
    c.poly([(x + 5, y + 2), (x + 16, y + 2), (x + 21, y + 8), (x + 10, y + 19), (x, y + 8)], "B")
    c.poly([(x + 5, y + 2), (x + 16, y + 2), (x + 21, y + 8), (x, y + 8)], "W")
    c.poly([(x + 7, y + 4), (x + 14, y + 4), (x + 16, y + 7), (x + 5, y + 7)], "B")
    c.line(x + 10, y + 9, x + 10, y + 17, "W", 2)


def book(c, x, y):
    # a closed spell book: violet cover, white pages showing along the side and the bottom
    c.rect(x + 4, y + 3, x + 20, y + 20, "W")                    # the pages
    for py in range(y + 5, y + 19, 3):
        c.rect(x + 18, py, x + 20, py + 1, "K")
    c.rect(x + 1, y, x + 17, y + 17, "V")                        # the cover
    c.rect(x + 1, y, x + 3, y + 17, "W")                         # the spine
    star(c, x + 10, y + 8, 5.5, 2.3, "W")
def curse_ground(c, x, y):
    # every curse is a violet face: one look says this die has gone bad
    c.rect(x, y, x + 21, y + 20, "V")


def fleas(c, x, y):
    # a big flea mid-jump: a black bug with long back legs, white hop lines behind it
    curse_ground(c, x, y)
    c.ellipse(x + 12, y + 9, 6, 4.5, "K")                        # body
    c.ellipse(x + 5, y + 8, 3, 3, "K")                           # head
    c.line(x + 4, y + 8, x + 1, y + 11, "K", 1)                  # snout
    c.line(x + 15, y + 12, x + 19, y + 17, "K", 2)               # jumping legs
    c.line(x + 12, y + 12, x + 13, y + 18, "K", 2)
    c.line(x + 8, y + 12, x + 6, y + 17, "K", 2)
    c.rect(x + 5, y + 7, x + 6, y + 8, "W")                      # eye
    for i, (hx, hy) in enumerate(((x + 17, y + 2), (x + 19, y + 5))):
        c.line(hx - 3, hy, hx, hy + 2, "W", 1)
def wet(c, x, y):
    # a big water drop
    curse_ground(c, x, y)
    c.poly([(x + 10, y + 1), (x + 15, y + 9), (x + 5, y + 9)], "K")
    c.ellipse(x + 10, y + 12, 6, 6, "K")
    c.poly([(x + 10, y + 3), (x + 14, y + 10), (x + 6, y + 10)], "W")
    c.ellipse(x + 10, y + 12, 5, 5, "W")
    c.rect(x + 7, y + 11, x + 9, y + 14, "K")                    # shine


def hiss(c, x, y):
    # an angry cat's head: ears flat back, slit eyes, mouth open on two fangs
    curse_ground(c, x, y)
    c.poly([(x + 1, y + 4), (x + 7, y + 5), (x + 3, y + 10)], "K")       # ears, out to the sides
    c.poly([(x + 20, y + 4), (x + 14, y + 5), (x + 18, y + 10)], "K")
    c.ellipse(x + 10.5, y + 11, 8, 7, "K")
    c.poly([(x + 5, y + 7), (x + 9, y + 9), (x + 5, y + 10)], "W")       # eyes, glaring
    c.poly([(x + 16, y + 7), (x + 12, y + 9), (x + 16, y + 10)], "W")
    c.ellipse(x + 10.5, y + 14, 4, 2.5, "W")                     # the open mouth
    c.ellipse(x + 10.5, y + 14.5, 3, 1.5, "K")
    c.poly([(x + 8, y + 12), (x + 10, y + 12), (x + 9, y + 16)], "W")    # fangs
    c.poly([(x + 11, y + 12), (x + 13, y + 12), (x + 12, y + 16)], "W")
def bath(c, x, y):
    # a bathtub on feet, bubbles over the top
    curse_ground(c, x, y)
    for bx, by, r in ((x + 5, y + 5, 2.5), (x + 11, y + 3, 3), (x + 16, y + 6, 2.5)):
        c.ellipse(bx, by, r, r, "W")
    c.rect(x + 1, y + 9, x + 21, y + 11, "K")
    c.poly([(x + 2, y + 10), (x + 20, y + 10), (x + 17, y + 17), (x + 5, y + 17)], "W")
    c.rect(x + 5, y + 17, x + 7, y + 20, "W")                    # feet
    c.rect(x + 15, y + 17, x + 17, y + 20, "W")


def lint(c, x, y):
    # a grey ball of fluff with stray hairs
    c.grey(x + 3, y + 4, x + 19, y + 18,
           lambda px, py: ((px - x - 11) / 7) ** 2 + ((py - y - 11) / 6) ** 2 <= 1)
    c.line(x + 4, y + 6, x + 1, y + 2, "W", 1)
    c.line(x + 17, y + 6, x + 20, y + 3, "W", 1)
    c.line(x + 18, y + 14, x + 21, y + 17, "W", 1)
    c.line(x + 3, y + 15, x, y + 18, "W", 1)


def plus_one(c, x, y):
    # +1 in bold white strokes
    c.rect(x + 1, y + 9, x + 10, y + 12, "W")                    # +
    c.rect(x + 4, y + 6, x + 7, y + 15, "W")
    c.rect(x + 15, y + 3, x + 18, y + 18, "W")                   # 1
    c.rect(x + 12, y + 5, x + 15, y + 7, "W")
    c.rect(x + 12, y + 16, x + 21, y + 18, "W")


def times_two(c, x, y):
    # x2 in bold white strokes
    c.line(x + 1, y + 7, x + 7, y + 15, "W", 3)                  # x
    c.line(x + 7, y + 7, x + 1, y + 15, "W", 3)
    c.rect(x + 11, y + 3, x + 20, y + 6, "W")                    # 2
    c.rect(x + 18, y + 3, x + 21, y + 11, "W")
    c.rect(x + 11, y + 9, x + 21, y + 12, "W")
    c.rect(x + 11, y + 9, x + 14, y + 18, "W")
    c.rect(x + 11, y + 15, x + 21, y + 18, "W")


def fang(c, x, y):
    c.ellipse(x + 10, y + 7, 9, 6, "W")                           # an open jaw from the front
    c.ellipse(x + 10, y + 9, 7, 5, "K")
    for tx in (x + 4, x + 14):                                    # two fangs
        c.poly([(tx, y + 7), (tx + 4, y + 7), (tx + 2, y + 15)], "W")
    c.rect(x + 8, y + 15, x + 13, y + 17, "W")                    # bottom teeth
    c.rect(x + 2, y + 17, x + 19, y + 19, "W")


def leaf(c, x, y):
    c.poly([(x + 10, y + 1), (x + 19, y + 5), (x + 17, y + 14), (x + 10, y + 19), (x + 3, y + 14),
            (x + 1, y + 5)], "G")                                 # a leaf shield
    c.line(x + 10, y + 3, x + 10, y + 17, "W", 2)                 # its vein
    c.line(x + 10, y + 9, x + 5, y + 6, "W", 2)
    c.line(x + 10, y + 9, x + 15, y + 6, "W", 2)


def heart(c, x, y):
    c.ellipse(x + 6, y + 6, 5, 5, "V")
    c.ellipse(x + 14, y + 6, 5, 5, "V")
    c.poly([(x + 1, y + 7), (x + 19, y + 7), (x + 10, y + 18)], "V")
    c.ellipse(x + 6, y + 5, 2, 2, "W")                            # shine


def candle(c, x, y):
    c.rect(x + 6, y + 10, x + 14, y + 20, "W")                    # the candle
    c.rect(x + 5, y + 18, x + 16, y + 20, "W")
    c.poly([(x + 10, y), (x + 15, y + 6), (x + 12, y + 9), (x + 8, y + 9), (x + 5, y + 6)], "O")
    c.rect(x + 9, y + 5, x + 11, y + 8, "W")                      # hot middle


def ghost(c, x, y):
    c.ellipse(x + 10, y + 7, 7, 7, "W")
    c.rect(x + 3, y + 7, x + 18, y + 17, "W")
    for i in range(4):                                            # the ragged hem
        c.rect(x + 3 + i * 4, y + 17, x + 5 + i * 4, y + 19, "W")
    c.rect(x + 6, y + 5, x + 8, y + 9, "K")                       # eyes
    c.rect(x + 12, y + 5, x + 14, y + 9, "K")
    c.ellipse(x + 10, y + 13, 2, 2, "K")                          # boo


def puff(c, x, y):
    for dx, dy, r in ((5, 13, 4), (11, 9, 5), (16, 14, 4), (9, 4, 3)):
        c.grey(x + dx - r, y + dy - r, x + dx + r + 1, y + dy + r + 1,
               lambda px, py, ax=x + dx, ay=y + dy, rr=r: ((px - ax) / rr) ** 2 + ((py - ay) / rr) ** 2 <= 1)


# in the order of the art module's TILE_ constants: the item faces, then the curses, then the
# math faces
TILES = [("WAND", wand), ("BONE", bone), ("KIBBLE", kibble), ("GEM", gem), ("BOOK", book),
         ("LINT", lint), ("FLEAS", fleas), ("WET", wet), ("HISS", hiss), ("BATH", bath),
         ("PLUS1", plus_one), ("TIMES2", times_two)]

# the witch dog's faces, still named by the dice in content/: drop them once nothing does
OLD_TILES = [("FANG", fang), ("LEAF", leaf), ("HEART", heart), ("CANDLE", candle),
             ("GHOST", ghost), ("PUFF", puff)]
