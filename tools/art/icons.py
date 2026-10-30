# dice face pictures and the small 5x7 hud glyphs.
#
# a face picture is an opaque tile 3 bytes (21 px) wide and 20 rows tall, drawn into the black
# middle of a die in the tray; one colour family a tile, since a byte holds one palette.
# the hud glyphs are 5x7 dots the game draws 2 px wide, so every stroke is white.

TILE_W, TILE_H = 21, 20

# glyphs added to the font, by the character they replace (the font only goes to 'Z')
GLYPHS = {
    "*": [".#.#.", "#####", "#####", "#####", ".###.", "..#..", "....."],   # heart
    "#": ["#####", "#####", "#####", "#####", ".###.", "..#..", "....."],   # shield
    "!": ["....#", "...##", "..##.", "###..", ".#...", "#.#..", "....."],   # sword
    "%": ["..#..", ".##..", ".###.", "#####", "##.##", "#####", ".###."],   # flame
    "@": [".###.", "#####", "#.#.#", "#####", "#####", "#####", "#.#.#"],   # ghost
    "+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],   # mend
    "$": [".....", "..#..", ".###.", "#####", ".###.", "..#..", "....."],   # diamond
    "&": ["...#.", "..#..", ".#...", "#####", "...#.", "..#..", ".#..."],   # spark
}


def wand(c, x, y):
    c.line(x + 3, y + 18, x + 14, y + 6, "O", 3)                  # the stick
    c.ellipse(x + 16, y + 4, 3, 3, "W")                           # the glowing tip
    c.rect(x + 11, y + 1, x + 13, y + 2, "W")
    c.rect(x + 19, y + 7, x + 21, y + 8, "W")
    c.rect(x + 19, y + 1, x + 21, y + 2, "W")


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


# in the order of the art module's TILE_ constants
TILES = [("WAND", wand), ("FANG", fang), ("LEAF", leaf), ("HEART", heart), ("CANDLE", candle),
         ("GHOST", ghost), ("PUFF", puff)]
