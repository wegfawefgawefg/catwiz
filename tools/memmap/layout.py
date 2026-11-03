# the byte map: every byte of every memory space owned by at most one item, each item a kind
# (code, tables, ...), and the runs and holes the pictures and the report are made of

from build_out import aux_card_end, aux_text_buffers, guard_home

# ---- kinds and their colours

KINDS = [
    ("code", "code", (66, 120, 230)),
    ("tables", "constant tables and text", (40, 170, 150)),
    ("vars", "variables, scratch and buffers", (236, 140, 60)),
    ("art", "art (sprite room, fonts, card shapes)", (160, 95, 215)),
    ("sound", "sound (songs, effects, the player)", (225, 80, 140)),
    ("screens", "screens (double hi-res pages)", (88, 104, 130)),
    ("tisple", "Tisple machinery (stubs, reader, unpacker, guard)", (150, 112, 62)),
    ("hw", "hardware, ROM, stack, vectors", (128, 128, 128)),
    ("unused", "reserved but unused, or loaded zeros", (205, 205, 205)),
    ("free", "free", (255, 236, 40)),
]
COLOUR = {k: c for k, _, c in KINDS}
KIND_NAME = {k: n for k, n, _ in KINDS}

# ---- spaces: (name, first address, bytes)

SPACES = {
    "main": ("main memory", 0x0000, 0x10000),
    "lc": ("language card bank 2 and $E000-$FFFF", 0xD000, 0x3000),
    "lc1": ("language card bank 1", 0xD000, 0x1000),
    "aux": ("aux memory", 0x0000, 0x10000),
    "alc": ("aux card bank 2 and $E000-$FFFF", 0xD000, 0x3000),
    "alc1": ("aux card bank 1", 0xD000, 0x1000),
}
# the RAM a program may use in each, for the totals (the rest is the machine's)
USABLE = {
    "main": (0x0000, 0xC000),
    "aux": (0x0000, 0xC000),
    "lc": (0xD000, 0x10000),
    "lc1": (0xD000, 0xE000),
    "alc": (0xD000, 0x10000),
    "alc1": (0xD000, 0xE000),
}


def hexa(a):
    return "$%04X" % a


def span(a, b):
    # a range [a, b) as $A-$B
    return "%s-%s" % (hexa(a), hexa(b - 1)) if b - a > 1 else hexa(a)


def nbytes(n):
    return "{:,} B".format(n)


# ---- the map: every byte of every space owned by at most one item

class Item:
    def __init__(self, space, start, size, name, kind, note=""):
        self.space, self.start, self.size, self.name, self.kind, self.note = (
            space, start, size, name, kind, note)

    @property
    def end(self):
        return self.start + self.size


def module_of(name):
    if " " in name:
        return name
    if name.startswith("str#a"):
        return "aux strings"
    if name.startswith("str#"):
        return "strings"
    head = name.split(".")[0]
    return head


def data_kind(name, size, is_let):
    module = name.split(".")[0]
    top = module.split("/")[0]
    if name.startswith("dhgr.page"):
        return "screens"
    if name in ("disk.work", "disk.reader", "unpack.code", "unpack.home_aux", "auxcard.code",
                "dhgr.kit", "dhgr.home_aux", "auxmem.home_main", "auxmem.home_aux",
                "auxmem.GUARD"):
        return "tisple"
    if name == "draw/blit.sprite_aux" or top == "art":
        return "art"
    if top == "sound" or module.startswith("mockingboard"):
        return "sound"
    if is_let:
        return "vars"
    return "tables"


TISPLE_CODE = ("startup", "bank stubs", "interrupt entry", "overlay stubs", "overlay copy",
               "zero-page image", "runtime")


def code_kind(name):
    if name in TISPLE_CODE or name.startswith("dispatch") or name.endswith(".indirect"):
        return "tisple"
    return "code"


class Map:
    def __init__(self, b, lets):
        self.b = b
        self.owner = {s: [None] * SPACES[s][2] for s in SPACES}
        self.items = []
        self.lets = lets
        self.dups = []

    def space_for(self, mem, addr, bank1=False):
        if mem == "aux":
            return "aux" if addr < 0xD000 else ("alc1" if bank1 else "alc")
        if addr < 0xD000:
            return "main"
        return "lc1" if bank1 else "lc"

    def put(self, space, start, size, name, kind, note="", over=True):
        item = Item(space, start, size, name, kind, note)
        base = SPACES[space][1]
        own = self.owner[space]
        for a in range(start, start + size):
            i = a - base
            if 0 <= i < len(own) and (over or own[i] is None):
                own[i] = item
        self.items.append(item)
        return item

    def at(self, space, addr):
        return self.owner[space][addr - SPACES[space][1]]

    def fill(self):
        b = self.b
        # the machine's own, under everything
        self.put("main", 0x0000, 0x100, "zero page", "free")
        low = [a + n for name, a, n, mem in self.b.data if mem == "main" and 0x100 <= a < 0x200]
        top = max(low) if low else 0x100
        self.put("main", top, 0x200 - top, "6502 stack", "hw")
        self.put("main", 0x03F0, 0x10, "vectors (BRK, reset, IRQ)", "hw")
        for row in range(8):  # text page 1's screen holes: the cards' firmware scratch
            self.put("main", 0x0478 + row * 0x80, 8, "screen holes (slot scratch)", "hw")
        self.put("main", 0xC000, 0x100, "I/O soft switches", "hw")
        self.put("main", 0xC100, 0xF00, "slot ROMs and $C800 space", "hw")
        self.put("main", 0xD000, 0x3000, "ROM (the card's RAM is in instead)", "hw")
        self.put("lc", 0xFFFA, 6, "6502 vectors (NMI, reset, IRQ)", "hw")
        self.put("aux", 0x0000, 0x200, "aux zero page and stack (ALTZP)", "hw")
        self.put("aux", 0xC000, 0x1000, "I/O (same as main)", "hw")
        self.put("aux", 0xD000, 0x3000, "aux language card (drawn apart)", "hw")
        end = aux_card_end()
        self.put("alc", end, 0x10000 - end, "vectors", "hw")
        for s in ("alc", "alc1"):
            top = 0xE000 if s == "alc1" else end
            self.put(s, SPACES[s][1], top - SPACES[s][1], "sprite room (per fight)", "art",
                     over=False)
        for at, size, name in aux_text_buffers():
            self.put("aux", at, size, name, "vars")
        # code
        region = b.region
        for name, addr, size, place in b.code:
            if place.startswith("group"):
                continue
            space = self.space_for("main", addr, place == "bank1")
            self.put(space, addr, size, name, code_kind(name))
        if region:
            self.put(self.space_for("main", region[0]), region[0], region[1],
                     "overlay region (one group at a time)", "code")
            self.put(self.space_for("main", region[0] + region[1]), region[0] + region[1],
                     b.frames_memory, "frames in memory", "vars")
        for k, g in enumerate(b.groups):
            if g["aux_at"] is not None:
                self.put("aux", g["aux_at"], g["bytes"], "overlay image %d: %s" % (
                    k, g["roots"].split(", ")[0]), "code")
        # data
        for name, addr, size, mem in b.data:
            space = self.space_for(mem, addr)
            kind = data_kind(name, size, name in self.lets)
            self.put(space, addr, size, name, kind)
        # zero page, byte by byte: globals from the data notes, frames from the listing
        named = {}
        for name, addr, size, mem in b.data:
            if mem == "main" and addr < 0x100:
                for a in range(addr, addr + size):
                    named[a] = name
        for a, names in b.listing_zp.items():
            if a in named:
                continue
            names = sorted(n for n in names if n)
            if not names or names[0] in ("scratch",) or names[0].startswith("rt_"):
                self.put("main", a, 1, "runtime scratch " + (names[0] if names else "(ROM's A)"),
                         "tisple")
            else:
                self.put("main", a, 1, "frames: " + ", ".join(names[:3]), "vars")
        # the guard's home in aux page 3 is a page, of which the guard's copy is the part from
        # GUARD_HOME
        home = guard_home()
        for it in list(self.items):
            if it.name == "auxmem.home_aux":
                self.put("aux", it.start, home - it.start, "auxmem.home_aux below the guard",
                         "unused")
        # main memory's code that with_aux runs is copied to the same addresses in aux memory:
        # a function whose bytes in an aux segment no let or image takes
        for mem, addr, size in b.segments:
            if mem != "aux":
                continue
            run = None
            for name, at, n, place in sorted(b.code, key=lambda c: c[1]):
                if place != "main" or at < addr or at + n > addr + size:
                    continue
                if any(self.at("aux", a) is not None for a in range(at, at + n)):
                    continue
                if run is not None and run.end == at:
                    run.size += n
                    for a in range(at, at + n):
                        self.owner["aux"][a] = run
                else:
                    run = self.put("aux", at, n, "copy of main's with_aux code", "code")
        # what is left in main memory's boot loader pages and text page 1 is free
        self.put("main", 0x0800, 0x300, "free (the boot loader's, once booted)", "free", over=False)

    def holes(self, space, lo=None, hi=None):
        base, size = SPACES[space][1], SPACES[space][2]
        lo = lo if lo is not None else USABLE[space][0]
        hi = hi if hi is not None else USABLE[space][1]
        out, start = [], None
        for a in range(lo, hi):
            it = self.owner[space][a - base]
            free = it is None or it.kind == "free"
            if free and start is None:
                start = a
            if not free and start is not None:
                out.append((start, a))
                start = None
        if start is not None:
            out.append((start, hi))
        return out

    def totals(self, space):
        base = SPACES[space][1]
        lo, hi = USABLE[space]
        t = {k: 0 for k in COLOUR}
        for a in range(lo, hi):
            it = self.owner[space][a - base]
            t[it.kind if it else "free"] += 1
        return t

    def runs(self, space, lo, hi, absorb):
        # runs of one kind
        base = SPACES[space][1]
        raw = []
        for a in range(lo, hi):
            it = self.owner[space][a - base]
            kind = it.kind if it else "free"
            key = (kind, it.name if (it and kind in ("hw", "screens")) else "")
            if raw and raw[-1][2] == key:
                raw[-1][1] = a + 1
                raw[-1][3].add(it)
            else:
                raw.append([a, a + 1, key, {it}])
        # a run under absorb bytes joins the run before; a big free run stays apart, and so
        # does what follows it
        out = []
        for r in raw:
            small = r[1] - r[0] < absorb
            r.append(r[2][0] == "free" and r[1] - r[0] >= max(1, absorb // 4))  # [4]: kept apart
            if out and not out[-1][4] and not r[4] and (small or out[-1][2] == r[2]):
                out[-1][1] = r[1]
                out[-1][3] |= r[3]
            else:
                out.append(r)
        # the kind of a run is what most of its bytes are
        for r in out:
            t = {}
            for a in range(r[0], r[1]):
                it = self.owner[space][a - base]
                k = it.kind if it else "free"
                t[k] = t.get(k, 0) + 1
            r[2] = (max(t, key=lambda k: t[k]), r[2][1])
        return [r[:4] for r in out]


def describe(items, kind, size):
    items = [i for i in items if i is not None and i.kind != "free"]
    if not items or kind == "free":
        return "FREE"
    named = {}
    for it in items:
        named[it.name] = it
    if len(named) == 1:
        it = list(named.values())[0]
        return it.name
    if kind == "free":
        return "FREE"
    weight = {}
    for it in named.values():
        weight[module_of(it.name)] = weight.get(module_of(it.name), 0) + it.size
    tops = sorted(weight, key=lambda m: -weight[m])
    text = ", ".join(tops[:3]) + (" +%d more" % (len(tops) - 3) if len(tops) > 3 else "")
    return "%s (%d): %s" % (KIND_NAME[kind].split(" (")[0].split(",")[0], len(named), text)


# the machine's own areas, where labels split (and their names when a run is the whole area)
ZONES = {
    "main": {0x0000: "zero page", 0x0100: "stack page", 0x0200: "pages 2 and 3",
             0x0400: "text page 1 (never shown)", 0x0800: "text page 2, the boot loader's",
             0x0B00: None, 0x2000: "hi-res page 1", 0x4000: "hi-res page 2", 0x6000: None,
             0x8000: None, 0xC000: "I/O and slot ROMs", 0xD000: "ROM"},
    "aux": {0x0000: "aux zero page and stack", 0x0200: "aux page 2", 0x0300: None,
            0x0400: "aux text page 1", 0x0800: None, 0x2000: "hi-res page 1, aux half",
            0x4000: "hi-res page 2, aux half", 0x6000: None, 0xC000: "I/O", 0xD000: None},
    "lc": {0xE000: None},
    "alc": {0xE000: None},
}


def name_run(m, space, a, b, kind, its, zone_name):
    its = [i for i in its if i is not None]
    if kind == "free":
        return "FREE"
    weight = {}
    for it in its:
        n = sum(1 for x in range(max(a, it.start), min(b, it.end))
                if m.at(space, x) is it)
        weight[it.name] = weight.get(it.name, 0) + n
    if weight:
        top = max(weight, key=lambda k: weight[k])
        if weight[top] >= 0.8 * (b - a):
            return top
    if zone_name:
        return zone_name
    t = {}
    for x in range(a, b):
        it = m.at(space, x)
        k = it.kind if it else "free"
        t[k] = t.get(k, 0) + 1
    if max(t.values()) < 0.5 * (b - a):
        return describe(its, kind, b - a).replace(
            describe(its, kind, b - a).split(" (")[0], "mixed", 1)
    return describe(its, kind, b - a)


def composition(m, space, a, b):
    # the kinds a labelled run holds, when it holds more than one
    t = {}
    for x in range(a, b):
        it = m.at(space, x)
        k = it.kind if it else "free"
        t[k] = t.get(k, 0) + 1
    if len(t) < 2:
        return ""
    return "  ".join("%s %s" % (k, "{:,}".format(v)) for k, v in sorted(t.items(), key=lambda kv: -kv[1]))


