# the two disks as track strips: (track, sector) -> kind

from layout import SPACES, hexa

def disk_cells(m, b, table):
    # disk 1: (track, sector) -> kind, and the spans to name
    cells = {}
    spans = []
    for s in range(16):
        cells[(0, s)] = "tisple" if s < 3 else "unused"
    spans.append((0, 0, "boot loader"))
    mem_of = {0: "main", 1: "card", 2: "aux", 3: "bank1"}
    track = 1
    for first, pages, bank in table:
        t0 = track
        for k in range(pages):
            if k > 0 and k % 16 == 0:
                track += 1
                if track == 17:
                    track = 18
            addr = (first << 8) + k * 256
            space = m.space_for("aux" if bank == 2 else "main", addr, bank == 3)
            cells[(track, k % 16)] = page_kind(m, space, addr)
        for s in range(pages % 16 or 16, 16):
            cells[(track, s)] = "unused"
        spans.append((t0, track, "%s %s, %d pages" % (mem_of[bank], hexa(first << 8), pages)))
        track += 1
        if track == 17:
            track = 18
    last = track - 1
    for s in range(16):
        cells[(17, s)] = "hw"
    spans.append((17, 17, "DOS catalog"))
    tabs = [t for t in b.tables if t[0] == 1]
    t_first = min(t[1] for t in tabs) if tabs else 35
    k = 0
    for t in tabs:
        for _ in range(t[5]):
            cells[(t_first + k // 16, k % 16)] = table_kind(t[3])
            k += 1
    for tr in range(t_first, 35):
        for s in range(16):
            cells.setdefault((tr, s), "unused")
    if tabs:
        spans.append((t_first, 34, "%d tables (the title's)" % len(tabs)))
    for tr in range(35):
        for s in range(16):
            cells.setdefault((tr, s), "free")
    return cells, spans, last


SLOT_ORDER = [0, 2, 4, 6, 8, 10, 12, 14, 1, 3, 5, 7, 9, 11, 13, 15]


def disk2_cells(b):
    # disk 2: tables in declaration order from track 1, every other sector round a track
    cells = {(0, s): ("tisple" if s == 0 else "unused") for s in range(16)}
    spans = [(0, 0, "boot sector")]
    slot = 0
    problems = []
    names = [t for t in b.tables if t[0] == 2]
    for t in names:
        t0 = 1 + slot // 16
        for _ in range(t[5]):
            cells[(1 + slot // 16, SLOT_ORDER[slot % 16])] = table_kind(t[3])
            slot += 1
        t1 = 1 + (slot - 1) // 16
        if (t0, t1) != (t[1], t[2]):
            problems.append("%s: tracks %d-%d by the slots, %d-%d by the build" % (
                t[3], t0, t1, t[1], t[2]))
    for tr in range(35):
        for s in range(16):
            cells.setdefault((tr, s), "free")
    return cells, spans, slot, problems


def table_kind(name):
    if "overlay group" in name:
        return "code"
    if name.startswith("art/"):
        return "art"
    if name.startswith("sound/"):
        return "sound"
    return "tables"


def page_kind(m, space, addr):
    counts = {}
    base = SPACES[space][1]
    for a in range(addr, addr + 256):
        if a - base >= SPACES[space][2]:
            break
        it = m.owner[space][a - base]
        k = it.kind if it else "unused"
        if k == "free" or (it and it.kind == "screens"):
            k = "unused"
        if it and it.name in ("draw/blit.sprite_aux", "content/items.records", "disk.work",
                              "unpack.home_aux", "dhgr.home_aux"):
            k = "unused"  # lets with no value: zeros on the disk
        counts[k] = counts.get(k, 0) + 1
    return max(counts, key=lambda c: counts[c])


