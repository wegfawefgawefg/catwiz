# the memory each fight screen's sprites need while it runs, as the game places them, written
# to art/dhgr/memory.txt and printed (python3 tools/dhgr/make.py memory).
#
# game/draw/blit.tsp places the runs of a screen's blocks: the hero's and the small sprites'
# first (blocks 0 and 1, read once from the second disk and kept while fights follow), then
# the screen's enemies' blocks; each time every main half into the aux language card (bank 2's
# 12,272 bytes at $D000-$FFEF, else bank 1's 4,096), then every aux half into bank 1 first,
# then bank 2, then blit.sprite_aux (10,688 bytes of aux memory; the hero's aux halves straight there). The fight's picture is read
# into what sprite_aux has after the hero's halves, before the enemies' runs go there: it must
# fit. Keep the capacities and the order in step with blit.tsp.
#
# The packed column is zlib -9, a stand-in for Tisple's packer (the build's own sizes are in
# tisple build --tables).

import os
import zlib

import dhgr
import game

BANK2 = 0xFFF0 - 0xD000
BANK1 = 0xE000 - 0xD000
SPRITE_AUX = 10688


def packed(data):
    return len(zlib.compress(bytes(data), 9))


class Room:
    def __init__(self):
        self.used2 = self.used1 = self.aux = self.short = 0
        self.lines = []

    def place(self, blocks, aux_home=False):
        # blit.tsp place_blocks: the main halves, then the aux halves (aux_home: those straight
        # to sprite_aux, as the hero's)
        halves = {b: game.runs_halves(game.sprites_of(b)) for b in blocks}
        for b in blocks:
            n = len(halves[b][1])
            fits2, fits1 = n <= BANK2 - self.used2, n <= BANK1 - self.used1
            if fits1 and not fits2:
                self.used1 += n
                self.lines.append("%s main %d: bank 1" % (b, n))
            elif fits2:
                self.used2 += n
                self.lines.append("%s main %d: bank 2" % (b, n))
            else:
                self.short += n
                self.lines.append("%s main %d: fits nowhere (the game gives up on it)" % (b, n))
        for b in blocks:
            n = len(halves[b][0])
            if aux_home:
                self.aux += n
                self.lines.append("%s aux %d: sprite_aux" % (b, n))
            elif n <= BANK1 - self.used1:
                self.used1 += n
                self.lines.append("%s aux %d: bank 1" % (b, n))
            elif n <= BANK2 - self.used2:
                self.used2 += n
                self.lines.append("%s aux %d: bank 2" % (b, n))
            else:
                self.aux += n
                self.lines.append("%s aux %d: sprite_aux%s" % (b, n, "" if self.aux <= SPRITE_AUX else ", past its end"))
        if self.aux > SPRITE_AUX:
            self.short += self.aux - SPRITE_AUX


def short_of(blocks):
    # the bytes a screen of these enemy blocks (after the hero's) would be short
    r = Room()
    r.place(game.HERO_BLOCKS, True)
    r.place(blocks)
    return r.short


def block_size(b):
    a, m = game.runs_halves(game.sprites_of(b))
    return len(a), len(m)


def run(art):
    out = []
    say = out.append
    room = BANK2 + BANK1 + SPRITE_AUX
    say("Catwiz double hi-res: each fight screen's sprites in memory (python3 tools/dhgr/make.py memory)")
    say("Room: the aux language card's bank 2 %d and bank 1 %d, then sprite_aux %d (game/draw/" % (BANK2, BANK1, SPRITE_AUX))
    say("blit.tsp): %d in all. The hero's and the small sprites' blocks stay; each screen's enemies'" % room)
    say("blocks go after them.")
    say("")
    fights, fight_screens = game.all_screens()
    blocks = []
    for S in fight_screens:
        for b in S.blocks:
            if b not in blocks:
                blocks.append(b)
    say("%-12s %13s %8s %8s   %s" % ("block", "aux+main", "sprites", "zlib", "of it the flash"))
    for b in blocks:
        sprites = game.sprites_of(b)
        a, m = block_size(b)
        fl = [s for s in sprites if s.name.endswith("_flash")]
        say("%-12s %6d+%-6d %8d %8d   %s" % (b, a, m, len(sprites), packed(b"".join(s.aux + s.main for s in sprites)),
                                         len(fl[0].aux) + len(fl[0].main) if fl else "-"))
    say("")
    hero = Room()
    hero.place(game.HERO_BLOCKS, True)
    sizes = game.table_sizes(fight_screens + [game.title_screen()])
    say("the screen's tables (art/sprites tab, main memory): %d sprites, %d kinds, %d blocks at most" % sizes)
    say("the hero's blocks: bank 2 %d, bank 1 %d, sprite_aux %d" % (hero.used2, hero.used1, hero.aux))
    say("")
    worst = 0
    for F, S in zip(fights, fight_screens):
        r = Room()
        r.used2, r.used1, r.aux = hero.used2, hero.used1, hero.aux
        tail = SPRITE_AUX - hero.aux
        r.place(S.blocks[2:])
        total = sum(sum(block_size(b)) for b in S.blocks)
        pm, pa = dhgr.to_pages(game.fight_picture(F).px)
        pic = packed(pm) + packed(pa)
        say("fight %d (%s): %s" % (F["n"], F["zone"], ", ".join(S.blocks)))
        say("  %6d bytes: bank 2 %d of %d, bank 1 %d of %d, sprite_aux %d of %d: %s" % (
            total, r.used2, BANK2, r.used1, BANK1, r.aux, SPRITE_AUX,
            "%d SHORT" % r.short if r.short else "%d to spare" % (room - total)))
        say("  the picture, zlib %d, into sprite_aux's %d after the hero's%s" % (
            pic, tail, "" if pic + 200 <= tail else ": TOO BIG"))
        for line in r.lines:
            say("           " + line)
        if r.short or pic + 200 > tail:
            worst += 1
        say("")
    text = "\n".join(out) + "\n"
    with open(os.path.join(art, "memory.txt"), "w") as f:
        f.write(text)
    print(text)
    if worst:
        raise SystemExit("memory.py: %d screens do not fit" % worst)
