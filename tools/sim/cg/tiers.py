"""The picks study's table (catwiz-sim --study picks --table F) and the cards study's output
(--study cards) as markdown tables for docs/sim-explore.md: each face's forced win rate by
third against the unforced runs, the blank face of its slot and a skip; each charm's; the
naturally drafted offer and pick rates and held-vs-not win rates.

    python3 tools/sim/cg/tiers.py PICKS.tsv [CARDS.txt]
"""

import math
import sys

KINDS = {0: "card", 1: "charm", 2: "nap", 3: "door"}
SLOTS = ["wand", "fluff", "star", "book", "curse", "trick"]


def read_picks(path):
    rows = []
    base = None
    for line in open(path):
        p = line.rstrip("\n").split("\t")
        if len(p) < 7:
            continue
        kind, after, what = int(p[0]), int(p[1]), int(p[2])
        if kind == -1:
            base = float(p[4])
            continue
        rows.append({"kind": kind, "after": after, "what": what, "name": p[3],
                     "win": float(p[4]), "hp": float(p[5]), "taken": float(p[6])})
    return base, rows


def se(p, n):
    return math.sqrt(max(p * (1 - p), 1e-9) / n)


def read_cards(path):
    faces, charms = {}, {}
    mode = None
    for line in open(path):
        p = line.rstrip("\n").split("\t")
        if p[0] == "face":
            mode = "face"
            continue
        if p[0] == "charm":
            mode = "charm"
            continue
        if mode == "face" and len(p) == 13:
            faces[p[0]] = p
        elif mode == "charm" and len(p) == 12:
            charms[p[0]] = p
    return faces, charms


def main():
    base, rows = read_picks(sys.argv[1])
    runs = int(sys.argv[3]) if len(sys.argv) > 3 else 256
    cards = read_cards(sys.argv[2]) if len(sys.argv) > 2 else ({}, {})
    print("unforced: %.1f%%; a line's noise about +-%.1f points (one standard error)" % (
        100 * base, 100 * se(base, runs)))
    thirds = [1, 4, 7]
    face = {}
    blank = {}
    skip = {}
    for r in rows:
        if r["kind"] != 0:
            continue
        name = r["name"]
        t = thirds.index(r["after"])
        if name.startswith("blank "):
            blank[(name[6:].lower(), t)] = r["win"]
            continue
        if name == "skip":
            skip[t] = r["win"]
            continue
        face.setdefault(name, [None, None, None, None])
        face[name][t] = r["win"]
        face[name][3] = r.get("taken")
    slot_of = {}
    sys.path.insert(0, __file__.rsplit("/", 2)[0])
    import catalog  # noqa: E402
    for f in catalog.faces():
        slot_of[f["name"]] = f["slot"]
    for s in range(6):
        slot_of["+1 " + SLOTS[s].upper()] = SLOTS[s]
    print("\nblank faces (the slot's face does nothing from that pick):")
    print("| slot | after fight 1 | 4 | 7 |")
    print("|---|---|---|---|")
    for s in SLOTS:
        print("| %s | %s |" % (s, " | ".join("%.0f%%" % (100 * blank.get((s, t), float("nan")))
                                             for t in range(3))))
    print("| skip | %s |" % " | ".join("%.0f%%" % (100 * skip.get(t, float("nan"))) for t in range(3)))
    out = []
    for name, w in face.items():
        vals = [x for x in w[:3] if x is not None]
        mean = sum(vals) / len(vals)
        slot = slot_of.get(name, "?")
        bl = [blank.get((slot, t)) for t in range(3)]
        below = sum(1 for t in range(3) if w[t] is not None and bl[t] is not None and
                    w[t] <= bl[t])
        pairs = [(w[t], bl[t]) for t in range(3) if w[t] is not None and bl[t] is not None]
        vs_blank = sum(a - b for a, b in pairs) / max(1, len(pairs))
        sk = [(w[t], skip[t]) for t in range(3) if w[t] is not None and t in skip]
        vs_skip = sum(a - b for a, b in sk) / max(1, len(sk))
        out.append((mean, name, slot, w, vs_blank, below, vs_skip))
    out.sort(reverse=True)
    fc = cards[0]
    print("\n| card | slot | forced after 1, 4, 7 | vs unforced | vs a skip | vs a blank | "
          "offered runs | taken when offered | held: won (not held) |")
    print("|---|---|---|---|---|---|---|---|---|")
    for mean, name, slot, w, vb, below, vs_skip in out:
        c = fc.get(name)
        extra = " |  |  |"
        if c:
            extra = " | %s | %.0f%% | %.0f%% (%.0f%%) |" % (
                c[4], 100 * float(c[7]) if c[7] != "nan" else float("nan"),
                100 * float(c[9]) if c[9] != "nan" else float("nan"), 100 * float(c[10]))
        print("| %s | %s | %s | %+.1f | %+.1f | %+.1f%s%s" % (
            name.title() if not name.startswith("+1") else name, slot,
            ", ".join("%.0f%%" % (100 * x) if x is not None else "-" for x in w[:3]),
            100 * (mean - base), 100 * vs_skip, 100 * vb,
            " (at or under in %d)" % below if below else "", extra))
    print("\ncharms:")
    ch = {}
    for r in rows:
        if r["kind"] != 1:
            continue
        ch.setdefault(r["name"], {})[r["after"]] = r["win"]
    cc = cards[1]
    print("| charm | forced after 3, 6, 9 | vs unforced | offered runs | taken when offered | "
          "held: won (not held) |")
    print("|---|---|---|---|---|---|")
    lines = []
    for name, d in ch.items():
        vals = [d.get(a) for a in (3, 6, 9)]
        m = sum(v for v in vals if v is not None) / max(1, sum(1 for v in vals if v is not None))
        lines.append((m, name, vals))
    lines.sort(reverse=True)
    for m, name, vals in lines:
        c = cc.get(name)
        extra = " |  |  |"
        if c:
            extra = " | %s | %.0f%% | %.0f%% (%.0f%%) |" % (
                c[4], 100 * float(c[7]) if c[7] != "nan" else float("nan"),
                100 * float(c[9]) if c[9] != "nan" else float("nan"), 100 * float(c[10]))
        print("| %s | %s | %+.1f%s" % (name.title(), ", ".join(
            "%.0f%%" % (100 * v) if v is not None else "-" for v in vals), 100 * (m - base), extra))
    print("\nnap and doors:")
    for r in rows:
        if r["kind"] in (2, 3):
            print("  %s after %d: %s %.1f%% (taken unforced %.0f%%)" % (
                KINDS[r["kind"]], r["after"], r["name"], 100 * r["win"], 100 * r["taken"]))


if __name__ == "__main__":
    main()
