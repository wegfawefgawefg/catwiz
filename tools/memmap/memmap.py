# Catwiz's memory map, drawn from a build: docs/memory-map.png (every memory space and both
# disks), docs/memory-map-low.png (main and aux memory's $0000-$1FFF byte by byte, zero page
# and the stack page as grids) and build/memmap.txt (every region and free hole as text, to
# compare before and after a memory pass). docs/memory-map.md is the audit written from them.
#
# run: python3 tools/memmap/memmap.py            builds first (tisple build --asm --tables with
#                                                TISPLE_DATA_NOTES=1; its output kept in build/asm.txt)
#      python3 tools/memmap/memmap.py --no-build  draws from build/asm.txt as it is
#
# Where the numbers come from, so nothing is typed in twice:
#   build/asm.txt            the build's summary (segments, overlay groups, disks), the listing
#                            (every function's address and bytes), the data notes (every let and
#                            const table: bytes, address, memory) and the disk tables (--tables)
#   build/catwiz.vars.json   which of those are lets (variables); the rest are const tables
#   build/catwiz.dsk         the boot loader's segment table (the segments as the disk loads them)
#   art/dhgr/memory.txt      each fight's sprites in the aux language card and sprite_aux
#                            (python3 tools/dhgr/make.py memory)
#   game/ and Tisple's lib/  a few pointers the layout cannot see (aux memory's text page
#                            buffers, the guard's home), read from their source
# Typed in here: only the machine's own regions (I/O, ROM, the stack, the screen holes, the
# vectors, the boot loader's pages).


import argparse
import json
import os
import sys

from build_out import ASM, OUT_LOW, OUT_PNG, OUT_TXT, ROOT, VARS, Build, build, find_loader_table
from build_out import loader_segments, sprite_room
from disks import disk2_cells, disk_cells
from layout import COLOUR, SPACES, USABLE, Map, hexa, span
from pictures import low_memory, overview


def report(m, b, table, fights, disk1, disk2):
    out = []
    say = out.append
    say("Catwiz memory map, from build/asm.txt (%s)" % ", ".join(b.disk_lines[:1]))
    for n in b.notes:
        say("note: " + n[:160] + ("..." if len(n) > 160 else ""))
    say("")
    for space in ("main", "lc", "lc1", "aux", "alc", "alc1"):
        t = m.totals(space)
        lo, hi = USABLE[space]
        holes = m.holes(space)
        say("%s %s: %s" % (SPACES[space][0], span(lo, hi), ", ".join(
            "%s %d" % (k, t[k]) for k in COLOUR if t[k])))
        say("  free %d bytes in %d holes: %s" % (sum(b2 - a for a, b2 in holes), len(holes), ", ".join(
            "%s (%d)" % (span(a, b2), b2 - a) for a, b2 in holes)))
    say("")
    say("zero page: the build says %d bytes used (frames %d)" % (b.zp_used, b.zp_frames))
    zp_free = [a for a in range(0x100) if m.at("main", a) is None or m.at("main", a).kind == "free"]
    say("  bytes no let and no listing line names: %d: %s" % (len(zp_free), " ".join(
        "$%02X" % a for a in zp_free)))
    say("")
    say("segments the boot disk loads (the loader's table):")
    for first, pages, bank in table:
        say("  %s %s, %d pages" % ({0: "main", 1: "card", 2: "aux", 3: "bank 1"}[bank],
                                   hexa(first << 8), pages))
    say("  %d segments, %d pages, %d tracks; disk 1 ends its program at track %d" % (
        len(table), sum(p for _, p, _ in table), sum((p + 15) // 16 for _, p, _ in table), disk1))
    say("disk 2: %d slots (sectors) used of 544" % disk2[0])
    for p in disk2[1]:
        say("  check: " + p)
    say("")
    say("overlay groups (region %s, %d bytes):" % (hexa(b.region[0]), b.region[1]))
    for k, g in enumerate(b.groups):
        say("  %d %s: %d bytes, %d functions, from %s%s, %.1f frames a load" % (
            k, g["roots"], g["bytes"], g["functions"], g["from"],
            " at " + hexa(g["aux_at"]) if g["aux_at"] else "", g["frames"]))
    say("")
    say("sprite room by fight (art/dhgr/memory.txt):")
    for f in fights:
        say("  fight %d %s: bank 2 %d of %d, bank 1 %d of %d, sprite_aux %d of %d, %d spare" % (
            f["fight"], f["zone"], f["bank2"], f["bank2_room"], f["bank1"], f["bank1_room"],
            f["aux"], f["aux_room"], f["spare"]))
    say("")
    say("every item, by space and address:")
    for space in SPACES:
        seen = set()
        for it in sorted((i for i in m.items if i.space == space), key=lambda i: (i.start, -i.size)):
            if id(it) in seen:
                continue
            seen.add(id(it))
            say("  %-5s %-11s %6d %-7s %s" % (space, span(it.start, it.end), it.size, it.kind,
                                               it.name))
    return "\n".join(out) + "\n"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--no-build", action="store_true", help="draw from build/asm.txt as it is")
    args = p.parse_args()
    if not args.no_build:
        build()
    b = Build(open(ASM).read().splitlines())
    lets = set(json.load(open(VARS))["vars"])
    lets |= {n.split(".")[0] + "." + n.split(".")[1] for n in lets if n.count(".") >= 2}
    m = Map(b, lets)
    m.fill()
    # the loader's table, found by the first aux segment the build lists
    aux = [s for s in b.segments if s[0] == "aux"]
    first = (aux[0][1] >> 8, (aux[0][1] + aux[0][2] - (aux[0][1] & 0xFF00) + 255) // 256, 2)
    table = find_loader_table(loader_segments(), first)
    fights = sprite_room()
    cells1, spans1, last1 = disk_cells(m, b, table)
    cells2, spans2, slots2, problems = disk2_cells(b)
    text = report(m, b, table, fights, last1, (slots2, problems))
    open(OUT_TXT, "w").write(text)
    overview(m, b, fights, cells1, spans1, cells2).save(OUT_PNG, optimize=True)
    low_memory(m, b).save(OUT_LOW, optimize=True)
    print(text.split("\nevery item")[0])
    print("wrote %s, %s, %s" % (os.path.relpath(OUT_PNG, ROOT), os.path.relpath(OUT_LOW, ROOT),
                                os.path.relpath(OUT_TXT, ROOT)))


if __name__ == "__main__":
    main()

