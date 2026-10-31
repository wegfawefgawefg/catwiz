"""The numbers and texts that changed in the proposal tables (tools/sim/proposal) between a
commit and now, by name, for copying into game/content.

    python3 tools/sim/tablediff.py              # against f403880 (what the engine was built from)
    python3 tools/sim/tablediff.py REF          # against another commit

It reads both versions with tsp.py: items, enemies and moves by name (moves by their enemy and
place), the fights' cards and charms, the charm table, the constants.
"""

import os
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)

import tsp  # noqa: E402

FILES = ["action", "effects", "encounters", "enemies", "items", "moves"]


def load(d):
    c = tsp.Content([d, os.path.join(REPO, "game")])
    return {f: c.module("content/" + f) for f in FILES}


def rows_by(rows, key):
    return {r[key]: r for r in rows}


def show(v):
    return '"%s"' % v if isinstance(v, str) else str(v)


def diff_rows(what, old, new):
    for name in new:
        if name not in old:
            print("%s %s: new" % (what, name))
            continue
        for k, v in new[name].items():
            if old[name].get(k) != v:
                print("%s %s: %s %s -> %s" % (what, name, k, show(old[name].get(k)), show(v)))
    for name in old:
        if name not in new:
            print("%s %s: gone" % (what, name))


def move_rows(m):
    enemies = m["enemies"].consts["ENEMIES"]
    moves = m["moves"].consts["MOVES"]
    out = {}
    for e in enemies:
        for i in range(e["move_count"]):
            out["%s move %d" % (e["name"], i + 1)] = moves[e["first_move"] + i]
    return out


def names(m, row):
    items = m["items"].consts["ITEMS"]
    slots = ["WAND", "FLUFF", "STAR", "BOOK", "CURSE", "TRICK"]
    return [("+1 " + slots[c - 128]) if c >= 128 else items[c]["name"] for c in row]


def main():
    ref = sys.argv[1] if len(sys.argv) > 1 else "f403880"
    with tempfile.TemporaryDirectory() as d:
        for f in FILES:
            text = subprocess.run(["git", "-C", REPO, "show", "%s:tools/sim/proposal/%s.tsp" % (ref, f)],
                                  capture_output=True, text=True, check=True).stdout
            with open(os.path.join(d, f + ".tsp"), "w") as fp:
                fp.write(text)
        old = load(d)
    new = load(os.path.join(HERE, "proposal"))
    for f in FILES:
        o = {k: v for k, v in old[f].consts.items() if isinstance(v, int)}
        n = {k: v for k, v in new[f].consts.items() if isinstance(v, int)}
        for k in sorted(set(o) | set(n)):
            if o.get(k) != n.get(k):
                print("%s.%s: %s -> %s" % (f, k, o.get(k), n.get(k)))
    diff_rows("item", rows_by(old["items"].consts["ITEMS"], "name"),
              rows_by(new["items"].consts["ITEMS"], "name"))
    diff_rows("enemy", rows_by(old["enemies"].consts["ENEMIES"], "name"),
              rows_by(new["enemies"].consts["ENEMIES"], "name"))
    diff_rows("move", move_rows(old), move_rows(new))
    diff_rows("charm", rows_by(old["encounters"].consts["CHARMS"], "name"),
              rows_by(new["encounters"].consts["CHARMS"], "name"))
    oc, nc = old["encounters"].consts, new["encounters"].consts
    kinds = new["enemies"].consts["ENEMIES"]
    if "FIGHT_CARDS" in oc and "FIGHT_CARDS" in nc:
        for i, (a, b) in enumerate(zip(oc["FIGHT_CARDS"], nc["FIGHT_CARDS"])):
            if names(old, a) != names(new, b):
                print("cards after fight row %d: %s -> %s" % (i, ", ".join(names(old, a)),
                                                             ", ".join(names(new, b))))
    if "OFFER_CARDS" in nc and "OFFER_CARDS" not in oc:
        charms = nc["CHARMS"]
        print("the card pool (card, weight, from fight), new:")
        for o in nc["OFFER_CARDS"]:
            print("  %s %d %d" % (names(new, [o["card"]])[0], o["weight"], o["from"]))
        print("the charm pool, new:")
        for o in nc["OFFER_CHARMS"]:
            print("  %s %d %d" % (charms[o["card"]]["name"], o["weight"], o["from"]))
    if len(oc["FIGHTS"]) != len(nc["FIGHTS"]) or "OFFER_CARDS" not in oc:
        print("the fights, new (row: enemies, elite, other door):")
        for i, b in enumerate(nc["FIGHTS"]):
            eb = [kinds[s["enemy"]]["name"] for s in b["spots"][: b["count"]]]
            print("  %d %s: %s%s%s" % (i, b.get("zone"), ", ".join(eb),
                                       ", elite" if b.get("elite") else "",
                                       ", other door %d" % b["other"] if b.get("other") != 255 else ""))
        return
    for i, (a, b) in enumerate(zip(oc["FIGHTS"], nc["FIGHTS"])):
        ea = [s["enemy"] for s in a["spots"][: a["count"]]]
        eb = [s["enemy"] for s in b["spots"][: b["count"]]]
        if ea != eb or a.get("nap") != b.get("nap") or a.get("other") != b.get("other"):
            print("fight row %d: %s -> %s" % (i, ea, eb))


if __name__ == "__main__":
    main()
