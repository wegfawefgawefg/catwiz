# what the build says: its summary, listing, data notes and disk tables (build/asm.txt), the
# boot loader's segment table on disk 1, each fight's sprite room (art/dhgr/memory.txt), and a
# few numbers read from the source the layout cannot see

import os
import re
import subprocess
import sys

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
TISPLE = os.environ.get("TISPLE", "tisple")
TISPLE_LIB = os.path.expanduser(os.environ.get("TISPLE_LIB", "~/Coding/LangDev/tisple/lib"))
BUILD = os.path.join(ROOT, "build")
ASM = os.path.join(BUILD, "asm.txt")
VARS = os.path.join(BUILD, "catwiz.vars.json")
DISK1 = os.path.join(BUILD, "catwiz.dsk")
SPRITES = os.path.join(ROOT, "art", "dhgr", "memory.txt")
OUT_PNG = os.path.join(ROOT, "docs", "memory-map.png")
OUT_LOW = os.path.join(ROOT, "docs", "memory-map-low.png")
OUT_TXT = os.path.join(BUILD, "memmap.txt")

def build():
    env = dict(os.environ, TISPLE_DATA_NOTES="1")
    with open(ASM, "w") as out:
        r = subprocess.run([TISPLE, "build", "--asm", "--tables"], cwd=ROOT, env=env, stdout=out,
                           stderr=subprocess.PIPE, text=True)
    if r.returncode != 0:
        sys.stderr.write(r.stderr)
        sys.exit("tisple build failed")


class Build:
    def __init__(self, lines):
        self.code = []      # (name, addr, size, place): place main | bank1 | group k
        self.data = []      # (name, addr, size, mem): mem main | aux
        self.segments = []  # (mem, addr, size): mem main | card | bank1 | aux
        self.tables = []    # (disk, first, last, name, bytes, sectors)
        self.groups = []    # dicts: roots, functions, bytes, from (disk2 | aux), frames, aux_at
        self.notes = []     # the build's warnings, as it says them
        self.region = None  # the overlay region (addr, size)
        self.zp_used = self.zp_frames = self.frames_memory = 0
        self.disk_lines = []
        self.listing_zp = {}  # zero page address: names the listing gives it
        header = re.compile(r"^(\S.*?)  \$([0-9A-F]{4}), (\d+) bytes(.*)$")
        seg_first = re.compile(r"^(\d+) bytes at \$([0-9A-F]{4}) \(code (\d+), data (\d+)\); "
                               r"zero page (\d+) bytes \(frames (\d+)\), frames in memory (\d+) bytes")
        seg = re.compile(r"^  and (\d+) bytes at \$([0-9A-F]{4}) in (.*) memory$")
        data = re.compile(r"^data +(\d+) \$([0-9A-F]{4}) (main|aux ) (\S+)$")
        table = re.compile(r"^  disk (\d) tracks +(\d+)- *(\d+): (.*), (\d+) bytes, (\d+) sectors$")
        zp = re.compile(r"^  [0-9A-F]{4}  (?:[0-9A-F]{2} ){1,3}\s*[A-Z]{3} \(?\$([0-9A-F]{2})\b"
                        r"[^;]*(?:; (\S+))?")
        for line in lines:
            line = line.rstrip("\n")
            m = header.match(line)
            if m and not line.startswith(";"):
                name, addr, size, rest = m.group(1), int(m.group(2), 16), int(m.group(3)), m.group(4)
                g = re.search(r"in overlay group (\d+)", rest)
                place = "group %s" % g.group(1) if g else ("bank1" if "bank 1" in rest else "main")
                self.code.append((name, addr, size, place))
                continue
            m = data.match(line)
            if m:
                self.data.append((m.group(4), int(m.group(2), 16), int(m.group(1)),
                                  m.group(3).strip()))
                continue
            m = seg_first.match(line)
            if m:
                self.segments.append(("main", int(m.group(2), 16), int(m.group(1))))
                self.code_bytes, self.data_bytes = int(m.group(3)), int(m.group(4))
                self.zp_used, self.zp_frames = int(m.group(5)), int(m.group(6))
                self.frames_memory = int(m.group(7))
                continue
            m = seg.match(line)
            if m:
                mem = {"main": "main", "language card": "card", "language card bank 1": "bank1",
                       "aux": "aux"}[m.group(3)]
                self.segments.append((mem, int(m.group(2), 16), int(m.group(1))))
                continue
            m = table.match(line)
            if m:
                self.tables.append((int(m.group(1)), int(m.group(2)), int(m.group(3)), m.group(4),
                                    int(m.group(5)), int(m.group(6))))
                continue
            if line.startswith("build/") and ".dsk:" in line:
                self.disk_lines.append(line)
                continue
            if line.startswith("; game/main.tsp"):
                self.notes.append(line[2:])
                continue
            m = zp.match(line)
            if m:
                self.listing_zp.setdefault(int(m.group(1), 16), set()).add(m.group(2) or "")
        self.parse_groups()
        aux_at = {}
        for name, addr, size, place in self.code:
            pass
        for line in lines:
            m = re.search(r"in overlay group (\d+) \(kept at aux \$([0-9A-F]{4})\)", line)
            if m:
                aux_at[int(m.group(1))] = int(m.group(2), 16)
        for k, g in enumerate(self.groups):
            g["aux_at"] = aux_at.get(k)

    def parse_groups(self):
        for note in self.notes:
            m = re.search(r"in a (\d+)-byte overlay region at \$([0-9A-F]{4}), [^:]*: (.*)\. The stubs",
                          note)
            if not m:
                continue
            self.region = (int(m.group(2), 16), int(m.group(1)))
            for part in m.group(3).split("); "):
                g = re.match(r"(.*?)( from the second disk)? \((\d+) functions, (\d+) bytes, a load "
                             r"about (\d+) cycles, ([\d.]+) frames", part)
                if g:
                    self.groups.append({"roots": g.group(1), "from": "disk2" if g.group(2) else "aux",
                                        "functions": int(g.group(3)), "bytes": int(g.group(4)),
                                        "cycles": int(g.group(5)), "frames": float(g.group(6))})


def source_const(path, name, need=True):
    # a const or let's number in a .tsp file: (const NAME u16 0x0630) or (let NAME u16 0x0400)
    text = open(path).read() if os.path.exists(path) else ""
    m = re.search(r"\((?:const|let) %s (?:u8|u16) (0x[0-9A-Fa-f]+|\d+)\)" % re.escape(name), text)
    if not m:
        if need:
            sys.exit("%s: no %s" % (path, name))
        return None
    return int(m.group(1), 0)


def game_path(module):
    return os.path.join(ROOT, "game", module + ".tsp")


# aux memory's text page buffers: pointers, not lets, so the layout never sees them. The rules
# page's buffer is shared (a song read from the disk, a hat trick's record, disk 2's label);
# main has one let a user, the load-music branch one for all (state.aux_page1)
PAGE1_USERS = (("state", "aux_page1"), ("battle/rules", "buffer"), ("sound/sound", "song_buffer"),
               ("content/items", "hat_at"), ("title/disk2", "read_at"))


def aux_text_buffers():
    found = [(m, n, source_const(game_path(m), n, need=False)) for m, n in PAGE1_USERS]
    found = [f for f in found if f[2] is not None]
    page_at = found[0][2]
    page_size = source_const(game_path("content/rules"), "PAGE_BYTES")
    users = [m.split("/")[-1] + "." + n for m, n, at in found if at == page_at]
    hist_at = source_const(game_path("battle/log"), "HIST_AT")
    hist_size = (source_const(game_path("battle/log"), "HISTORY") *
                 source_const(game_path("draw/text"), "LINE_BYTES"))
    return [(page_at, page_size, "rules page, song, hat record buffer (" + ", ".join(users) + ")"),
            (hist_at, hist_size, "the log's history (battle/log HIST_AT)")]


def guard_home():
    return source_const(os.path.join(TISPLE_LIB, "auxmem.tsp"), "GUARD_HOME")


def aux_card_end():
    return source_const(game_path("draw/blit"), "CARD2_END")


def loader_segments():
    # the boot loader's table on the disk: first page, pages, memory (0 main, 1 card bank 2,
    # 2 aux, 3 card bank 1), ended by 0 pages; the loader is track 0's physical sectors 0-2
    disk = open(DISK1, "rb").read()
    logical = [0, 7, 14, 6, 13, 5, 12, 4, 11, 3, 10, 2, 9, 1, 8, 15]  # physical -> DOS 3.3 order
    loader = b"".join(disk[logical[p] * 256:logical[p] * 256 + 256] for p in range(3))
    return loader


def find_loader_table(loader, first):
    # the table starts with the first segment the build says it loads (aux memory's first)
    for i in range(len(loader) - 3):
        if loader[i] == first[0] and loader[i + 1] == first[1] and loader[i + 2] == first[2]:
            out, j = [], i
            while loader[j + 1] != 0 and len(out) < 12:
                out.append((loader[j], loader[j + 1], loader[j + 2]))
                j += 3
            if 1 < len(out) <= 10:
                return out
    sys.exit("the boot loader's segment table was not found in %s" % DISK1)


def sprite_room():
    # each fight's fill of the aux card and sprite_aux, from art/dhgr/memory.txt
    fights = []
    pat = re.compile(r"^fight (\d+) \((\w+)\): (.*)\n +(\d+) bytes: bank 2 (\d+) of (\d+), bank 1 "
                     r"(\d+) of (\d+), sprite_aux (\d+) of (\d+): (-?\d+) to spare", re.M)
    for m in pat.finditer(open(SPRITES).read()):
        fights.append({"fight": int(m.group(1)), "zone": m.group(2), "who": m.group(3),
                       "bank2": int(m.group(5)), "bank2_room": int(m.group(6)),
                       "bank1": int(m.group(7)), "bank1_room": int(m.group(8)),
                       "aux": int(m.group(9)), "aux_room": int(m.group(10)),
                       "spare": int(m.group(11))})
    return fights


