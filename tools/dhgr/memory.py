# the memory each fight's sprites need while it runs, as the game places them, written to
# art/dhgr/memory.txt and printed (python3 tools/dhgr/make.py memory).
#
# A fight unpacks its kinds' runs (game.py's sprites: the cat, the small ones, its enemies) as
# game/draw/blit.tsp unpack_all does: every kind's main half into the aux language card (bank
# 2's 12,272 bytes at $D000-$FFEF, else bank 1's 4,096), then every aux half into bank 1 first,
# then bank 2, then blit.sprite_aux (10,752 bytes of aux memory). Keep the capacities and the
# order in step with blit.tsp. "before" is the masked frames of the build before the midnight
# decision (day light, no flash frames), "after" the solid night frames and the flash ones.
#
# The packed column is zlib -9, a stand-in for Tisple's packer (the build's own sizes are in
# its output): the store in aux memory, the runs and the backdrops.
#
# The art/dhgr/*.bin tables are the 2026-10-30 planning round's (day sprites, materials,
# screens): nothing writes or reads them now.

import os
import zlib

import dhgr
import forest
import game
import game_sprites as gs
import light
import night
import screen

BANK2 = 0xFFF0 - 0xD000
BANK1 = 0xE000 - 0xD000
SPRITE_AUX = 10752


def packed(data):
    return len(zlib.compress(bytes(data), 9))


def kinds_after():
    # {kind: (aux bytes, main bytes)} as game.py writes them
    out = {}
    for kind, sprites, _ in game.all_sprites():
        out[kind] = (b"".join(s.aux for s in sprites), b"".join(s.main for s in sprites))
    return out


def kinds_before():
    # the masked day frames, no flash: what the build carried before
    out = {}
    for kind in gs.KINDS:
        if kind == "misc":
            sprites = gs.misc()
        else:
            sprites = [gs.Sprite(f, light.lit(screen.figure(kind, f), "day")) for f in gs.frames(kind)]
        out[kind] = (b"".join(s.aux for s in sprites), b"".join(s.main for s in sprites))
    return out


def place(kinds, sizes):
    # blit.tsp unpack_all: where each half goes. Returns (lines, bank 2 used, bank 1 used,
    # sprite_aux used, bytes short)
    used2 = used1 = used_aux = short = 0
    lines = []
    for k in kinds:
        n = len(sizes[k][1])
        fits2, fits1 = n <= BANK2 - used2, n <= BANK1 - used1
        if fits1 and not fits2:
            used1 += n
            lines.append("%s main %d: bank 1" % (k, n))
        elif fits2:
            used2 += n
            lines.append("%s main %d: bank 2" % (k, n))
        else:
            short += n
            lines.append("%s main %d: fits nowhere (the game gives up on it)" % (k, n))
    for k in kinds:
        n = len(sizes[k][0])
        if n <= BANK1 - used1:
            used1 += n
            lines.append("%s aux %d: bank 1" % (k, n))
        elif n <= BANK2 - used2:
            used2 += n
            lines.append("%s aux %d: bank 2" % (k, n))
        else:
            used_aux += n
            lines.append("%s aux %d: sprite_aux%s" % (k, n, "" if used_aux <= SPRITE_AUX else ", past its end"))
    short += max(0, used_aux - SPRITE_AUX)
    return lines, used2, used1, used_aux, short


def fight_kinds(F):
    return ["cat", "misc"] + [k for i, k in enumerate(F["foes"]) if k not in F["foes"][:i]]


def run(art):
    out = []
    say = out.append
    before, after = kinds_before(), kinds_after()
    room = BANK2 + BANK1 + SPRITE_AUX
    say("Catwiz double hi-res: the sprites' memory per fight (python3 tools/dhgr/make.py memory)")
    say("before: masked day frames, no flash (the build before 2026-10-31); after: solid night")
    say("frames and a flash frame a fighter kind. Room: the aux language card's bank 2 %d and" % BANK2)
    say("bank 1 %d, then sprite_aux %d (game/draw/blit.tsp): %d in all." % (BANK1, SPRITE_AUX, room))
    say("")
    say("%-10s %15s %15s %8s   %s" % ("kind", "before aux+main", "after aux+main", "growth", "zlib before -> after"))
    for k in gs.KINDS:
        b, a = before[k], after[k]
        nb, na = len(b[0]) + len(b[1]), len(a[0]) + len(a[1])
        say("%-10s %7d+%-7d %7d+%-7d %+8d   %d -> %d" % (k, len(b[0]), len(b[1]), len(a[0]), len(a[1]), na - nb,
                                                      packed(b[0] + b[1]), packed(a[0] + a[1])))
    for kind, sprites, _ in game.all_sprites():
        for s in sprites:
            if s.name.endswith("_flash"):
                say("%-10s of it the flash frame: %d" % (kind, len(s.aux) + len(s.main)))
    say("")
    for F in game.FIGHTS:
        kinds = fight_kinds(F)
        say("fight %d (%s): %s" % (F["n"], F["variant"], ", ".join(kinds)))
        for label, sizes in (("before", before), ("after", after)):
            total = sum(len(sizes[k][0]) + len(sizes[k][1]) for k in kinds)
            lines, u2, u1, ua, short = place(kinds, sizes)
            say("  %-6s %6d bytes: bank 2 %d of %d, bank 1 %d of %d, sprite_aux %d of %d: %s" % (
                label, total, u2, BANK2, u1, BANK1, ua, SPRITE_AUX,
                "%d SHORT" % short if short else "%d to spare" % (room - total)))
            if label == "after":
                for line in lines:
                    say("           " + line)
        dm, da = dhgr.to_pages(forest.picture(F["P"], F["variant"]).px)
        nm, na = dhgr.to_pages(night.picture(F["variant"]).px)
        say("  backdrop, zlib: day %d, night %d" % (packed(dm) + packed(da), packed(nm) + packed(na)))
        say("")
    text = "\n".join(out) + "\n"
    with open(os.path.join(art, "memory.txt"), "w") as f:
        f.write(text)
    print(text)
